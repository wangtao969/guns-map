import 'package:flutter/material.dart';
import '../models.dart';

/// 参数化示意轮廓：给没有实物照片的枪，按它自己的全长与枪管长比例
/// 生成一张侧面轮廓，而不是所有枪共用一张品类代表图。
///
/// 画法与现有品类剪影同语言：实心填充、枪口一律朝右、100×44 坐标空间。
/// 长枪按“枪托—机匣—护木—枪管”分段布长：枪管段占全长比例取自该枪
/// 自己的枪管长/全长（解析不到时退回该品类原型枪的比例）；手枪按
/// 滑套与握把分段。轮廓只保证品类形态与长短比例正确，细节（护木纹理、
/// 准星形状、铭文等）一律不画，详情页会标注“示意轮廓，非实物”。
class ParametricSilhouette extends StatelessWidget {
  final Gun gun;
  final double width;
  final double height;
  final Color color;
  const ParametricSilhouette({
    super.key,
    required this.gun,
    this.width = 288,
    this.height = 127,
    this.color = const Color(0xFFE8E2D4),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _ParametricPainter(gun, color),
      ),
    );
  }
}

double? _mm(String s) {
  final m = RegExp(r'([\d,]+(?:\.\d+)?)\s*mm').firstMatch(s);
  if (m != null) {
    return double.tryParse(m.group(1)!.replaceAll(',', ''));
  }
  final inch = RegExp(r'([\d.]+)\s*(?:in|英寸)').firstMatch(s);
  if (inch != null) {
    final v = double.tryParse(inch.group(1)!);
    if (v != null) return v * 25.4;
  }
  return null;
}

int? _count(String s) {
  final m = RegExp(r'(\d+)').firstMatch(s);
  return m == null ? null : int.tryParse(m.group(1)!);
}

