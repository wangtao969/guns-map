import 'dart:ui';
import 'package:flutter/material.dart';
import '../screens/settings_screen.dart';

/// 毛玻璃底：半透明底色 + 模糊（底部细线已按要求去掉）。
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
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(color: tint),
      ),
    );
  }
}

/// 主 Tab 顶栏（毛玻璃）：应用名靠左，右上角齿轮圆形设置按钮。
/// 只在首页四个主页面显示；子页面一律用 SubPageAppBar，不再出现应用名与齿轮。
class OrdnanceAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// 设置页本身不再放齿轮按钮，避免重复进设置页。
  final bool showSettingsButton;
  const OrdnanceAppBar({super.key, this.showSettingsButton = true});

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
        "Ordnance",
        style: TextStyle(
          // 线衬体（系统 serif）：比无衬线多一点设计感。
          fontFamily: 'serif',
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
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
        "Ordnance",
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
