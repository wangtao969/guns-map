import 'package:flutter/material.dart';
import '../screens/settings_screen.dart';

/// 全局统一顶栏：左上角 App 名（加粗放大），右上角齿轮圆形设置按钮。
/// 各页共用，保证整体 UI 风格统一。
class GunsMapAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// 设置页本身不再放齿轮按钮，避免重复进设置页。
  final bool showSettingsButton;
  const GunsMapAppBar({super.key, this.showSettingsButton = true});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? const Color(0xFFEDE8DF) : const Color(0xFF2E2A24);
    final circleBg = dark ? const Color(0xFF1E1C19) : Colors.white;
    return AppBar(
      centerTitle: false,
      title: Text(
        "Gun's Map",
        style: TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.bold,
          color: ink,
        ),
      ),
      actions: [
        if (showSettingsButton)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: circleBg,
                border: Border.all(
                  color: dark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: 0.08),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(Icons.settings_rounded, size: 22, color: ink),
            ),
          ),
        ),
      ],
    );
  }
}
