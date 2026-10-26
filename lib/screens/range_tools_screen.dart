import 'package:flutter/material.dart';
import '../widgets/app_top_bar.dart';

/// 靶场换算：只算你输入的数，不画弹道、不给装药建议。
/// 公式（公开常用值）：
/// - 1 MOA 在 100 码 = 1.047 英寸；在 100 米 ≈ 2.909 厘米；
/// - 1 密位在 100 米 = 10 厘米；
/// - 常见瞄具每格：1/4 MOA、1/2 MOA、1 MOA、0.1 密位。
/// 调节方向以瞄具说明书为准，本页只算格数。
class RangeToolsScreen extends StatefulWidget {
  const RangeToolsScreen({super.key});

  @override
  State<RangeToolsScreen> createState() => _RangeToolsScreenState();
}

class _RangeToolsScreenState extends State<RangeToolsScreen> {
  final _groupCtrl = TextEditingController();
  final _distCtrl = TextEditingController(text: '100');
  final _moaCtrl = TextEditingController();
  final _hDevCtrl = TextEditingController();
  final _vDevCtrl = TextEditingController();
  String _clickUnit = '1/4 MOA';

  @override
  void dispose() {
    _groupCtrl.dispose();
    _distCtrl.dispose();
    _moaCtrl.dispose();
    _hDevCtrl.dispose();
    _vDevCtrl.dispose();
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
    final groupCm = double.tryParse(_groupCtrl.text) ?? 0;
    final distM = double.tryParse(_distCtrl.text) ?? 0;
    final moa = double.tryParse(_moaCtrl.text) ?? 0;
    final hDev = double.tryParse(_hDevCtrl.text) ?? 0;
    final vDev = double.tryParse(_vDevCtrl.text) ?? 0;

    // 1 MOA 在 dist 米处 ≈ dist * 0.02909 厘米；1 密位 = dist * 0.1 厘米。
    final moaValue = distM > 0 ? groupCm / (distM * 0.02909) : 0.0;
    final mradValue = distM > 0 ? groupCm / (distM * 0.1) : 0.0;
    final moaGroupCm = distM > 0 ? moa * distM * 0.02909 : 0.0;

    double perClickMoa;
    double perClickMrad;
    if (_clickUnit == '1/4 MOA') {
      perClickMoa = 0.25;
      perClickMrad = 0;
    } else if (_clickUnit == '1/2 MOA') {
      perClickMoa = 0.5;
      perClickMrad = 0;
    } else if (_clickUnit == '1 MOA') {
      perClickMoa = 1.0;
      perClickMrad = 0;
    } else {
      perClickMoa = 0;
      perClickMrad = 0.1;
    }
    final hClicks = distM > 0
        ? (perClickMoa > 0
            ? (hDev / (distM * 0.02909)) / perClickMoa
            : (hDev / (distM * 0.1)) / perClickMrad)
        : 0.0;
    final vClicks = distM > 0
        ? (perClickMoa > 0
            ? (vDev / (distM * 0.02909)) / perClickMoa
            : (vDev / (distM * 0.1)) / perClickMrad)
        : 0.0;

    return Scaffold(
      appBar: const SubPageAppBar(title: '靶场换算'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('只算你输入的数，不画弹道、不给装药建议；调节方向以瞄具说明书为准。',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 16),
          const Text('散布换算',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _NumberField(
              controller: _groupCtrl,
              label: '散布（厘米，取最远两发中心距）',
              onChanged: (_) => setState(() {})),
          const SizedBox(height: 8),
          _NumberField(
              controller: _distCtrl,
              label: '距离（米）',
              onChanged: (_) => setState(() {})),
          if (groupCm > 0 && distM > 0) ...[
            _ResultLine(
                '散布 = ${_fmt(moaValue)} MOA（${_fmt(mradValue)} 密位）'),
            Text('1 MOA 在该距离 ≈ ${_fmt(distM * 0.02909)} 厘米；1 密位 ≈ ${_fmt(distM * 0.1)} 厘米。',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
          const SizedBox(height: 20),
          const Text('MOA 换算成散布',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _NumberField(
              controller: _moaCtrl,
              label: 'MOA 值',
              onChanged: (_) => setState(() {})),
          if (moa > 0 && distM > 0)
            _ResultLine(
                '${_fmt(moa)} MOA 在 ${_fmt(distM)} 米处 ≈ ${_fmt(moaGroupCm)} 厘米'),
          const SizedBox(height: 20),
          const Text('瞄具调节格数',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('每格调节量：'),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _clickUnit,
                items: const [
                  DropdownMenuItem(value: '1/4 MOA', child: Text('1/4 MOA')),
                  DropdownMenuItem(value: '1/2 MOA', child: Text('1/2 MOA')),
                  DropdownMenuItem(value: '1 MOA', child: Text('1 MOA')),
                  DropdownMenuItem(value: '0.1 密位', child: Text('0.1 密位')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _clickUnit = v);
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          _NumberField(
              controller: _hDevCtrl,
              label: '水平偏差（厘米，绝对值）',
              onChanged: (_) => setState(() {})),
          const SizedBox(height: 8),
          _NumberField(
              controller: _vDevCtrl,
              label: '垂直偏差（厘米，绝对值）',
              onChanged: (_) => setState(() {})),
          if ((hDev > 0 || vDev > 0) && distM > 0)
            _ResultLine(
                '水平约 ${_fmt(hClicks, 1)} 格，垂直约 ${_fmt(vClicks, 1)} 格（$_clickUnit/格，四舍五入到整格后以实测为准）'),
          const SizedBox(height: 8),
          const Text('本页距离统一用米；靶场记录里的散布和距离可以直接拿来算。',
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
