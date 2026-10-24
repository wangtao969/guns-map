import 'package:flutter/material.dart';

/// 品类剪影图标：在 100×44 的画布上用曲线画出各类型枪械的侧面剪影，
/// 扳机护圈以描边圆环表现，比实心多边形更贴近真实枪形。
class CategorySilhouette extends StatelessWidget {
  final String category;
  final double width;
  final double height;
  final Color color;
  const CategorySilhouette({
    super.key,
    required this.category,
    this.width = 110,
    this.height = 46,
    this.color = const Color(0xFF4A4238),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _SilhouettePainter(category, color),
      ),
    );
  }
}

Path _rrect(double x, double y, double w, double h, [double r = 2]) {
  return Path()..addRRect(RRect.fromLTRBR(x, y, x + w, y + h, Radius.circular(r)));
}

Path _rect(double x, double y, double w, double h) {
  return Path()..addRect(Rect.fromLTWH(x, y, w, h));
}

/// 通用步枪下半身：机匣 + 弯枪托 + 弯弹匣 + 握把 + 护圈。
List<Path> _rifleLower(double stockX, double receiverX, double receiverW) {
  return [
    _rrect(receiverX, 14, receiverW, 10, 2),
    // 弯枪托
    Path()
      ..moveTo(receiverX, 14)
      ..quadraticBezierTo(stockX + 8, 16, stockX + 2, 20)
      ..lineTo(stockX + 2, 29)
      ..quadraticBezierTo(stockX + 10, 30, receiverX, 27)
      ..close(),
    // 弯弹匣
    Path()
      ..moveTo(receiverX + 10, 24)
      ..lineTo(receiverX + 19, 24)
      ..quadraticBezierTo(receiverX + 17, 31, receiverX + 14, 37)
      ..lineTo(receiverX + 8, 37)
      ..quadraticBezierTo(receiverX + 8, 31, receiverX + 10, 24)
      ..close(),
    // 握把
    Path()
      ..moveTo(receiverX + 2, 24)
      ..lineTo(receiverX + 9, 24)
      ..quadraticBezierTo(receiverX + 8, 30, receiverX + 6, 34)
      ..lineTo(receiverX, 34)
      ..close(),
  ];
}

List<Path> _guard(double x, double y, double w, double h) {
  return [_rrect(x, y, w, h, 3)];
}

