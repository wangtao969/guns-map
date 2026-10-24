import 'package:flutter/material.dart';

/// 品类阴影图标：在 100×44 的画布上用实色多边形画出各类型枪械的剪影。
class CategorySilhouette extends StatelessWidget {
  final String category;
  final double width;
  final double height;
  final Color color;
  const CategorySilhouette({
    super.key,
    required this.category,
    this.width = 96,
    this.height = 42,
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

Path _poly(List<List<double>> pts) {
  final p = Path();
  p.moveTo(pts.first[0], pts.first[1]);
  for (final pt in pts.skip(1)) {
    p.lineTo(pt[0], pt[1]);
  }
  p.close();
  return p;
}

Path _rect(double x, double y, double w, double h) {
  return Path()..addRect(Rect.fromLTWH(x, y, w, h));
}

class _SilhouettePainter extends CustomPainter {
  final String category;
  final Color color;
  _SilhouettePainter(this.category, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100, size.height / 44);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    for (final path in _shapes(category)) {
      canvas.drawPath(path, paint);
    }
  }

  List<Path> _shapes(String c) {
    switch (c) {
      case '手枪':
        return [
          _rect(8, 12, 54, 9), // 套筒
          _rect(12, 21, 42, 4), // 底把
          _poly([
            [40, 21],
            [54, 21],
            [50, 42],
            [37, 42],
          ]), // 握把
          _rect(24, 21, 9, 9), // 扳机护圈
        ];
      case '步枪':
        return [
          _rect(60, 18, 38, 3), // 枪管
          _rect(34, 16, 27, 7), // 护木
          _rect(18, 14, 18, 10), // 机匣
          _poly([
            [18, 14],
            [4, 18],
            [4, 30],
            [18, 27],
          ]), // 枪托
          _poly([
            [28, 24],
            [37, 24],
            [34, 37],
            [26, 37],
          ]), // 弹匣
          _poly([
            [20, 24],
            [27, 24],
            [25, 34],
            [18, 34],
          ]), // 握把
        ];
      case '精确射手步枪':
        return [
          _rect(30, 8, 22, 5), // 瞄准镜
          _rect(34, 13, 3, 3),
          _rect(45, 13, 3, 3),
          _rect(62, 18, 36, 3), // 枪管
          _rect(36, 16, 27, 7), // 护木
          _rect(18, 14, 20, 10), // 机匣
          _poly([
            [18, 14],
            [4, 18],
            [4, 30],
            [18, 27],
          ]), // 枪托
          _poly([
            [28, 24],
            [37, 24],
            [34, 37],
            [26, 37],
          ]), // 弹匣
          _poly([
            [56, 23],
            [58, 23],
            [64, 34],
            [62, 34],
          ]), // 脚架
        ];
      case '狙击步枪':
        return [
          _rect(30, 8, 26, 5), // 瞄准镜
          _rect(34, 13, 3, 3),
          _rect(48, 13, 3, 3),
          _rect(64, 18, 34, 2.5), // 长枪管
          _rect(38, 16, 27, 7), // 护木
          _rect(20, 14, 20, 10), // 机匣
          _poly([
            [20, 14],
            [6, 18],
            [6, 31],
            [20, 27],
          ]), // 枪托
          _poly([
            [30, 24],
            [38, 24],
            [35, 36],
            [28, 36],
          ]), // 弹匣
          _poly([
            [58, 23],
            [60, 23],
            [66, 35],
            [64, 35],
          ]), // 脚架
          _poly([
            [58, 23],
            [60, 23],
            [54, 35],
            [52, 35],
          ]),
        ];
      case '反器材步枪':
        return [
          _rect(56, 17, 38, 4), // 粗长枪管
          _rect(90, 14, 9, 10), // 制退器
          _rect(36, 15, 22, 9), // 护木
          _rect(18, 13, 20, 11), // 大机匣
          _poly([
            [18, 13],
            [4, 17],
            [4, 31],
            [18, 27],
          ]), // 枪托
          _poly([
            [28, 24],
            [37, 24],
            [34, 37],
            [26, 37],
          ]), // 弹匣
          _poly([
            [52, 24],
            [54, 24],
            [60, 36],
            [58, 36],
          ]), // 脚架
          _poly([
            [52, 24],
            [54, 24],
            [48, 36],
            [46, 36],
          ]),
        ];
      case '冲锋枪':
        return [
          _rect(62, 18, 28, 3), // 枪管
          _rect(26, 15, 38, 10), // 机匣
          _rect(8, 17, 18, 6), // 折叠枪托
          _poly([
            [34, 25],
            [40, 25],
            [38, 39],
            [32, 39],
          ]), // 直弹匣
          _poly([
            [22, 25],
            [29, 25],
            [27, 35],
            [20, 35],
          ]), // 握把
        ];
      case '机枪':
        return [
          _rect(62, 16, 30, 3), // 枪管
          _rect(30, 10, 18, 3), // 提把
          _rect(20, 14, 44, 10), // 机匣
          _rect(28, 24, 14, 10), // 弹鼓/弹箱
          _poly([
            [20, 14],
            [6, 18],
            [6, 29],
            [20, 26],
          ]), // 枪托
          _poly([
            [54, 24],
            [56, 24],
            [62, 36],
            [60, 36],
          ]), // 脚架
          _poly([
            [54, 24],
            [56, 24],
            [48, 36],
            [46, 36],
          ]),
        ];
      case '霰弹枪':
        return [
          _rect(50, 16, 46, 5), // 粗枪管
          _rect(50, 22, 34, 4), // 弹仓
          _rect(20, 15, 32, 10), // 机匣
          _poly([
            [20, 15],
            [5, 19],
            [5, 31],
            [20, 27],
          ]), // 枪托
          _poly([
            [24, 25],
            [31, 25],
            [29, 35],
            [22, 35],
          ]), // 握把
        ];
      default:
        return _shapes('手枪');
    }
  }

  @override
  bool shouldRepaint(covariant _SilhouettePainter old) =>
      old.category != category || old.color != color;
}
