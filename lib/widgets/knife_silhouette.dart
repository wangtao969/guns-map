import 'package:flutter/material.dart';

/// 刀形剪影：示意图，非任何具体产品的实物照片。
/// 柄在左、刃在右；刺刀刃更细长，折刀刃带一点收折角，传统刀刃略带弧度。
class KnifeSilhouette extends StatelessWidget {
  final String type;
  final Color color;
  const KnifeSilhouette({super.key, required this.type, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _KnifePainter(type: type, color: color),
    );
  }
}

class _KnifePainter extends CustomPainter {
  final String type;
  final Color color;
  _KnifePainter({required this.type, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final w = size.width;
    final h = size.height;
    final midY = h * 0.52;
    final bladeH = type == '军用刺刀' ? h * 0.16 : h * 0.30;
    final tipX = w * 0.97;
    final bladeEndX = w * 0.38;
    // 刃：从护手到刀尖的细长多边形，刀尖收拢。
    final blade = Path()
      ..moveTo(bladeEndX, midY - bladeH / 2)
      ..lineTo(tipX - w * 0.10, midY - bladeH / 2)
      ..quadraticBezierTo(tipX, midY - bladeH * 0.1, tipX, midY)
      ..quadraticBezierTo(tipX, midY + bladeH * 0.1, tipX - w * 0.10,
          midY + bladeH / 2)
      ..lineTo(bladeEndX, midY + bladeH / 2)
      ..close();
    canvas.drawPath(blade, paint);
    // 护手。
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(bladeEndX - w * 0.03, midY - h * 0.28, w * 0.03,
            h * 0.56),
        const Radius.circular(2),
      ),
      paint,
    );
    // 柄：圆角矩形，折刀略向下斜以示收折形态。
    final handle = Path();
    if (type == '实用折刀' || type == '传统刀具') {
      handle
        ..moveTo(bladeEndX - w * 0.03, midY - h * 0.18)
        ..lineTo(w * 0.04, midY - h * 0.10)
        ..quadraticBezierTo(w * 0.01, midY + h * 0.30, w * 0.06,
            midY + h * 0.32)
        ..lineTo(bladeEndX - w * 0.03, midY + h * 0.18)
        ..close();
    } else {
      handle.addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(
            w * 0.02, midY - h * 0.18, bladeEndX - w * 0.05, h * 0.36),
        const Radius.circular(6),
      ));
    }
    canvas.drawPath(handle, paint);
  }

  @override
  bool shouldRepaint(_KnifePainter old) =>
      old.type != type || old.color != color;
}
