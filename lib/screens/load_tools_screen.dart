import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../tools_units.dart';
import '../widgets/app_top_bar.dart';

/// 装药工具：只做物理换算，不给装药建议。
/// - 单位换算：格令 ↔ 克、英尺/秒 ↔ 米/秒、英寸 ↔ 厘米；
/// - 枪口动能：弹头重 + 初速（你输入的数）算焦耳与英尺·磅；
/// - 后坐力：自由后坐能量，火药燃气速度按 1.75 倍初速估算，结果为参考值。
/// 装药请以手册原文为准，本页不查手册、不推算装药。
/// 带入式：手册装药卡与复装记录可把弹头重、初速、装药量带进来，
/// 单位按工具页单位制换算显示；没填就不算，不再用示例数误导。
class LoadToolsScreen extends StatefulWidget {
  /// 带入值一律用英制原单位（格令、英尺/秒），页内按单位制换算显示。
  final double? initialBulletGr;
  final double? initialVelocityFps;
  final double? initialPowderGr;
  final String? initialLabel;
  const LoadToolsScreen(
      {super.key,
      this.initialBulletGr,
      this.initialVelocityFps,
      this.initialPowderGr,
      this.initialLabel});

  @override
  State<LoadToolsScreen> createState() => _LoadToolsScreenState();
}

class _LoadToolsScreenState extends State<LoadToolsScreen> {
  static const _prefsChannel = MethodChannel('gunsmap/prefs');
  static const _prefsKey = 'load_tools_inputs_v1';
  final _grainsCtrl = TextEditingController();
  final _fpsCtrl = TextEditingController();
  final _inchCtrl = TextEditingController();
  final _mmCtrl = TextEditingController();
  final _psiCtrl = TextEditingController();
  final _yardCtrl = TextEditingController();
  final _bulletCtrl = TextEditingController();
  final _velocityCtrl = TextEditingController();
  final _powderCtrl = TextEditingController();
  final _gunWeightCtrl = TextEditingController();

