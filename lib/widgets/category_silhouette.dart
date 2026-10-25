import 'package:flutter/material.dart';

/// 品类剪影图标：每个品类对应一支真实代表枪型，用实心填充画出侧面轮廓。
/// 不再用描边圆环画扳机护圈（之前那种悬空的细环就是“丝带状”观感的来源），
/// 护圈改为与底把相连的实心环（外框 + 镂空内孔一次成型）。
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

/// 各品类剪影的真实原型枪型，卡片上同步标注，杜绝“乱用模型”。
const Map<String, String> categoryPrototype = {
  '手枪': 'Glock 17',
  '步枪': 'M4 卡宾枪',
  '精确射手步枪': 'SVD',
  '狙击步枪': 'AWM',
  '反器材步枪': 'Barrett M82A1',
  '冲锋枪': 'MP5',
  '机枪': 'M249 SAW',
  '霰弹枪': 'Mossberg 500',
};

/// 各品类代表枪型的透明底 PNG 抠图（像 CS:GO、CF 武器栏的干净侧视图，
/// 枪口一律朝右，全枪可见；M4/MP5 来自 Commons 透明底原图，SVD/Glock
/// 由透明底图水平翻转而来，AWM/M82A1/M249 由白底官方照抠图，
/// Mossberg 500 由瓷砖底实拍抠图；授权见品类页脚署名）。
/// 品类卡和详情页无图占位都用它。
const Map<String, String> categoryPhoto = {
  '手枪': 'assets/images/category-handgun.png',
  '步枪': 'assets/images/category-rifle.png',
  '精确射手步枪': 'assets/images/category-dmr.png',
  '狙击步枪': 'assets/images/category-sniper.png',
  '反器材步枪': 'assets/images/category-antimateriel.png',
  '冲锋枪': 'assets/images/category-smg.png',
  '机枪': 'assets/images/category-mg.png',
  '霰弹枪': 'assets/images/category-shotgun.png',
};

Path _rrect(double x, double y, double w, double h, [double r = 2]) {
  return Path()..addRRect(RRect.fromLTRBR(x, y, x + w, y + h, Radius.circular(r)));
}

Path _rect(double x, double y, double w, double h) {
  return Path()..addRect(Rect.fromLTWH(x, y, w, h));
}