/// 各品类原型枪的枪管占全长比例（数据缺失时的退路）。
const Map<String, double> _prototypeFrac = {
  '手枪': 0.56, // Glock 17：114 / 202
  '步枪': 0.44, // M4：368 / 838
  '精确射手步枪': 0.51, // SVD：620 / 1225
  '狙击步枪': 0.56, // AWM：660 / 1180
  '反器材步枪': 0.51, // M82A1：737 / 1422
  '冲锋枪': 0.33, // MP5：225 / 680
  '机枪': 0.45, // M249：465 / 1030
  '霰弹枪': 0.57, // Remington 870：710 / 1245
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

class _ParametricPainter extends CustomPainter {
  final Gun gun;
  final Color color;
  _ParametricPainter(this.gun, this.color);

  double get _frac {
    final b = _mm(gun.barrel);
    final l = _mm(gun.length);
    if (b != null && l != null && l > 0) {
      return (b / l).clamp(0.15, 0.80);
    }
    return _prototypeFrac[gun.category] ?? 0.5;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100, size.height / 44);
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    for (final p in _shapes()) {
      canvas.drawPath(p, fill);
    }
  }

  List<Path> _shapes() {
    if (gun.category == '手枪') return _pistol();
    return _longGun();
  }

  List<Path> _pistol() {
    final frac = _frac;
    final slideFront = 6 + 96 * (0.80 + frac * 0.18);
    final gripDepth = 12 + (1 - frac) * 6;
    return [
      _rrect(6, 12, slideFront - 6, 9, 2), // 套筒
      _rect(10, 9, 5, 3), // 照门
      _rect(slideFront - 5, 9, 3, 3), // 准星
      _rect(8, 21, slideFront - 26, 4), // 底把
      Path() // 握把（倾角随枪管占比微调）
        ..moveTo(32, 21)
        ..lineTo(48, 21)
        ..quadraticBezierTo(47, 30, 43, 21 + gripDepth)
        ..lineTo(31, 21 + gripDepth)
        ..quadraticBezierTo(30, 30, 32, 21)
        ..close(),
      _guardRing(20, 21, 13, 10),
      _rect(27, 24, 2, 6), // 扳机
    ];
  }

  List<Path> _longGun() {
    final frac = _frac;
    const muzzleX = 98.0;
    const totalW = 96.0;
    final barrelBack = muzzleX - totalW * frac; // 机匣前端 = 枪管后端
    var receiverW = 20.0;
    var receiverRear = barrelBack - receiverW;
    if (receiverRear < 10) {
      receiverRear = 10;
      receiverW = barrelBack - receiverRear;
    }
    final receiverFront = barrelBack;
    final barrelLen = muzzleX - receiverFront;
    final isShotgun = gun.category == '霰弹枪';
    final isMachineGun = gun.category == '机枪';
    final hasScope = gun.category == '狙击步枪' ||
        gun.category == '精确射手步枪' ||
        gun.category == '反器材步枪';
    final hasBipod = gun.category == '狙击步枪' ||
        gun.category == '反器材步枪' ||
        isMachineGun;
    final capacity = _count(gun.capacity);
    final shapes = <Path>[
      _rect(receiverFront, 18, barrelLen, 2.5), // 枪管
      _rrect(muzzleX - 3, 16.5, 3, 5.5, 1), // 枪口装置
      _rrect(receiverFront, 16.5, barrelLen * 0.55, 5.5, 2), // 护木
      _rrect(receiverRear, 15, receiverW, 9, 2), // 机匣
      Path() // 枪托（向后收窄的楔形）
        ..moveTo(receiverRear, 15)
        ..quadraticBezierTo(receiverRear - 8, 16, 4, 19)
        ..lineTo(2, 29)
        ..quadraticBezierTo(receiverRear - 6, 29, receiverRear, 26)
        ..close(),
      _rrect(2, 18, 2.5, 12, 1), // 托底板
      Path() // 握把
        ..moveTo(receiverRear + 2, 24)
        ..lineTo(receiverRear + 9, 24)
        ..quadraticBezierTo(receiverRear + 8, 30, receiverRear + 6, 34)
        ..lineTo(receiverRear, 34)
        ..close(),
      _guardRing(receiverRear + 6, 24, 11, 8),
      _rect(receiverRear + 12, 26, 2, 5), // 扳机
    ];
    // 供弹具：霰弹枪是弹仓管，其余按弹容量给弹匣长短。
    if (isShotgun) {
      shapes.add(_rect(receiverFront, 21.5, barrelLen * 0.65, 3.5));
      shapes.add(_rrect(receiverFront + 4, 20.5, 10, 5, 1.5));
    } else if (capacity != null && capacity < 10) {
      shapes.add(_rect(receiverRear + 8, 24, 6, 6));
    } else {
      final magLen = capacity == null
          ? 12.0
          : (capacity >= 25 ? 15.0 : 11.0);
      shapes.add(Path() // 弯弹匣
        ..moveTo(receiverRear + 8, 24)
        ..lineTo(receiverRear + 15, 24)
        ..quadraticBezierTo(receiverRear + 14, 30, receiverRear + 11, 24 + magLen)
        ..lineTo(receiverRear + 5, 24 + magLen)
        ..quadraticBezierTo(receiverRear + 5, 30, receiverRear + 8, 24)
        ..close());
    }
    if (isMachineGun) {
      shapes.add(Path() // 弹箱
        ..moveTo(receiverRear + 4, 24)
        ..lineTo(receiverRear + 18, 24)
        ..lineTo(receiverRear + 18, 32)
        ..quadraticBezierTo(receiverRear + 11, 35, receiverRear + 4, 32)
        ..close());
    }
    // 瞄具：三类长程枪给瞄准镜，其余给前后准星。
    if (hasScope) {
      shapes.add(_rrect(receiverRear + 2, 9, receiverW - 4, 4.5, 2));
      shapes.add(_rect(receiverRear + 5, 13.5, 3, 1.5));
      shapes.add(_rect(receiverRear + receiverW - 8, 13.5, 3, 1.5));
    } else {
      shapes.add(_rect(receiverRear + 2, 12, 3, 3));
      if (isShotgun) {
        shapes.add(_rect(muzzleX - 4, 15, 2, 3));
      } else {
        shapes.add(_rect(muzzleX - 8, 14, 2, 4));
      }
    }
    // 脚架：从护木中段向下张开的两条腿。
    if (hasBipod) {
      final legX = receiverFront + barrelLen * 0.45;
      shapes.add(Path()
        ..moveTo(legX, 22)
        ..lineTo(legX + 2, 22)
        ..lineTo(legX + 8, 40)
        ..lineTo(legX + 6, 40)
        ..close());
      shapes.add(Path()
        ..moveTo(legX, 22)
        ..lineTo(legX + 2, 22)
        ..lineTo(legX - 4, 40)
        ..lineTo(legX - 6, 40)
        ..close());
    }
    return shapes;
  }

  @override
  bool shouldRepaint(covariant _ParametricPainter old) =>
      old.gun.name != gun.name || old.color != color;
}
