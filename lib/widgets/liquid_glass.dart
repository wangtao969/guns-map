import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// 液态玻璃（对标苹果 iOS 26 的 Liquid Glass），不是毛玻璃：
/// 毛玻璃 = 背景模糊 + 半透明 tint，只有“看不清”；
/// 液态玻璃 = 透镜感（背景在玻璃里被放大一圈）+ 边缘高光 +
/// 随手指移动的镜面高光 + 按压回弹的形态。
///
/// 坦白讲：Flutter 原生做不到系统级的逐像素折射（那是 iOS
/// 系统渲染器的能力），这里用 BackdropFilter 的矩阵放大 +
/// 轻模糊 + 镜面高光层来逼近。试验版，先看感觉再定
/// 是否推到全 App 的顶栏、底栏与卡片上。
class LiquidGlass extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final double magnification;
  final bool followFinger;
  final VoidCallback? onTap;
  const LiquidGlass({
    super.key,
    required this.child,
    this.borderRadius = 24,
    this.magnification = 1.12,
    this.followFinger = false,
    this.onTap,
  });

  @override
  State<LiquidGlass> createState() => _LiquidGlassState();
}

class _LiquidGlassState extends State<LiquidGlass> {
  var _pressed = false;
  Offset? _finger;

  @override
  Widget build(BuildContext context) {
    final content = LayoutBuilder(
      builder: (_, constraints) {
        final w = constraints.maxWidth.isFinite ? constraints.maxWidth : 300.0;
        final h =
            constraints.maxHeight.isFinite ? constraints.maxHeight : 200.0;
        final cx = w / 2;
        final cy = h / 2;
        // 先矩阵放大背景（透镜感），再轻模糊：放大是液态感的主来源。
        final filter = ui.ImageFilter.compose(
          outer: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          inner: ui.ImageFilter.matrix(
            (Matrix4.identity()
                  ..setEntry(0, 0, widget.magnification)
                  ..setEntry(1, 1, widget.magnification)
                  ..setEntry(0, 3, (1 - widget.magnification) * cx)
                  ..setEntry(1, 3, (1 - widget.magnification) * cy))
                .storage,
          ),
        );
        return ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: Stack(
            children: [
              Positioned.fill(
                child: BackdropFilter(
                  filter: filter,
                  child: Container(
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
              ),
              // 顶部镜面高光：玻璃感主要靠这道光。
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.center,
                        colors: [
                          Colors.white.withValues(alpha: 0.45),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // 手指跟随的镜面光斑（只在要求跟随的卡上启用）。
              if (widget.followFinger && _finger != null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment(
                            (_finger!.dx / w) * 2 - 1,
                            (_finger!.dy / h) * 2 - 1,
                          ),
                          radius: 0.9,
                          colors: [
                            Colors.white.withValues(alpha: 0.35),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              // 边缘一圈亮边 + 底部淡淡的折射色边。
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(widget.borderRadius),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.45),
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: widget.child,
              ),
            ],
          ),
        );
      },
    );
    final scaled = AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutBack,
      child: content,
    );
    if (widget.onTap == null && !widget.followFinger) return scaled;
    return Listener(
      onPointerMove: widget.followFinger
          ? (e) => setState(() => _finger = e.localPosition)
          : null,
      child: GestureDetector(
        onTapDown: widget.onTap == null
            ? null
            : (_) => setState(() => _pressed = true),
        onTapUp: widget.onTap == null
            ? null
            : (_) => setState(() => _pressed = false),
        onTapCancel: widget.onTap == null
            ? null
            : () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: scaled,
      ),
    );
  }
}
