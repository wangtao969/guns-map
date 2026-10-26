import 'package:flutter/material.dart';
import '../models.dart';

/// 族系识别图：按枪族画的标志性特征线图（实心填充、枪口朝右），
/// 不是某支枪的精确外形，而是“认出这个族系靠哪几个特征”。
/// 目前只画规模前 5 的族系；其余族系仍走参数化轮廓兜底。
///
/// 族系名 -> （展示名，识别要点）。要点只写该族系公认的标志性特征，
/// 不写需要查证的细节数据。

const Map<String, (String, List<String>)> familyDiagramInfo = {
  'ar': (
    'AR系',
    ['导轨式机匣顶盖，可装各类瞄具', '弹匣较直、仅轻微弧度', '伸缩枪托是常见标志', '拉机柄位于机匣尾部上方'],
  ),
  'glock': (
    '格洛克系',
    ['方正套筒，棱角分明', '无外露击锤', '扳机护圈呈方形', '握把倾角大'],
  ),
  'aw': (
    '精密国际 AW 系',
    ['大口径物镜瞄准镜', '重型枪管配制退器', '拇指孔式可调枪托', '可拆弹匣与两脚架'],
  ),
  'mauser98': (
    '毛瑟 98 系',
    ['旋转后拉枪机，拉机柄向下弯', '木质护木长至近枪口', '弹仓内置，机匣顶部有桥夹导槽', '刀片式准星'],
  ),
  'mossberg': (
    '莫斯伯格系',
    ['机匣顶部后方的顶置保险', '泵动护木', '管状弹仓位于枪管下方', '珠状准星'],
  ),
};

/// 该枪是否有前 5 族系的识别图；有则返回族系 key，否则返回 null。
String? familyDiagramOf(Gun gun) {
  final n = gun.name
      .toUpperCase()
      .replaceAll(' ', '')
      .replaceAll('·', '')
      .replaceAll('-', '')
      .replaceAll('.', '')
      .replaceAll('/', '');
  if (n.contains('格洛克') || n.contains('GLOCK')) return 'glock';
  if (n.contains('莫斯伯格') || n.contains('MOSSBERG')) return 'mossberg';
  if (n.contains('精确国际') ||
      n.contains('精密国际') ||
      n.contains('ACCURACY') ||
      n.contains('L96') ||
      n.contains('AWM') ||
      n.contains('AXMC') ||
      n.contains('AXSR') ||
      n.contains('ATX') ||
      n.contains('AEMK') ||
      n.contains('AT执法')) {
    return 'aw';
  }
  if (n.contains('毛瑟') ||
      n.contains('MAUSER') ||
      n.contains('KAR98') ||
      n.contains('98K') ||
      n.contains('98式') ||
      n.contains('98A') ||
      n.contains('VZ98') ||
      n.contains('VZ24') ||
      n.contains('VZ33') ||
      n.contains('WZ29') ||
      n.contains('M49卡宾') ||
      n.contains('M48') ||
      n.contains('3340') ||
      n.contains('中正式') ||
      n.contains('M1943') ||
      n.contains('M1938') ||
      n.contains('M2447')) {
    return 'mauser98';
  }
  // AR 系：霰弹枪里的 M4（贝内利 M4）与 M40/M400 不在此列；
  // M16/LAR 需防子串误中（如 SOCOM 16、Galil ARM）。
  if (gun.category == '霰弹枪') return null;
  if (n.contains('M110A1')) return null; // HK417 系，不属 AR 系
  final arStart = RegExp(r'^M4(?![0-9])').hasMatch(n);
  final arWord = RegExp(r'(?<![A-Z])(M16|LAR)').hasMatch(n);
  const arMarks = [
    'AR15', 'AR10', 'AR556', 'M&P15', 'MP15', 'M&P10', 'MP10', 'M110',
    'STAG15', 'STAG10', 'DDM4', 'DD5', 'DD4', 'MR556', 'REC7', 'SIG516',
    'SIG716', 'FN15', 'LMT', 'LWRC', 'SR15', 'SR25', 'MK18', 'M468', 'DPMS',
    'C7A2', 'C8A3', 'POF', 'ZION', 'ARAD', 'SAINT', '圣徒', '锡安', '阿拉德',
    '卡梅尔', 'SFAR', 'MSR10', 'M4E1', 'M5E1',
  ];
  if (arStart || arWord || arMarks.any(n.contains)) return 'ar';
  return null;
}

