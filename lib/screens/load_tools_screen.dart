import 'package:flutter/material.dart';
import '../widgets/app_top_bar.dart';

/// 装药工具：只做物理换算，不给装药建议。
/// - 单位换算：格令 ↔ 克、英尺/秒 ↔ 米/秒、英寸 ↔ 厘米；
/// - 枪口动能：弹头重 + 初速（你输入的数）算焦耳与英尺·磅；
/// - 后坐力：自由后坐能量，火药燃气速度按 1.75 倍初速估算，结果为参考值。
/// 装药请以手册原文为准，本页不查手册、不推算装药。
class LoadToolsScreen extends StatefulWidget {
  const LoadToolsScreen({super.key});

  @override
  State<LoadToolsScreen> createState() => _LoadToolsScreenState();
}

class _LoadToolsScreenState extends State<LoadToolsScreen> {
  final _grainsCtrl = TextEditingController();
  final _fpsCtrl = TextEditingController();
  final _inchCtrl = TextEditingController();
  final _mmCtrl = TextEditingController();
  final _psiCtrl = TextEditingController();
  final _yardCtrl = TextEditingController();
  final _bulletCtrl = TextEditingController(text: '150');
  final _velocityCtrl = TextEditingController(text: '2800');
  final _powderCtrl = TextEditingController(text: '45');
  final _gunWeightCtrl = TextEditingController(text: '4');

  @override
  void dispose() {
    _grainsCtrl.dispose();
    _fpsCtrl.dispose();
    _inchCtrl.dispose();
    _mmCtrl.dispose();
    _psiCtrl.dispose();
    _yardCtrl.dispose();
    _bulletCtrl.dispose();
    _velocityCtrl.dispose();
    _powderCtrl.dispose();
    _gunWeightCtrl.dispose();
    super.dispose();
  }

  static const _grToG = 0.06479891;
  static const _fpsToMs = 0.3048;

  String _fmt(double v, [int digits = 2]) {
    var s = v.toStringAsFixed(digits);
    while (s.contains('.') && s.endsWith('0')) {
      s = s.substring(0, s.length - 1);
    }
    if (s.endsWith('.')) s = s.substring(0, s.length - 1);
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final grains = double.tryParse(_grainsCtrl.text) ?? 0;
    final fps = double.tryParse(_fpsCtrl.text) ?? 0;
    final inch = double.tryParse(_inchCtrl.text) ?? 0;
    final mm = double.tryParse(_mmCtrl.text) ?? 0;
    final psi = double.tryParse(_psiCtrl.text) ?? 0;
    final yard = double.tryParse(_yardCtrl.text) ?? 0;
    final bulletGr = double.tryParse(_bulletCtrl.text) ?? 0;
    final velocityFps = double.tryParse(_velocityCtrl.text) ?? 0;
    final powderGr = double.tryParse(_powderCtrl.text) ?? 0;
    final gunKg = double.tryParse(_gunWeightCtrl.text) ?? 0;

    final bulletKg = bulletGr * _grToG / 1000;
    final velocityMs = velocityFps * _fpsToMs;
    final energyJ = 0.5 * bulletKg * velocityMs * velocityMs;
    final energyFtLb = energyJ * 0.737562;

    final powderKg = powderGr * _grToG / 1000;
    final recoilV = gunKg > 0
        ? (bulletKg * velocityMs + powderKg * velocityMs * 1.75) / gunKg
        : 0.0;
    final recoilJ = 0.5 * gunKg * recoilV * recoilV;
    final recoilFtLb = recoilJ * 0.737562;

    return Scaffold(
      appBar: SubPageAppBar(title: '装药工具'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          const Text('只做物理换算，不给装药建议；装药请以手册原文为准。',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 16),
          const Text('单位换算',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _NumberField(
            controller: _grainsCtrl,
            label: '格令（gr）',
            onChanged: (_) => setState(() {}),
          ),
          if (grains > 0)
            _ResultLine('= ${_fmt(grains * _grToG, 3)} 克'),
          const SizedBox(height: 8),
          _NumberField(
            controller: _fpsCtrl,
            label: '初速（英尺/秒 fps）',
            onChanged: (_) => setState(() {}),
          ),
          if (fps > 0)
            _ResultLine('= ${_fmt(fps * _fpsToMs, 2)} 米/秒'),
          const SizedBox(height: 8),
          _NumberField(
            controller: _inchCtrl,
            label: '长度（英寸）',
            onChanged: (_) => setState(() {}),
          ),
          if (inch > 0)
            _ResultLine('= ${_fmt(inch * 2.54, 2)} 厘米'),
          const SizedBox(height: 8),
          _NumberField(
            controller: _mmCtrl,
            label: '弹头直径（毫米）',
            onChanged: (_) => setState(() {}),
          ),
          if (mm > 0)
            _ResultLine('= ${_fmt(mm / 25.4, 3)} 英寸'),
          const SizedBox(height: 8),
          _NumberField(
            controller: _psiCtrl,
            label: '膛压（psi）',
            onChanged: (_) => setState(() {}),
          ),
          if (psi > 0)
            _ResultLine('= ${_fmt(psi * 0.00689476, 2)} 兆帕（MPa）'),
          const SizedBox(height: 8),
          _NumberField(
            controller: _yardCtrl,
            label: '距离（码）',
            onChanged: (_) => setState(() {}),
          ),
          if (yard > 0)
            _ResultLine('= ${_fmt(yard * 0.9144, 2)} 米'),
          const SizedBox(height: 20),
          const Text('枪口动能',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _NumberField(
            controller: _bulletCtrl,
            label: '弹头重（格令）',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          _NumberField(
            controller: _velocityCtrl,
            label: '初速（英尺/秒）',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          _ResultLine(
              '枪口动能：${_fmt(energyJ, 1)} 焦耳（${_fmt(energyFtLb, 1)} 英尺·磅）'),
          const SizedBox(height: 20),
          const Text('后坐力（自由后坐能量）',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _NumberField(
            controller: _powderCtrl,
            label: '装药量（格令）',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          _NumberField(
            controller: _gunWeightCtrl,
            label: '枪重（千克）',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          _ResultLine(
              '后坐能量：${_fmt(recoilJ, 1)} 焦耳（${_fmt(recoilFtLb, 1)} 英尺·磅），后坐速度 ${_fmt(recoilV, 2)} 米/秒'),
          const SizedBox(height: 8),
          const Text('火药燃气速度按 1.75 倍初速估算，结果为参考值。',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final ValueChanged<String> onChanged;
  const _NumberField({
    required this.controller,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
      ),
    );
  }
}

class _ResultLine extends StatelessWidget {
  final String text;
  const _ResultLine(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(text,
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFFE86A1C),
              fontSize: 15)),
    );
  }
}
