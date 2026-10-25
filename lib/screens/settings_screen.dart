import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../haptics.dart';
import '../i18n.dart';
import '../main.dart';
import '../widgets/app_top_bar.dart';
import 'feedback_screen.dart';

/// 当前版本：每次发版时与 pubspec.yaml 一起改。
const String appVersion = '1.6.1';

/// 设置页：主题切换与关于信息。
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final grey = dark ? const Color(0xFF8A8578) : const Color(0xFF9A917F);
    // 语言切换时整页重译。
    return ValueListenableBuilder<String>(
      valueListenable: localeNotifier,
      builder: (_, __, ___) => Scaffold(
      appBar: const GunsMapAppBar(showSettingsButton: false),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(tr('theme'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeModeNotifier,
            builder: (_, mode, __) => RadioGroup<ThemeMode>(
              groupValue: mode,
              onChanged: (v) => themeModeNotifier.value = v!,
              child: Column(
                children: [
                  RadioListTile<ThemeMode>(
                    title: Text(tr('theme_system')),
                    subtitle: Text(tr('theme_system_sub')),
                    value: ThemeMode.system,
                  ),
                  RadioListTile<ThemeMode>(
                    title: Text(tr('theme_light')),
                    subtitle: Text(tr('theme_light_sub')),
                    value: ThemeMode.light,
                  ),
                  RadioListTile<ThemeMode>(
                    title: Text(tr('theme_dark')),
                    subtitle: Text(tr('theme_dark_sub')),
                    value: ThemeMode.dark,
                  ),
                ],
              ),
            ),
          ),
          Text(tr('theme_note'),
              style: TextStyle(color: grey, fontSize: 12)),
          const SizedBox(height: 24),
          Text(tr('haptics'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ValueListenableBuilder<bool>(
            valueListenable: hapticsEnabledNotifier,
            builder: (_, enabled, __) => SwitchListTile(
              title: Text(tr('haptics_title')),
              subtitle: Text(tr('haptics_sub')),
              value: enabled,
              onChanged: (v) => hapticsEnabledNotifier.value = v,
            ),
          ),
          Text(tr('haptics_note'),
              style: TextStyle(color: grey, fontSize: 12)),
          const SizedBox(height: 24),
          Text(tr('language'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ValueListenableBuilder<String>(
            valueListenable: localeNotifier,
            builder: (_, locale, __) => RadioGroup<String>(
              groupValue: locale,
              onChanged: (v) => localeNotifier.value = v!,
              child: Column(
                children: [
                  for (final entry in localeNames.entries)
                    RadioListTile<String>(
                      title: Text(entry.value),
                      value: entry.key,
                    ),
                ],
              ),
            ),
          ),
          Text(tr('language_note'),
              style: TextStyle(color: grey, fontSize: 12)),
          const SizedBox(height: 24),
          Text(tr('about'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ListTile(
            title: const Text("Gun's Map"),
            subtitle: Text('${tr('version_prefix')}v$appVersion${tr('version_suffix')}'),
          ),
          ListTile(
            title: Text(tr('check_update')),
            subtitle: Text(tr('check_update_sub')),
            trailing: const Icon(Icons.system_update_alt),
            onTap: () => _checkUpdate(context),
          ),
          ListTile(
            title: Text(tr('feedback')),
            subtitle: Text(tr('feedback_sub')),
            trailing: const Icon(Icons.feedback_outlined),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FeedbackScreen()),
            ),
          ),
          ListTile(
            title: Text(tr('data_note')),
            subtitle: Text(
              tr('data_note_body'),
              style: TextStyle(color: grey, fontSize: 13),
            ),
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 8),
          Center(
            child: Text('ID：wangtao969',
                style: TextStyle(color: grey, fontSize: 13)),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(tr('id_account'),
                style: TextStyle(color: grey, fontSize: 11)),
          ),
        ],
      ),
      ),
    );
  }

  /// 检查更新：只用 Dart 核心库查 GitHub 最新 Release，不引第三方包。
  Future<void> _checkUpdate(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text(tr('checking')),
          ],
        ),
      ),
    );
    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 10);
      final request = await client.getUrl(Uri.parse(
          'https://api.github.com/repos/wangtao969/guns-map/releases/latest'));
      request.headers.set('Accept', 'application/vnd.github+json');
      request.headers.set('User-Agent', 'GunsMap');
      final response =
          await request.close().timeout(const Duration(seconds: 15));
      final body = await response.transform(utf8.decoder).join();
      client.close();
      if (response.statusCode != 200) {
        throw HttpException('HTTP ${response.statusCode}');
      }
      final data = jsonDecode(body) as Map<String, dynamic>;
      final tag = (data['tag_name'] as String?) ?? '';
      final latest = tag.replaceFirst(RegExp(r'^v'), '').split('-').first;
      final notes = (data['body'] as String?) ?? '';
      String? apkUrl;
      for (final a in (data['assets'] as List? ?? [])) {
        final asset = a as Map;
        final name = (asset['name'] as String?) ?? '';
        if (name.endsWith('.apk')) {
          apkUrl = asset['browser_download_url'] as String?;
          break;
        }
      }
      final link =
          apkUrl ?? (data['html_url'] as String? ?? 'https://github.com/wangtao969/guns-map/releases');
      if (!context.mounted) return;
      Navigator.of(context).pop();
      if (latest.isEmpty || _compareVersions(latest, appVersion) <= 0) {
        if (!context.mounted) return;
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(tr('latest_title')),
            content: Text('${tr('latest_body_prefix')}$appVersion${tr('latest_body_suffix')}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(tr('ok')),
              ),
            ],
          ),
        );
        return;
      }
      final shownNotes =
          notes.length > 500 ? '${notes.substring(0, 500)}…' : notes;
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('${tr('new_title_prefix')}$latest'),
          content: SingleChildScrollView(
            child: Text(shownNotes.isEmpty ? tr('new_empty') : shownNotes),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(tr('close')),
            ),
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: link));
                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(tr('copied'))),
                );
              },
              child: Text(tr('copy_link')),
            ),
          ],
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      Navigator.of(context).pop();
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(tr('check_failed')),
          content: Text(tr('check_failed_body')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(tr('ok')),
            ),
          ],
        ),
      );
    }
  }

  /// 版本号比较：1.4.0 这种三段数字，返回负数表示 a 更旧。
  int _compareVersions(String a, String b) {
    final pa = a.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final pb = b.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    for (var i = 0; i < 3; i++) {
      final x = i < pa.length ? pa[i] : 0;
      final y = i < pb.length ? pb[i] : 0;
      if (x != y) return x.compareTo(y);
    }
    return 0;
  }
}