  void _onUnitsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    unitSystemNotifier.addListener(_onUnitsChanged);
    _init();
  }

  /// 先等单位制读好，再读已存输入，最后把带入值盖上去，
  /// 免得单位制还没读好就按错单位显示带入值。
  Future<void> _init() async {
    await loadUnitSystem();
    if (!mounted) return;
    setState(() {});
    await _load();
  }

  Future<void> _load() async {
    try {
      final raw = await _prefsChannel
          .invokeMethod<String>('getString', {'key': _prefsKey})
          .timeout(const Duration(seconds: 2));
      if (raw != null && raw.isNotEmpty && mounted) {
        final m = jsonDecode(raw) as Map<String, dynamic>;
        setState(() {
          void set(TextEditingController c, String k) {
            final v = m[k] as String?;
            if (v != null) c.text = v;
          }
          set(_grainsCtrl, 'grains');
          set(_fpsCtrl, 'fps');
          set(_inchCtrl, 'inch');
          set(_mmCtrl, 'mm');
          set(_psiCtrl, 'psi');
          set(_yardCtrl, 'yard');
          set(_bulletCtrl, 'bullet');
          set(_velocityCtrl, 'velocity');
          set(_powderCtrl, 'powder');
          set(_gunWeightCtrl, 'gunWeight');
        });
      }
    } catch (_) {}
    if (!mounted) return;
    final metric = isMetricUnits;
    final b = widget.initialBulletGr;
    final v = widget.initialVelocityFps;
    final p = widget.initialPowderGr;
    if (b == null && v == null && p == null) return;
    setState(() {
      if (b != null) {
        _bulletCtrl.text = metric ? _fmt(b * _grToG, 2) : _fmt(b);
      }
      if (v != null) {
        _velocityCtrl.text = metric ? _fmt(v * _fpsToMs, 2) : _fmt(v);
      }
      if (p != null) {
        _powderCtrl.text = metric ? _fmt(p * _grToG, 2) : _fmt(p);
      }
    });
    _save();
  }

  void _save() {
    try {
      _prefsChannel.invokeMethod('setString', {
        'key': _prefsKey,
        'value': jsonEncode({
          'grains': _grainsCtrl.text,
          'fps': _fpsCtrl.text,
          'inch': _inchCtrl.text,
          'mm': _mmCtrl.text,
          'psi': _psiCtrl.text,
          'yard': _yardCtrl.text,
          'bullet': _bulletCtrl.text,
          'velocity': _velocityCtrl.text,
          'powder': _powderCtrl.text,
          'gunWeight': _gunWeightCtrl.text,
        }),
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    unitSystemNotifier.removeListener(_onUnitsChanged);
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
    // 动能与后坐力的输入单位跟随工具页单位制：公制时弹头重按克、
    // 初速按米/秒、装药按克、枪重按千克输入，内部换算回格令/英尺/秒
    // 再套原公式；英制时沿用原来的格令/英尺/秒/千克。
    final metric = isMetricUnits;
    final bulletGr = (double.tryParse(_bulletCtrl.text) ?? 0) *
        (metric ? 1 / _grToG : 1);
    final velocityFps = (double.tryParse(_velocityCtrl.text) ?? 0) *
        (metric ? 1 / _fpsToMs : 1);
    final powderGr = (double.tryParse(_powderCtrl.text) ?? 0) *
        (metric ? 1 / _grToG : 1);
    final gunInput = double.tryParse(_gunWeightCtrl.text) ?? 0;
    // 枪重：公制按千克，英制按磅（旧版默认 4 千克，切换到英制后
    // 请按磅重填；结果同时显示焦耳与英尺·磅，不受此影响）。

    final bulletKg = bulletGr * _grToG / 1000;
    final velocityMs = velocityFps * _fpsToMs;
    final energyJ = 0.5 * bulletKg * velocityMs * velocityMs;
    final energyFtLb = energyJ * 0.737562;

    final powderKg = powderGr * _grToG / 1000;
    final gunKg = metric ? gunInput : gunInput * 0.45359237;
    final recoilV = gunKg > 0
        ? (bulletKg * velocityMs + powderKg * velocityMs * 1.75) / gunKg
        : 0.0;
    final recoilJ = 0.5 * gunKg * recoilV * recoilV;
    final recoilFtLb = recoilJ * 0.737562;

    return ValueListenableBuilder<String>(
      valueListenable: unitSystemNotifier,
      builder: (_, __, ___) => Scaffold(
      appBar: SubPageAppBar(title: '装药工具'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          const Text('只做物理换算，不给装药建议；装药请以手册原文为准。',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
          if (widget.initialLabel != null) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text('已从 ${widget.initialLabel} 带入弹头、初速与装药，可直接改。',
                    style: const TextStyle(fontSize: 13)),
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Text('单位换算',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _NumberField(
            controller: _grainsCtrl,
            label: '格令（gr）',
            onChanged: (_) { setState(() {}); _save(); },
          ),
          if (grains > 0)
            _ResultLine('= ${_fmt(grains * _grToG, 3)} 克'),
          const SizedBox(height: 8),
          _NumberField(
            controller: _fpsCtrl,
            label: '初速（英尺/秒 fps）',
            onChanged: (_) { setState(() {}); _save(); },
          ),
          if (fps > 0)
            _ResultLine('= ${_fmt(fps * _fpsToMs, 2)} 米/秒'),
          const SizedBox(height: 8),
          _NumberField(
            controller: _inchCtrl,
            label: '长度（英寸）',
            onChanged: (_) { setState(() {}); _save(); },
          ),
          if (inch > 0)
            _ResultLine('= ${_fmt(inch * 2.54, 2)} 厘米'),
          const SizedBox(height: 8),
          _NumberField(
            controller: _mmCtrl,
            label: '弹头直径（毫米）',
            onChanged: (_) { setState(() {}); _save(); },
          ),
          if (mm > 0)
            _ResultLine('= ${_fmt(mm / 25.4, 3)} 英寸'),
          const SizedBox(height: 8),
          _NumberField(
            controller: _psiCtrl,
            label: '膛压（psi）',
            onChanged: (_) { setState(() {}); _save(); },
          ),
          if (psi > 0)
            _ResultLine('= ${_fmt(psi * 0.00689476, 2)} 兆帕（MPa）'),
          const SizedBox(height: 8),
          _NumberField(
            controller: _yardCtrl,
            label: '距离（码）',
            onChanged: (_) { setState(() {}); _save(); },
          ),
          if (yard > 0)
            _ResultLine('= ${_fmt(yard * 0.9144, 2)} 米'),
          const SizedBox(height: 20),
          const Text('枪口动能',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _NumberField(
            controller: _bulletCtrl,
            label: metric ? '弹头重（克）' : '弹头重（格令）',
            onChanged: (_) { setState(() {}); _save(); },
          ),
          const SizedBox(height: 8),
          _NumberField(
            controller: _velocityCtrl,
            label: metric ? '初速（米/秒）' : '初速（英尺/秒）',
            onChanged: (_) { setState(() {}); _save(); },
          ),
          const SizedBox(height: 8),
          if (bulletGr > 0 && velocityFps > 0)
            _ResultLine(
                '枪口动能：${_fmt(energyJ, 1)} 焦耳（${_fmt(energyFtLb, 1)} 英尺·磅）')
          else
            const Text('填入弹头重与初速后出结果',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 20),
          const Text('后坐力（自由后坐能量）',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _NumberField(
            controller: _powderCtrl,
            label: metric ? '装药量（克）' : '装药量（格令）',
            onChanged: (_) { setState(() {}); _save(); },
          ),
          const SizedBox(height: 8),
          _NumberField(
            controller: _gunWeightCtrl,
            label: metric ? '枪重（千克）' : '枪重（磅）',
            onChanged: (_) { setState(() {}); _save(); },
          ),
          const SizedBox(height: 8),
          if (gunKg > 0 && velocityFps > 0)
            _ResultLine(
                '后坐能量：${_fmt(recoilJ, 1)} 焦耳（${_fmt(recoilFtLb, 1)} 英尺·磅），后坐速度 ${_fmt(recoilV, 2)} 米/秒')
          else
            const Text('填入初速与枪重后出结果',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 8),
          const Text('火药燃气速度按 1.75 倍初速估算，结果为参考值。',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
          Text('动能与后坐力的输入单位跟随工具页单位制（当前：${metric ? '公制' : '英制'}）。',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
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
