import 'package:flutter/material.dart';

/// 全局页面过渡：新页从右轻滑 + 淡入，旧页随 secondaryAnimation 往左轻移，
/// 两边动作衔接，不生硬。时长走路由默认 300ms，曲线 easeOutCubic。
class SlideFadePageTransitionsBuilder extends PageTransitionsBuilder {
  const SlideFadePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final enter = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
    final exit = CurvedAnimation(
        parent: secondaryAnimation, curve: Curves.easeOutCubic);
    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(-0.06, 0),
      ).animate(exit),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.12, 0),
          end: Offset.zero,
        ).animate(enter),
        child: FadeTransition(opacity: enter, child: child),
      ),
    );
  }
}
