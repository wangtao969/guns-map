import 'package:flutter/material.dart';

/// 按压缩放按钮：按下缩到 0.96、松开弹回，带 120ms 动画。
/// 包住普通按钮（OutlinedButton / FilledButton 等）即可，不改按钮本身样式。
class ScaleTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const ScaleTap({super.key, required this.child, this.onTap});

  @override
  State<ScaleTap> createState() => _ScaleTapState();
}

class _ScaleTapState extends State<ScaleTap>
    with SingleTickerProviderStateMixin {
  late final _ctrl = AnimationController(
      duration: const Duration(milliseconds: 120), vsync: this);
  late final _scale =
      Tween<double>(begin: 1.0, end: 0.96).animate(_ctrl);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(
          scale: _scale.value,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}
