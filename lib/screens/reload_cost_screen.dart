import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/app_top_bar.dart';

/// 复装成本：只算你输入的价格，不提供任何厂商报价、不给装药建议。
/// 弹壳成本按单价除以复用次数摊销；复用次数填 1 表示一次性弹壳。
/// 装药量只用来算火药钱，不推算、不推荐装药量，装药以手册原文为准。
/// 价格按实际购买方式填：弹头底火填整盒价与盒内数，火药填整罐价
/// 与罐重（克，1 磅 = 453.6 克），单价自动算；货币单位跟你输入的一致。
/// 复装记录可带入装药量与批次数，算这批的总成本与每发成本。
class ReloadCostScreen extends StatefulWidget {
  final double? initialPowderGr;
  final int? initialRounds;
  final String? initialLabel;
  const ReloadCostScreen(
      {super.key,
      this.initialPowderGr,
      this.initialRounds,
      this.initialLabel});

  @override
  State<ReloadCostScreen> createState() => _ReloadCostScreenState();
}

class _ReloadCostScreenState extends State<ReloadCostScreen> {
  static const _prefsChannel = MethodChannel('gunsmap/prefs');
  static const _prefsKey = 'reload_cost_inputs_v1';
  final _bulletBoxCtrl = TextEditingController();
  final _bulletCountCtrl = TextEditingController();
  final _primerBoxCtrl = TextEditingController();
  final _primerCountCtrl = TextEditingController();
  final _powderCanCtrl = TextEditingController();
  final _powderCanGCtrl = TextEditingController();
  final _powderGrCtrl = TextEditingController();
  final _brassCtrl = TextEditingController();
  final _reuseCtrl = TextEditingController(text: '5');
  final _roundsCtrl = TextEditingController();
  final _factoryCtrl = TextEditingController();

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
      if (raw != null && raw.isNotEmpty && mounted) {
        final m = jsonDecode(raw) as Map<String, dynamic>;
        setState(() {
          void set(TextEditingController c, String k) {
            final v = m[k] as String?;
            if (v != null) c.text = v;
          }
          // 旧版存的是单价（bullet/primer/powderPrice），新版存总价与数量；
          // 旧数据按“总价 = 旧单价、数量 = 1”迁过来，单价本身不变，不编盒数。
          if (m['bulletBox'] == null && m['bullet'] != null) {
            _bulletBoxCtrl.text = m['bullet'] as String;
            _bulletCountCtrl.text = '1';
          } else {
            set(_bulletBoxCtrl, 'bulletBox');
            set(_bulletCountCtrl, 'bulletCount');
          }
          if (m['primerBox'] == null && m['primer'] != null) {
            _primerBoxCtrl.text = m['primer'] as String;
            _primerCountCtrl.text = '1';
          } else {
            set(_primerBoxCtrl, 'primerBox');
            set(_primerCountCtrl, 'primerCount');
          }
          if (m['powderCan'] == null && m['powderPrice'] != null) {
            _powderCanCtrl.text = m['powderPrice'] as String;
            _powderCanGCtrl.text = '1';
          } else {
            set(_powderCanCtrl, 'powderCan');
            set(_powderCanGCtrl, 'powderCanG');
          }
          set(_powderGrCtrl, 'powderGr');
          set(_brassCtrl, 'brass');
          set(_reuseCtrl, 'reuse');
          set(_roundsCtrl, 'rounds');
          set(_factoryCtrl, 'factory');
        });
      }
    } catch (_) {}
    if (!mounted) return;
    final p = widget.initialPowderGr;
    final r = widget.initialRounds;
    if (p == null && r == null) return;
    setState(() {
      if (p != null) _powderGrCtrl.text = _fmt(p);
      if (r != null) _roundsCtrl.text = '$r';
    });
    _save();
  }

  void _save() {
    try {
      _prefsChannel.invokeMethod('setString', {
        'key': _prefsKey,
        'value': jsonEncode({
          'bulletBox': _bulletBoxCtrl.text,
          'bulletCount': _bulletCountCtrl.text,
          'primerBox': _primerBoxCtrl.text,
          'primerCount': _primerCountCtrl.text,
          'powderCan': _powderCanCtrl.text,
          'powderCanG': _powderCanGCtrl.text,
          'powderGr': _powderGrCtrl.text,
          'brass': _brassCtrl.text,
          'reuse': _reuseCtrl.text,
          'rounds': _roundsCtrl.text,
          'factory': _factoryCtrl.text,
        }),
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _bulletBoxCtrl.dispose();
    _bulletCountCtrl.dispose();
    _primerBoxCtrl.dispose();
    _primerCountCtrl.dispose();
    _powderCanCtrl.dispose();
    _powderCanGCtrl.dispose();
    _powderGrCtrl.dispose();
    _brassCtrl.dispose();
    _reuseCtrl.dispose();
    _roundsCtrl.dispose();
    _factoryCtrl.dispose();
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
    double num(TextEditingController c) => double.tryParse(c.text) ?? 0;
    double unit(double total, double count) => count > 0 ? total / count : 0;
    final bullet = unit(num(_bulletBoxCtrl), num(_bulletCountCtrl));
    final primer = unit(num(_primerBoxCtrl), num(_primerCountCtrl));
    final powderPricePerG = unit(num(_powderCanCtrl), num(_powderCanGCtrl));
    final powderGr = num(_powderGrCtrl);
    final brass = num(_brassCtrl);
    final reuse = num(_reuseCtrl);
    final rounds = num(_roundsCtrl);
    final factory = num(_factoryCtrl);
    final powderCost = powderPricePerG * powderGr * grToG;
    final brassCost = reuse > 0 ? brass / reuse : brass;
    final perRound = bullet + primer + powderCost + brassCost;
    final batchTotal = perRound * rounds;
    final saving = factory - perRound;
    final savingPct = factory > 0 ? saving / factory * 100 : 0.0;

    Widget pair(TextEditingController total, TextEditingController count,
        String totalLabel, String countLabel) {
      return Row(
        children: [
          Expanded(
            child: _NumberField(
                controller: total,
                label: totalLabel,
                onChanged: (_) { setState(() {}); _save(); }),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _NumberField(
                controller: count,
                label: countLabel,
                onChanged: (_) { setState(() {}); _save(); }),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: const SubPageAppBar(title: '复装成本'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('只算你输入的价格，不提供厂商报价、不给装药建议；装药以手册原文为准。',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
          if (widget.initialLabel != null) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text('已从 ${widget.initialLabel} 带入装药量与批次数，价格用你填过的。',
                    style: const TextStyle(fontSize: 13)),
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Text('弹头',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          pair(_bulletBoxCtrl, _bulletCountCtrl, '整盒价', '盒内数（颗）'),
          if (num(_bulletCountCtrl) > 0)
            Text('弹头单价：${_fmt(bullet)}',
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 12),
          const Text('底火',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          pair(_primerBoxCtrl, _primerCountCtrl, '整盒价', '盒内数（颗）'),
          if (num(_primerCountCtrl) > 0)
            Text('底火单价：${_fmt(primer)}',
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 12),
          const Text('火药',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          pair(_powderCanCtrl, _powderCanGCtrl, '整罐价', '罐重（克）'),
          const Text('1 磅 = 453.6 克；8 磅桶 = 3628.8 克。',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
          if (num(_powderCanGCtrl) > 0)
            Text('火药每克：${_fmt(powderPricePerG)}',
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 8),
          _NumberField(
              controller: _powderGrCtrl,
              label: '装药量（格令，仅用来算火药钱）',
              onChanged: (_) { setState(() {}); _save(); }),
          const SizedBox(height: 12),
          const Text('弹壳',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _NumberField(
              controller: _brassCtrl,
              label: '弹壳单价',
              onChanged: (_) { setState(() {}); _save(); }),
          const SizedBox(height: 8),
          _NumberField(
              controller: _reuseCtrl,
              label: '弹壳复用次数（填 1 表示一次性）',
              onChanged: (_) { setState(() {}); _save(); }),
          const SizedBox(height: 12),
          const Text('这批与对比',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _NumberField(
              controller: _roundsCtrl,
              label: '批次数（发，算这批总成本）',
              onChanged: (_) { setState(() {}); _save(); }),
          const SizedBox(height: 8),
          _NumberField(
              controller: _factoryCtrl,
              label: '厂弹单价（自己填的对比价，不是报价）',
              onChanged: (_) { setState(() {}); _save(); }),
          const SizedBox(height: 16),
          _ResultLine('每发成本：${_fmt(perRound)}'),
          const SizedBox(height: 4),
          Text('其中：弹头 ${_fmt(bullet)} + 底火 ${_fmt(primer)} + 火药 ${_fmt(powderCost)} + 弹壳摊销 ${_fmt(brassCost)}',
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 12),
          _ResultLine('50 发：${_fmt(perRound * 50)}'),
          _ResultLine('100 发：${_fmt(perRound * 100)}'),
          _ResultLine('1000 发：${_fmt(perRound * 1000)}'),
          if (rounds > 0) ...[
            const SizedBox(height: 8),
            _ResultLine('这批 ${_fmt(rounds, 0)} 发总成本：${_fmt(batchTotal)}'),
          ],
          if (factory > 0 && perRound > 0) ...[
            const SizedBox(height: 8),
            _ResultLine(saving >= 0
                ? '比厂弹每发省 ${_fmt(saving)}（省 ${_fmt(savingPct, 1)}%）'
                : '比厂弹每发贵 ${_fmt(-saving)}'),
          ],
          const SizedBox(height: 8),
          const Text('货币单位跟你输入的价格一致；换一批组件价格，改总价重算即可。',
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
