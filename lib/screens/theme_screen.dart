import 'package:flutter/material.dart';

import '../i18n.dart';
import '../main.dart';
import '../theme_accent.dart';
import '../widgets/app_top_bar.dart';

/// 主题页：白天/黑夜模式三选一（跟随系统、白天、夜晚，仅本次打开期间
/// 生效，与设置页原有行为一致）＋主题颜色预设（持久化，重启后保持）。
class ThemeScreen extends StatelessWidget {
  const ThemeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final grey = dark ? const Color(0xFF8A8578) : const Color(0xFF9A917F);
    return ValueListenableBuilder<String>(
      valueListenable: localeNotifier,
      builder: (_, __, ___) => Scaffold(
        extendBodyBehindAppBar: true,
        appBar: SubPageAppBar(title: tr('theme')),
        body: ListView(
          padding: EdgeInsets.fromLTRB(16,
              MediaQuery.of(context).padding.top + kToolbarHeight + 16, 16, 16),
          children: [
            Row(
              children: [
                const Icon(Icons.brightness_6_outlined, size: 22),
                const SizedBox(width: 8),
                Text(tr('theme_mode'),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
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
                      value: ThemeMode.system,
                    ),
                    RadioListTile<ThemeMode>(
                      title: Text(tr('theme_light')),
                      value: ThemeMode.light,
                    ),
                    RadioListTile<ThemeMode>(
                      title: Text(tr('theme_dark')),
                      value: ThemeMode.dark,
                    ),
                  ],
                ),
              ),
            ),
            Text(tr('theme_note'),
                style: TextStyle(color: grey, fontSize: 12)),
            const SizedBox(height: 24),
            Row(
              children: [
                const Icon(Icons.palette_outlined, size: 22),
                const SizedBox(width: 8),
                Text(tr('theme_accent'),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            ValueListenableBuilder<Color>(
              valueListenable: accentNotifier,
              builder: (_, current, __) => Column(
                children: [
                  for (final preset in accentPresets)
                    ListTile(
                      leading: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: preset.color,
                          border: Border.all(
                              color: Colors.grey.withValues(alpha: 0.4)),
                        ),
                      ),
                      title: Text(tr(preset.nameKey)),
                      trailing: current.toARGB32() == preset.color.toARGB32()
                          ? Icon(Icons.check,
                              color: dark
                                  ? lightenedAccent(current)
                                  : current)
                          : null,
                      onTap: () => saveAccent(preset.color),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
