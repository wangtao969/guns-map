import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme_accent.dart';

/// 柱状图通用组件：CustomPaint 手画，零第三方包。
/// 两处复用：弹药库存按口径分布、DOPE 分组 MOA 趋势。
/// 只画传入的数据，不读任何存储；空数据时父级不渲染本组件。
class BarChartEntry {
  final String label;
  final double value;
  final String valueText;
  final bool warning;
  const BarChartEntry({
    required this.label,
    required this.value,
    required this.valueText,
    this.warning = false,
  });
}

class SimpleBarChart extends StatelessWidget {
  final List<BarChartEntry> entries;
  final double height;
  const SimpleBarChart({super.key, required this.entries, this.height = 200});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ValueListenableBuilder<Color>(
      valueListenable: accentNotifier,
      builder: (_, accent, __) {
        return CustomPaint(
          size: Size(double.infinity, height),
          painter: _BarChartPainter(
            entries: entries,
            barColor: dark ? lightenedAccent(accent) : accent,
            warningColor: Colors.red,
            labelColor:
                dark ? const Color(0xFFB8B2A4) : const Color(0xFF6B655A),
            gridColor: dark
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.08),
            axisColor: dark
                ? Colors.white.withValues(alpha: 0.25)
                : Colors.black.withValues(alpha: 0.25),
          ),
        );
      },
    );
  }
}

/// 把最大值圆整到 1/2/2.5/5/10 档，网格线刻度干净。
double _niceMax(double v) {
  if (v <= 0) return 1;
  final exp = (math.log(v) / math.ln10).floor();
  final pow10 = math.pow(10, exp).toDouble();
  final f = v / pow10;
  final nf = f <= 1 ? 1 : f <= 2 ? 2 : f <= 2.5 ? 2.5 : f <= 5 ? 5 : 10;
  return nf * pow10;
}

String _gridLabel(double v) {
  if (v >= 10) return v.toStringAsFixed(0);
  final s = v.toStringAsFixed(1);
  return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
}

class _BarChartPainter extends CustomPainter {
  final List<BarChartEntry> entries;
  final Color barColor;
  final Color warningColor;
  final Color labelColor;
  final Color gridColor;
  final Color axisColor;

  const _BarChartPainter({
    required this.entries,
    required this.barColor,
    required this.warningColor,
    required this.labelColor,
    required this.gridColor,
    required this.axisColor,
  });

  static const _leftPad = 30.0;
  static const _rightPad = 4.0;
  static const _topPad = 20.0;
  static const _bottomPad = 24.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.isEmpty) return;
    final plotW = size.width - _leftPad - _rightPad;
    final plotH = size.height - _topPad - _bottomPad;
    if (plotW <= 0 || plotH <= 0) return;
    final maxV = _niceMax(
        entries.map((e) => e.value).reduce((a, b) => a > b ? a : b));

    // 网格线 + 左侧刻度：0、1/3、2/3、最大值四档。
    final gridPaint = Paint()..color = gridColor..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = _topPad + plotH - plotH * i / 3;
      canvas.drawLine(Offset(_leftPad, y), Offset(size.width - _rightPad, y),
          gridPaint);
      _drawText(canvas, _gridLabel(maxV * i / 3),
          Offset(_leftPad - 4, y - 7), labelColor, 11, rightAlign: true);
    }
    // 基线。
    final axisPaint = Paint()..color = axisColor..strokeWidth = 1;
    final baseY = _topPad + plotH;
    canvas.drawLine(Offset(_leftPad, baseY), Offset(size.width - _rightPad, baseY),
        axisPaint);

    // 横轴标签：按最长标签算步长，拥挤时隔行显示，不重叠。
    var maxLabelW = 0.0;
    for (final e in entries) {
      maxLabelW = math.max(maxLabelW, _measure(e.label, 11));
    }
    final stride = math.max(
        1, ((maxLabelW + 6) * entries.length / plotW).ceil());
    final slotW = plotW / entries.length;
    final barW = math.min(slotW * 0.6, 36.0);

    for (var i = 0; i < entries.length; i++) {
      final e = entries[i];
      final cx = _leftPad + slotW * i + slotW / 2;
      final h = math.max(e.value / maxV * plotH, e.value > 0 ? 2.0 : 0.0);
      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(cx - barW / 2, baseY - h, barW, h),
        topLeft: const Radius.circular(4),
        topRight: const Radius.circular(4),
      );
      canvas.drawRRect(
          rect, Paint()..color = e.warning ? warningColor : barColor);
      // 柱上数值。
      _drawText(canvas, e.valueText, Offset(cx, baseY - h - 16),
          e.warning ? warningColor : labelColor, 11,
          center: true);
      // 横轴标签。
      if (i % stride == 0) {
        final w = _measure(e.label, 11);
        final dx = (cx - w / 2)
            .clamp(_leftPad, size.width - _rightPad - w)
            .toDouble();
        _drawText(canvas, e.label, Offset(dx, baseY + 6), labelColor, 11);
      }
    }
  }

  double _measure(String text, double size) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(fontSize: size)),
      textDirection: TextDirection.ltr,
    )..layout();
    return tp.width;
  }

  void _drawText(Canvas canvas, String text, Offset offset, Color color,
      double size,
      {bool center = false, bool rightAlign = false}) {
    final tp = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(color: color, fontSize: size)),
      textDirection: TextDirection.ltr,
    )..layout();
    var dx = offset.dx;
    if (center) dx -= tp.width / 2;
    if (rightAlign) dx -= tp.width;
    tp.paint(canvas, Offset(dx, offset.dy));
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter old) =>
      old.entries != entries ||
      old.barColor != barColor ||
      old.warningColor != warningColor ||
      old.labelColor != labelColor ||
      old.gridColor != gridColor ||
      old.axisColor != axisColor;
}
