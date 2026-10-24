import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../haptics.dart';
import '../main.dart';
import '../widgets/app_top_bar.dart';
import 'feedback_screen.dart';

/// 当前版本：每次发版时与 pubspec.yaml 一起改。
const String appVersion = '1.5.0';

/// 设置页：主题切换与关于信息。
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final grey = dark ? const Color(0xFF8A8578) : const Color(0xFF9A917F);
    return Scaffold(
      appBar: const GunsMapAppBar(showSettingsButton: false),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('主题',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeModeNotifier,
            builder: (_, mode, __) => RadioGroup<ThemeMode>(
              groupValue: mode,
              onChanged: (v) => themeModeNotifier.value = v!,
              child: const Column(
                children: [
                  RadioListTile<ThemeMode>(
                    title: Text('跟随系统'),
                    subtitle: Text('白天米白，夜晚黑底白字'),
                    value: ThemeMode.system,
                  ),
                  RadioListTile<ThemeMode>(
                    title: Text('浅色'),
                    subtitle: Text('始终使用米白主题'),
                    value: ThemeMode.light,
                  ),
                  RadioListTile<ThemeMode>(
                    title: Text('深色'),
                    subtitle: Text('始终使用黑底白字主题'),
                    value: ThemeMode.dark,
                  ),
                ],
              ),
            ),
          ),
          Text('主题选择仅在本次打开期间生效，重启后恢复跟随系统。',
              style: TextStyle(color: grey, fontSize: 12)),
          const SizedBox(height: 24),
          const Text('震动反馈',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ValueListenableBuilder<bool>(
            valueListenable: hapticsEnabledNotifier,
            builder: (_, enabled, __) => SwitchListTile(
              title: const Text('卡片与导航震动'),
              subtitle: const Text('点击卡片、切换底部导航时轻震一下'),
              value: enabled,
              onChanged: (v) => hapticsEnabledNotifier.value = v,
            ),
          ),
          Text('震动开关仅在本次打开期间生效，重启后恢复开启。',
              style: TextStyle(color: grey, fontSize: 12)),
          const SizedBox(height: 24),
          const Text('关于',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ListTile(
            title: const Text("Gun's Map"),
            subtitle: Text('安卓枪械图鉴 App · v$appVersion 正式版（arm64）'),
          ),
          ListTile(
            title: const Text('检查更新'),
            subtitle: const Text('联网查询 GitHub 最新 Release，有新版会给出下载链接'),
            trailing: const Icon(Icons.system_update_alt),
            onTap: () => _checkUpdate(context),
          ),
          ListTile(
            title: const Text('意见反馈'),
            subtitle: const Text('应用内填写反馈，可留联系邮箱'),
            trailing: const Icon(Icons.feedback_outlined),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FeedbackScreen()),
            ),
          ),
          ListTile(
            title: const Text('数据说明'),
            subtitle: Text(
              '图鉴与配件数据为公开资料整理；装药数据引自 Hornady、Speer、Nosler、Hodgdon、Vihtavuori、Lyman 等公开手册，各条标注出处；枪械与组件价格为 2026 年 10 月美国零售参考价，随时变动。',
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
            child: Text('GitHub 账号',
                style: TextStyle(color: grey, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  /// 检查更新：只用 Dart 核心库查 GitHub 最新 Release，不引第三方包。
  Future<void> _checkUpdate(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('正在检查更新…'),
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
            title: const Text('已是最新版本'),
            content: Text('当前版本 v$appVersion 已是最新。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('好的'),
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
          title: Text('发现新版本 v$latest'),
          content: SingleChildScrollView(
            child: Text(shownNotes.isEmpty ? '去 Release 页查看更新说明。' : shownNotes),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('关闭'),
            ),
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: link));
                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('下载链接已复制，去浏览器粘贴打开即可')),
                );
              },
              child: const Text('复制下载链接'),
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
          title: const Text('检查失败'),
          content: const Text('没能连上 GitHub，请检查网络后重试。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('好的'),
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