/// 实心扳机护圈环：外框与内孔用 evenOdd 一次画出，环体与底把相连不悬空。
Path _guardRing(double x, double y, double w, double h) {
  return Path()
    ..fillType = PathFillType.evenOdd
    ..addRRect(RRect.fromLTRBR(x, y, x + w, y + h, const Radius.circular(3)))
    ..addRect(Rect.fromLTWH(x + 3, y + 3, w - 6, h - 6));
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
    for (final p in _shapes(category)) {
      canvas.drawPath(p, fill);
    }
  }

  List<Path> _shapes(String c) {
    switch (c) {
      case '手枪':
        // Glock 17：方正套筒、方形护圈、无外露击锤、握把大倾角。
        return [
          _rrect(10, 10, 52, 9, 2), // 套筒
          _rect(14, 7, 5, 3), // 照门
          _rect(58, 7, 3, 3), // 准星
          _rect(12, 19, 46, 4), // 底把
          Path() // 握把
            ..moveTo(36, 19)
            ..lineTo(52, 19)
            ..quadraticBezierTo(51, 30, 47, 41)
            ..lineTo(35, 41)
            ..quadraticBezierTo(34, 30, 36, 19)
            ..close(),
          _guardRing(20, 19, 13, 10),
          _rect(27, 22, 2, 6), // 扳机
        ];
      case '步枪':
        // M4 卡宾枪：提把、A2 准星、圆护木、弯弹匣、伸缩枪托。
        return [
          _rect(66, 18, 28, 2.5), // 枪管
          _rect(93, 17, 3, 4.5), // 消焰器
          _rect(87, 13, 2, 5), // A2 准星柱
          _rect(85, 17, 6, 2),
          _rrect(40, 15, 28, 8, 2), // 圆护木
          _rrect(20, 10, 22, 3, 1.5), // 提把
          _rect(20, 13, 3, 3),
          _rect(39, 13, 3, 3),
          _rrect(18, 16, 24, 8, 2), // 机匣
          Path() // 弯弹匣
            ..moveTo(30, 24)
            ..lineTo(37, 24)
            ..quadraticBezierTo(36, 31, 32, 38)
            ..lineTo(26, 38)
            ..quadraticBezierTo(26, 31, 30, 24)
            ..close(),
          _rrect(4, 15, 14, 9, 1), // 伸缩枪托
          _rrect(2, 14, 3, 11, 1), // 托底板
          Path() // 握把
            ..moveTo(20, 24)
            ..lineTo(27, 24)
            ..quadraticBezierTo(26, 30, 24, 34)
            ..lineTo(18, 34)
            ..close(),
          _guardRing(24, 24, 10, 8),
        ];
      case '精确射手步枪':
        // SVD：PSO 瞄准镜、长枪管、大弯弹匣、拇指孔枪托轮廓。
        return [
          _rrect(28, 6, 24, 5, 2.5), // PSO 瞄准镜
          _rect(32, 11, 3, 3),
          _rect(44, 11, 3, 3),
          _rect(64, 18, 32, 2), // 长枪管
          _rect(94, 16, 3, 5), // 制退器
          _rrect(30, 15, 34, 8, 2), // 机匣护木
          Path() // 大弯弹匣
            ..moveTo(40, 23)
            ..lineTo(47, 23)
            ..quadraticBezierTo(46, 31, 41, 38)
            ..lineTo(35, 38)
            ..quadraticBezierTo(35, 31, 40, 23)
            ..close(),
          Path() // 枪托
            ..moveTo(30, 15)
            ..quadraticBezierTo(12, 16, 4, 20)
            ..lineTo(4, 29)
            ..quadraticBezierTo(14, 30, 30, 26)
            ..close(),
          _guardRing(26, 23, 10, 8),
        ];
      case '狙击步枪':
        // AWM：大物镜瞄准镜、重枪管、旋转后拉枪机、可调贴腮枪托、脚架。
        return [
          _rrect(26, 6, 24, 5, 2.5), // 瞄准镜
          _rrect(48, 5, 6, 7, 2), // 大物镜
          _rect(30, 11, 3, 3),
          _rect(42, 11, 3, 3),
          _rect(62, 17, 32, 3), // 重枪管
          _rect(92, 15, 4, 6), // 制退器
          _rrect(32, 15, 30, 8, 2), // 机匣
          _rect(44, 23, 7, 7), // 可拆弹匣
          _rect(36, 23, 2, 4), // 枪机拉柄
          _rrect(33, 27, 5, 3, 1.5), // 拉柄球头
          Path() // 贴腮枪托
            ..moveTo(32, 15)
            ..quadraticBezierTo(12, 13, 5, 18)
            ..lineTo(5, 28)
            ..quadraticBezierTo(14, 29, 32, 25)
            ..close(),
          _rrect(8, 11, 12, 3, 1.5), // 可调贴腮板
          Path() // 脚架
            ..moveTo(56, 23)
            ..lineTo(58, 23)
            ..lineTo(64, 36)
            ..lineTo(62, 36)
            ..close(),
          Path()
            ..moveTo(56, 23)
            ..lineTo(58, 23)
            ..lineTo(52, 36)
            ..lineTo(50, 36)
            ..close(),
          _guardRing(28, 23, 10, 8),
        ];
      case '反器材步枪':
        // Barrett M82A1：巨型制退器、粗长枪管、大弹匣、脚架。
        return [
          _rrect(24, 6, 22, 5, 2.5), // 瞄准镜
          _rect(28, 11, 3, 3),
          _rect(38, 11, 3, 3),
          _rect(52, 16, 38, 4), // 粗长枪管
          _rrect(88, 13, 10, 10, 1.5), // 箭形制退器
          _rrect(30, 14, 26, 10, 2), // 机匣
          _rect(38, 24, 8, 10), // 大弹匣
          Path() // 枪托
            ..moveTo(30, 14)
            ..quadraticBezierTo(10, 16, 4, 20)
            ..lineTo(4, 29)
            ..quadraticBezierTo(12, 30, 30, 26)
            ..close(),
          Path() // 握把
            ..moveTo(22, 24)
            ..lineTo(29, 24)
            ..quadraticBezierTo(28, 30, 26, 34)
            ..lineTo(20, 34)
            ..close(),
          Path() // 脚架
            ..moveTo(50, 24)
            ..lineTo(52, 24)
            ..lineTo(58, 36)
            ..lineTo(56, 36)
            ..close(),
          Path()
            ..moveTo(50, 24)
            ..lineTo(52, 24)
            ..lineTo(46, 36)
            ..lineTo(44, 36)
            ..close(),
          _guardRing(24, 24, 10, 8),
        ];
      case '冲锋枪':
        // MP5：罩式准星、方机匣、直弹匣、伸缩枪托拉杆。
        return [
          _rect(66, 18, 26, 3), // 枪管
          _rect(88, 14, 2, 7), // 罩式准星
          _rect(91, 14, 2, 7),
          _rect(88, 14, 5, 2),
          _rrect(50, 15, 16, 8, 2), // 护木
          _rrect(22, 14, 32, 10, 2), // 机匣
          _rect(6, 16, 16, 2), // 伸缩托拉杆
          _rect(6, 21, 16, 2),
          _rrect(4, 15, 3, 8, 1), // 托底板
          _rect(32, 24, 6, 14), // 直弹匣
          Path() // 握把
            ..moveTo(22, 24)
            ..lineTo(29, 24)
            ..quadraticBezierTo(28, 30, 26, 34)
            ..lineTo(20, 34)
            ..close(),
          _guardRing(24, 24, 9, 8),
        ];
      case '机枪':
        // M249 SAW：提把、弹箱、两脚架、重枪管。
        return [
          _rect(62, 15, 30, 3), // 枪管
          _rrect(40, 10, 16, 3, 1.5), // 提把
          _rect(40, 13, 3, 3),
          _rect(53, 13, 3, 3),
          _rrect(18, 13, 46, 11, 2), // 机匣
          Path() // 弹箱
            ..moveTo(26, 24)
            ..lineTo(42, 24)
            ..lineTo(42, 32)
            ..quadraticBezierTo(34, 35, 26, 32)
            ..close(),
          Path() // 枪托
            ..moveTo(18, 13)
            ..quadraticBezierTo(8, 15, 4, 19)
            ..lineTo(4, 28)
            ..quadraticBezierTo(10, 29, 18, 26)
            ..close(),
          Path() // 脚架
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
          _guardRing(24, 24, 9, 8),
        ];
      case '霰弹枪':
        // Remington 870：泵动护木、弹仓管、珠状准星、木质枪托轮廓。
        return [
          _rrect(46, 15, 48, 5, 2), // 枪管
          _rect(92, 12, 2, 3), // 珠状准星
          _rect(46, 21, 30, 4), // 弹仓管
          _rrect(40, 20, 14, 6, 1.5), // 泵动护木
          _rrect(18, 14, 30, 11, 2), // 机匣
          Path() // 枪托
            ..moveTo(18, 14)
            ..quadraticBezierTo(8, 16, 3, 20)
            ..lineTo(3, 29)
            ..quadraticBezierTo(10, 30, 18, 27)
            ..close(),
          Path() // 握把
            ..moveTo(24, 25)
            ..lineTo(31, 25)
            ..quadraticBezierTo(30, 31, 28, 35)
            ..lineTo(22, 35)
            ..close(),
          _guardRing(24, 25, 9, 8),
        ];
      default:
        return _shapes('手枪');
    }
  }

  @override
  bool shouldRepaint(covariant _SilhouettePainter old) =>
      old.category != category || old.color != color;
}