class FamilyDiagram extends StatelessWidget {
  final String family;
  final double width;
  final double height;
  final Color color;
  const FamilyDiagram({
    super.key,
    required this.family,
    this.width = 288,
    this.height = 144,
    this.color = const Color(0xFFE8E2D4),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _FamilyPainter(family, color),
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

Path _guardRing(double x, double y, double w, double h, [double r = 3]) {
  return Path()
    ..fillType = PathFillType.evenOdd
    ..addRRect(RRect.fromLTRBR(x, y, x + w, y + h, Radius.circular(r)))
    ..addRect(Rect.fromLTWH(x + 3, y + 3, w - 6, h - 6));
}

Path _circle(double cx, double cy, double r) {
  return Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r));
}

class _FamilyPainter extends CustomPainter {
  final String family;
  final Color color;
  _FamilyPainter(this.family, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 120, size.height / 60);
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    for (final p in _shapes()) {
      canvas.drawPath(p, fill);
    }
  }

  List<Path> _shapes() {
    switch (family) {
      case 'ar':
        // M4：导轨机匣、A2 准星、直弹匣、伸缩托。
        return [
          _rect(78, 27, 38, 2.2), // 枪管
          _rrect(114, 26, 4, 4.5, 1), // 消焰器
          _rect(106, 22.5, 2, 4.5), // A2 准星柱
          _rect(104.5, 22.5, 5, 1.5), // 准星护耳
          _rrect(52, 25.5, 26, 6, 1.5), // 护木
          for (var i = 0; i < 5; i++) _rect(54.0 + i * 4, 24.5, 2, 1), // 护木导轨齿
          _rrect(28, 25, 24, 8, 1.5), // 导轨机匣
          for (var i = 0; i < 5; i++) _rect(30.0 + i * 4, 24, 2, 1), // 机匣导轨齿
          _rect(30, 22.5, 3, 2.5), // 后照门
          _rect(14, 27, 14, 2.5), // 缓冲管
          _rrect(4, 24, 10, 12, 1.5), // 伸缩枪托
          Path() // 握把
            ..moveTo(30, 33)
            ..lineTo(37, 33)
            ..quadraticBezierTo(36, 39, 35, 44)
            ..lineTo(28, 44)
            ..close(),
          Path() // 近直弹匣（轻微弧度）
            ..moveTo(42, 33)
            ..lineTo(49, 33)
            ..quadraticBezierTo(48, 40, 46, 47)
            ..lineTo(40, 47)
            ..quadraticBezierTo(41, 40, 42, 33)
            ..close(),
          _guardRing(34, 33, 11, 7),
          _rect(40, 35, 2, 4), // 扳机
        ];
      case 'glock':
        // Glock：方正套筒、方形护圈、无外露击锤、大倾角握把。
        return [
          Path() // 套筒（前端微斜）
            ..moveTo(16, 22)
            ..lineTo(108, 22)
            ..lineTo(112, 25)
            ..lineTo(112, 29)
            ..lineTo(16, 29)
            ..close(),
          _rect(20, 19, 6, 3), // 照门
          _rect(104, 19, 3, 3), // 准星
          _rect(18, 29, 66, 4), // 底把
          Path() // 大倾角握把
            ..moveTo(36, 33)
            ..lineTo(58, 33)
            ..quadraticBezierTo(57, 44, 52, 54)
            ..lineTo(38, 54)
            ..quadraticBezierTo(37, 44, 36, 33)
            ..close(),
          _guardRing(40, 33, 15, 8, 1), // 方形护圈
          _rect(48, 35, 2, 5), // 扳机
        ];
      case 'aw':
        // 精密国际 AW：大物镜瞄准镜、重枪管制退器、拇指孔枪托、脚架。
        return [
          _rrect(36, 13, 30, 5, 2.5), // 瞄准镜筒
          _rrect(64, 11, 8, 9, 2), // 大物镜
          _rrect(32, 13, 4, 5, 2), // 目镜
          _rect(42, 18, 3, 2), // 镜座
          _rect(58, 18, 3, 2),
          _rect(70, 25, 44, 3.5), // 重枪管
          _rrect(112, 23.5, 6, 6.5, 1), // 制退器
          _rrect(30, 24, 40, 9, 2), // 机匣
          Path() // 拇指孔枪托（外框 + 镂空内孔一次成型）
            ..fillType = PathFillType.evenOdd
            ..moveTo(30, 24)
            ..quadraticBezierTo(14, 23, 5, 26)
            ..lineTo(4, 36)
            ..quadraticBezierTo(14, 38, 30, 33)
            ..close()
            ..addRRect(
                RRect.fromLTRBR(12, 27, 22, 32, const Radius.circular(2))),
          _rrect(10, 20, 14, 3, 1.5), // 可调贴腮板
          _rect(44, 33, 10, 10), // 可拆弹匣
          _guardRing(38, 33, 9, 6),
          _rect(42, 35, 2, 3), // 扳机
          _circle(33, 30, 2), // 枪机拉柄球头
          Path() // 脚架
            ..moveTo(80, 33)
            ..lineTo(82, 33)
            ..lineTo(88, 54)
            ..lineTo(86, 54)
            ..close(),
          Path()
            ..moveTo(80, 33)
            ..lineTo(82, 33)
            ..lineTo(76, 54)
            ..lineTo(74, 54)
            ..close(),
        ];
      case 'mauser98':
        // 毛瑟 98：长木护木、向下弯的拉机柄、刀片准星、桥夹导槽。
        return [
          _rect(66, 26.5, 50, 2), // 枪管
          _rect(110, 23, 2, 3.5), // 刀片准星
          _rect(60, 23, 4, 3.5), // 表尺照门
          _rect(58, 26, 8, 1),
          _rrect(34, 23, 24, 9, 2), // 机匣
          Path() // 长木护木与枪托
            ..moveTo(34, 27)
            ..lineTo(88, 27)
            ..lineTo(88, 32)
            ..lineTo(44, 35)
            ..lineTo(8, 36)
            ..lineTo(5, 31)
            ..lineTo(5, 27)
            ..close(),
          _rrect(4, 26, 2.5, 11, 1), // 托底板
          _rect(40, 20, 2.5, 4), // 拉机柄杆
          _circle(41, 19, 2), // 拉机柄球头
          _rect(42, 32, 10, 2), // 弹仓底板
          _guardRing(44, 32, 10, 7),
          _rect(50, 34, 2, 4), // 扳机
        ];
      case 'mossberg':
        // 莫斯伯格：顶置保险、泵动护木、管状弹仓、珠状准星。
        return [
          _rect(50, 25, 66, 2.5), // 枪管
          _circle(112, 23, 1.5), // 珠状准星
          _rect(50, 28.5, 42, 3), // 管状弹仓
          _rrect(56, 27.5, 16, 6, 2), // 泵动护木
          _rrect(26, 23, 24, 10, 2), // 机匣
          _rect(28, 21, 4, 2), // 顶置保险
          Path() // 枪托
            ..moveTo(26, 23)
            ..lineTo(10, 24)
            ..lineTo(4, 28)
            ..lineTo(4, 38)
            ..lineTo(12, 38)
            ..lineTo(26, 33)
            ..close(),
          _rrect(3, 27, 2.5, 12, 1), // 托底板
          Path() // 握把
            ..moveTo(30, 33)
            ..lineTo(36, 33)
            ..quadraticBezierTo(35, 37, 34, 40)
            ..lineTo(28, 40)
            ..close(),
          _guardRing(32, 33, 10, 7),
          _rect(38, 35, 2, 4), // 扳机
        ];
      default:
        return [];
    }
  }

  @override
  bool shouldRepaint(covariant _FamilyPainter old) =>
      old.family != family || old.color != color;
}
