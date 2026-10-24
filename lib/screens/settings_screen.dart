import 'package:flutter/material.dart';
import '../main.dart';
import '../widgets/app_top_bar.dart';

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
          const Text('关于',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const ListTile(
            title: Text("Gun's Map"),
            subtitle: Text('安卓枪械图鉴 App · v1.2.0 debug（arm64）'),
          ),
          ListTile(
            title: const Text('数据说明'),
            subtitle: Text(
              '图鉴与配件数据为公开资料整理；装药数据引自 Hornady、Speer、Nosler、Hodgdon、Vihtavuori、Lyman 等公开手册，各条标注出处；枪械与组件价格为 2026 年 10 月美国零售参考价，随时变动。',
              style: TextStyle(color: grey, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
