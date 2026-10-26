import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/app_top_bar.dart';

/// 复装成本：只算你输入的价格，不提供任何厂商报价、不给装药建议。
/// 弹壳成本按单价除以复用次数摊销；复用次数填 1 表示一次性弹壳。
/// 装药量只用来算火药钱，不推算、不推荐装药量，装药以手册原文为准。
class ReloadCostScreen extends StatefulWidget {
  const ReloadCostScreen({super.key});

  @override
  State<ReloadCostScreen> createState() => _ReloadCostScreenState();
}

class _ReloadCostScreenState extends State<ReloadCostScreen> {
  static const _prefsChannel = MethodChannel('gunsmap/prefs');
  static const _prefsKey = 'reload_cost_inputs_v1';
  final _bulletCtrl = TextEditingController();
  final _primerCtrl = TextEditingController();
  final _powderPriceCtrl = TextEditingController();
  final _powderGrCtrl = TextEditingController();
  final _brassCtrl = TextEditingController();
  final _reuseCtrl = TextEditingController(text: '5');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final raw = await _prefsChannel
          .invokeMethod<String>('getString', {'key': _prefsKey})
          .timeout(const Duration(seconds: 2));
      if (raw == null || raw.isEmpty || !mounted) return;
      final m = jsonDecode(raw) as Map<String, dynamic>;
      setState(() {
        void set(TextEditingController c, String k) {
          final v = m[k] as String?;
          if (v != null) c.text = v;
        }
        set(_bulletCtrl, 'bullet');
        set(_primerCtrl, 'primer');
        set(_powderPriceCtrl, 'powderPrice');
        set(_powderGrCtrl, 'powderGr');
        set(_brassCtrl, 'brass');
        set(_reuseCtrl, 'reuse');
      });
    } catch (_) {}
  }

  void _save() {
    try {
      _prefsChannel.invokeMethod('setString', {
        'key': _prefsKey,
        'value': jsonEncode({
          'bullet': _bulletCtrl.text,
          'primer': _primerCtrl.text,
          'powderPrice': _powderPriceCtrl.text,
          'powderGr': _powderGrCtrl.text,
          'brass': _brassCtrl.text,
          'reuse': _reuseCtrl.text,
        }),
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _bulletCtrl.dispose();
    _primerCtrl.dispose();
    _powderPriceCtrl.dispose();
    _powderGrCtrl.dispose();
    _brassCtrl.dispose();
    _reuseCtrl.dispose();
    super.dispose();
  }

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
    const grToG = 0.06479891;
    final bullet = double.tryParse(_bulletCtrl.text) ?? 0;
    final primer = double.tryParse(_primerCtrl.text) ?? 0;
    final powderPricePerG = double.tryParse(_powderPriceCtrl.text) ?? 0;
    final powderGr = double.tryParse(_powderGrCtrl.text) ?? 0;
    final brass = double.tryParse(_brassCtrl.text) ?? 0;
    final reuse = double.tryParse(_reuseCtrl.text) ?? 0;
    final powderCost = powderPricePerG * powderGr * grToG;
    final brassCost = reuse > 0 ? brass / reuse : brass;
    final perRound = bullet + primer + powderCost + brassCost;

    return Scaffold(
      appBar: const SubPageAppBar(title: '复装成本'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('只算你输入的价格，不提供厂商报价、不给装药建议；装药以手册原文为准。',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 16),
          _NumberField(
              controller: _bulletCtrl,
              label: '弹头单价（元/颗）',
              onChanged: (_) { setState(() {}); _save(); }),
          const SizedBox(height: 8),
          _NumberField(
              controller: _primerCtrl,
              label: '底火单价（元/颗）',
              onChanged: (_) { setState(() {}); _save(); }),
          const SizedBox(height: 8),
          _NumberField(
              controller: _powderPriceCtrl,
              label: '火药单价（元/克）',
              onChanged: (_) { setState(() {}); _save(); }),
          const SizedBox(height: 8),
          _NumberField(
              controller: _powderGrCtrl,
              label: '装药量（格令，仅用来算火药钱）',
              onChanged: (_) { setState(() {}); _save(); }),
          const SizedBox(height: 8),
          _NumberField(
              controller: _brassCtrl,
              label: '弹壳单价（元/颗）',
              onChanged: (_) { setState(() {}); _save(); }),
          const SizedBox(height: 8),
          _NumberField(
              controller: _reuseCtrl,
              label: '弹壳复用次数（填 1 表示一次性）',
              onChanged: (_) { setState(() {}); _save(); }),
          const SizedBox(height: 16),
          _ResultLine('每发成本：${_fmt(perRound)} 元'),
          const SizedBox(height: 4),
          Text('其中：弹头 ${_fmt(bullet)} + 底火 ${_fmt(primer)} + 火药 ${_fmt(powderCost)} + 弹壳摊销 ${_fmt(brassCost)}',
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 12),
          _ResultLine('50 发：${_fmt(perRound * 50)} 元'),
          _ResultLine('100 发：${_fmt(perRound * 100)} 元'),
          _ResultLine('1000 发：${_fmt(perRound * 1000)} 元'),
          const SizedBox(height: 8),
          const Text('货币单位跟你输入的单价一致；换一批组件价格，改单价重算即可。',
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
  const _NumberField(
      {required this.controller,
      required this.label,
      required this.onChanged});

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
