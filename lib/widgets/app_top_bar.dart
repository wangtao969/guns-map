import 'dart:ui';
import 'package:flutter/material.dart';
import '../screens/settings_screen.dart';

/// 毛玻璃底：半透明底色 + 模糊 + 底部细线。
/// 主 Tab 页与设置页用 extendBodyBehindAppBar 让内容从栏下滚动而过，
/// 模糊效果才真实可见；其余子页正常布局，栏本身仍是半透明毛玻璃样式。
class _GlassBackground extends StatelessWidget {
  const _GlassBackground();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final tint = dark
        ? const Color(0xFF121110).withValues(alpha: 0.72)
        : const Color(0xFFF7F2E9).withValues(alpha: 0.72);
    final line = dark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.08);
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: tint,
            border: Border(bottom: BorderSide(color: line)),
          ),
        ),
      ),
    );
  }
}

/// 全局统一顶栏（毛玻璃）：左上角 App 名（加粗放大），右上角齿轮圆形设置按钮。
/// 只在首页四个主页面显示；子页面一律用 SubPageAppBar，不再出现 App 名与齿轮。
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
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      flexibleSpace: const _GlassBackground(),
      title: Text(
        "Gun's Map",
        style: TextStyle(
          // 无衬线现代简洁体：Android 系统默认无衬线 Roboto，加粗字重。
          fontFamily: 'Roboto',
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
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

/// 子页顶栏（毛玻璃）：只显示本页标题 + 系统返回箭头，不显示 App 名与齿轮。
/// 子页面显示优先：全局栏与正文返回行重复的问题，用这一个栏统一解决。
class SubPageAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  const SubPageAppBar({super.key, required this.title});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? const Color(0xFFEDE8DF) : const Color(0xFF2E2A24);
    return AppBar(
      centerTitle: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      flexibleSpace: const _GlassBackground(),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 19,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
          color: ink,
        ),
      ),
    );
  }
}