class _SilhouettePainter extends CustomPainter {
  final String category;
  final Color color;
  _SilhouettePainter(this.category, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100, size.height / 44);
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final (fills, strokes) = _shapes(category);
    for (final p in fills) {
      canvas.drawPath(p, fill);
    }
    for (final p in strokes) {
      canvas.drawPath(p, stroke);
    }
  }

  (List<Path>, List<Path>) _shapes(String c) {
    switch (c) {
      case '手枪':
        return (
          [
            _rrect(8, 11, 54, 9, 2), // 套筒
            _rect(14, 8, 6, 3), // 照门
            _rect(56, 8, 3, 3), // 准星
            _rect(12, 20, 44, 4), // 底把
            // 弯握把
            Path()
              ..moveTo(38, 20)
              ..lineTo(54, 20)
              ..quadraticBezierTo(53, 30, 49, 41)
              ..lineTo(37, 41)
              ..quadraticBezierTo(36, 30, 38, 20)
              ..close(),
          ],
          _guard(22, 20, 12, 9),
        );
      case '步枪':
        return (
          [
            _rect(64, 18, 33, 2.5), // 枪管
            _rect(92, 14, 2, 4), // 准星
            _rrect(36, 16, 28, 7, 1.5), // 护木
            ..._rifleLower(4, 18, 20),
          ],
          _guard(24, 22, 10, 8),
        );
      case '精确射手步枪':
        return (
          [
            _rrect(30, 7, 22, 5, 2.5), // 瞄准镜
            _rect(34, 12, 3, 3),
            _rect(45, 12, 3, 3),
            _rect(62, 18, 35, 2.5), // 枪管
            _rrect(36, 16, 27, 7, 1.5),
            ..._rifleLower(4, 18, 20),
            // 脚架
            Path()
              ..moveTo(56, 23)
              ..lineTo(58, 23)
              ..lineTo(64, 35)
              ..lineTo(62, 35)
              ..close(),
            Path()
              ..moveTo(56, 23)
              ..lineTo(58, 23)
              ..lineTo(52, 35)
              ..lineTo(50, 35)
              ..close(),
          ],
          _guard(24, 22, 10, 8),
        );
      case '狙击步枪':
        return (
          [
            _rrect(28, 7, 26, 5, 2.5), // 大瞄准镜
            _rect(32, 12, 3, 3),
            _rect(46, 12, 3, 3),
            _rect(64, 18, 34, 2.5), // 长枪管
            _rect(93, 14, 2, 4),
            _rrect(38, 16, 27, 7, 1.5),
            ..._rifleLower(6, 20, 20),
            // 贴腮板
            _rrect(8, 12, 12, 3, 1.5),
            // 脚架
            Path()
              ..moveTo(58, 23)
              ..lineTo(60, 23)
              ..lineTo(66, 35)
              ..lineTo(64, 35)
              ..close(),
            Path()
              ..moveTo(58, 23)
              ..lineTo(60, 23)
              ..lineTo(54, 35)
              ..lineTo(52, 35)
              ..close(),
          ],
          _guard(26, 22, 10, 8),
        );
      case '反器材步枪':
        return (
          [
            _rrect(26, 7, 20, 5, 2.5), // 瞄准镜
            _rect(30, 12, 3, 3),
            _rect(40, 12, 3, 3),
            _rect(52, 17, 38, 4), // 粗长枪管
            _rrect(90, 14, 9, 10, 1.5), // 制退器
            _rrect(34, 15, 20, 9, 1.5), // 护木
            ..._rifleLower(4, 18, 20),
            // 脚架
            Path()
              ..moveTo(52, 24)
              ..lineTo(54, 24)
              ..lineTo(60, 36)
              ..lineTo(58, 36)
              ..close(),
            Path()
              ..moveTo(52, 24)
              ..lineTo(54, 24)
              ..lineTo(48, 36)
              ..lineTo(46, 36)
              ..close(),
          ],
          _guard(24, 22, 10, 8),
        );
      case '冲锋枪':
        return (
          [
            _rect(62, 18, 28, 3), // 枪管
            _rrect(52, 16, 12, 7, 1.5), // 护罩
            _rrect(24, 15, 32, 10, 2), // 机匣
            // 折叠枪托
            Path()
              ..moveTo(24, 17)
              ..lineTo(8, 17)
              ..lineTo(8, 23)
              ..lineTo(24, 23)
              ..close(),
            // 直弹匣
            Path()
              ..moveTo(32, 25)
              ..lineTo(38, 25)
              ..lineTo(37, 39)
              ..lineTo(31, 39)
              ..close(),
            // 握把
            Path()
              ..moveTo(22, 25)
              ..lineTo(29, 25)
              ..quadraticBezierTo(28, 31, 26, 35)
              ..lineTo(20, 35)
              ..close(),
          ],
          _guard(24, 22, 9, 8),
        );
      case '机枪':
        return (
          [
            _rect(62, 16, 30, 3), // 枪管
            _rrect(20, 14, 44, 10, 2), // 机匣
            // 弹箱
            Path()
              ..moveTo(28, 24)
              ..lineTo(42, 24)
              ..lineTo(42, 32)
              ..quadraticBezierTo(35, 35, 28, 32)
              ..close(),
            // 弯枪托
            Path()
              ..moveTo(20, 14)
              ..quadraticBezierTo(10, 16, 6, 20)
              ..lineTo(6, 29)
              ..quadraticBezierTo(12, 30, 20, 27)
              ..close(),
            // 脚架
            Path()
              ..moveTo(54, 24)
              ..lineTo(56, 24)
              ..lineTo(62, 36)
              ..lineTo(60, 36)
              ..close(),
            Path()
              ..moveTo(54, 24)
              ..lineTo(56, 24)
              ..lineTo(48, 36)
              ..lineTo(46, 36)
              ..close(),
          ],
          [
            _rrect(30, 9, 18, 5, 2.5), // 提把（描边环）
            ..._guard(24, 22, 9, 8),
          ],
        );
      case '霰弹枪':
        return (
          [
            _rrect(48, 16, 48, 5, 2), // 粗枪管
            _rect(92, 13, 2, 3), // 珠状准星
            _rect(48, 22, 32, 4), // 弹仓管
            _rrect(42, 22, 12, 5, 1.5), // 泵柄
            _rrect(20, 15, 30, 10, 2), // 机匣
            // 弯枪托
            Path()
              ..moveTo(20, 15)
              ..quadraticBezierTo(10, 17, 5, 21)
              ..lineTo(5, 30)
              ..quadraticBezierTo(12, 31, 20, 27)
              ..close(),
            // 握把
            Path()
              ..moveTo(24, 25)
              ..lineTo(31, 25)
              ..quadraticBezierTo(30, 31, 28, 35)
              ..lineTo(22, 35)
              ..close(),
          ],
          _guard(26, 22, 9, 8),
        );
      default:
        return _shapes('手枪');
    }
  }

  @override
  bool shouldRepaint(covariant _SilhouettePainter old) =>
      old.category != category || old.color != color;
}
