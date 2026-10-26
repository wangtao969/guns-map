import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// 真折射液态玻璃悬浮导航条（v2，对标酷安底栏的做法）。
///
/// 原理：不用矩阵放大冒充折射，而是走 Impeller 的 [ui.ImageFilter.shader]，
/// 片元着色器直接采样底栏后方的实时画面，按圆角 SDF 的法线做边缘折射位移
/// + 红蓝错位色散 + 边缘高光。着色器在 shaders/liquid_glass.frag。
/// 不支持着色器的后端（非 Impeller）加载会失败，自动退回 v1 毛玻璃外观。
class LiquidGlassNavBar extends StatefulWidget {
  const LiquidGlassNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onTap,
    this.height = 64,
    this.radius = 32,
  });

  final List<IconData> items;
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final double height;
  final double radius;

  @override
  State<LiquidGlassNavBar> createState() => _LiquidGlassNavBarState();
}

class _LiquidGlassNavBarState extends State<LiquidGlassNavBar> {
  ui.FragmentProgram? _program;

  @override
  void initState() {
    super.initState();
    ui.FragmentProgram.fromAsset('shaders/liquid_glass.frag').then(
      (program) {
        if (mounted) setState(() => _program = program);
      },
      onError: (_) {
        // 着色器不可用：保持毛玻璃退路，不抛错。
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget bar = Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        for (int i = 0; i < widget.items.length; i++)
          GestureDetector(
            onTap: () => widget.onTap(i),
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 56,
              height: widget.height,
              child: Icon(
                widget.items[i],
                color: i == widget.selectedIndex
                    ? const Color(0xFFE86A1C)
                    : Colors.white,
                size: i == widget.selectedIndex ? 28 : 24,
              ),
            ),
          ),
      ],
    );

    if (_program != null) {
      final shader = _program!.fragmentShader();
      // 引擎自动占位：u_size 占 float 索引 0、1；自定义 uniform 从 2 开始。
      shader.setFloat(2, widget.radius);
      shader.setFloat(3, 14.0); // 折射位移 px
      shader.setFloat(4, 0.35); // 色散系数
      shader.setFloat(5, 0.08); // 白色 veil
      bar = ClipRRect(
        borderRadius: BorderRadius.circular(widget.radius),
        child: BackdropFilter(
          filter: ui.ImageFilter.shader(shader),
          child: Container(color: Colors.transparent, child: bar),
        ),
      );
    } else {
      // 退路：v1 毛玻璃外观。
      bar = ClipRRect(
        borderRadius: BorderRadius.circular(widget.radius),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            color: Colors.white.withValues(alpha: 0.18),
            child: bar,
          ),
        ),
      );
    }

    return SizedBox(height: widget.height, child: bar);
  }
}
