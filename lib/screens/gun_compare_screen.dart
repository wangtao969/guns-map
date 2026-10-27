import 'package:flutter/material.dart';
import '../data.dart';
import '../english_terms.dart';
import '../models.dart';
import '../widgets/app_top_bar.dart';
import 'gun_picker_dialog.dart';

/// 两枪参数对比：只对照图鉴已收录的纸面参数，不做弹道推算。
/// 初速与弹道系数未收录，所以不画弹道曲线——画了就是现编。
/// 入口在枪械详情页：当前这把已是第一把，只需再选第二把；
/// 工具页不再放这个入口，对比是对图鉴数据的查看，不是算具。
/// 不同项高亮显示，可只看不同项；不算胜负，字符串写法不统一
/// （如重量单位混写）时硬算谁更轻可能算错。
class GunCompareScreen extends StatefulWidget {
  final Gun? initialGun;
  const GunCompareScreen({super.key, this.initialGun});

  @override
  State<GunCompareScreen> createState() => _GunCompareScreenState();
}

class _GunCompareScreenState extends State<GunCompareScreen> {
  Gun? _a;
  Gun? _b;
  bool _diffOnly = false;

  @override
  void initState() {
    super.initState();
    _a = widget.initialGun;
  }

  Future<void> _pick(bool first) async {
    final gun = await showGunPickerDialog(context);
    if (gun == null) return;
    setState(() {
      if (first) {
        _a = gun;
      } else {
        _b = gun;
      }
    });
  }

  String _caliberSize(String caliber) {
    for (final c in caliberInfos) {
      if (c.caliber == caliber) {
        return 'Bullet ${c.bulletDiameter} · Case ${c.caseLength}';
      }
    }
    return '未收录';
  }

  String _join(List<String> items) =>
      items.isEmpty ? '—' : items.join(', ');

  @override
  Widget build(BuildContext context) {
    final rows = <_RowData>[];
    if (_a != null && _b != null) {
      void add(String label, String a, String b) =>
          rows.add(_RowData(label, a, b));
      add('Manufacturer', vendorDisplay(_a!.vendor), vendorDisplay(_b!.vendor));
      add('Category', categoryDisplay(_a!.category),
          categoryDisplay(_b!.category));
      add('Caliber', _a!.caliber, _b!.caliber);
      add('Caliber Dimensions', _caliberSize(_a!.caliber),
          _caliberSize(_b!.caliber));
      add('Action', actionDisplay(_a!.action), actionDisplay(_b!.action));
      add('Barrel', _a!.barrel, _b!.barrel);
      add('Overall Length', _a!.length, _b!.length);
      add('Weight', _a!.weight, _b!.weight);
      add('Capacity', _a!.capacity, _b!.capacity);
      add('Compatible Ammo', _join(_a!.ammo), _join(_b!.ammo));
      add('Compatible Accessories',
          _a!.accessories.map(accessoryDisplay).join(', '),
          _b!.accessories.map(accessoryDisplay).join(', '));
      add('Model', _a!.nameEn ?? '未确认', _b!.nameEn ?? '未确认');
      add('Origin', originDisplay(_a!.origin), originDisplay(_b!.origin));
      add('Year', _a!.year, _b!.year);
      add('Reference Price', _a!.price ?? '未确认', _b!.price ?? '未确认');
    }
    final diffRows = rows.where((r) => r.diff).toList();
    final shown = _diffOnly ? diffRows : rows;
    return Scaffold(
      appBar: const SubPageAppBar(title: '两枪参数对比'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('只对照纸面参数；初速与弹道系数未收录，不画弹道曲线。',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _pick(true),
                  child: Text(
                      _a == null ? '选第一把枪' : gunDisplayName(_a!),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.swap_horiz, size: 20),
                tooltip: '交换两把',
                onPressed: _a != null && _b != null
                    ? () => setState(() {
                          final t = _a;
                          _a = _b;
                          _b = t;
                        })
                    : null,
              ),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _pick(false),
                  child: Text(
                      _b == null ? '选第二把枪' : gunDisplayName(_b!),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_a != null && _b != null) ...[
            Text(
                '${rows.length} 项里 ${diffRows.length} 项不同${diffRows.isNotEmpty ? '：${diffRows.map((r) => r.label).join(', ')}' : ''}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: FilterChip(
                label: const Text('只看不同项'),
                selected: _diffOnly,
                onSelected: (v) => setState(() => _diffOnly = v),
              ),
            ),
            const SizedBox(height: 8),
            if (shown.isEmpty)
              const Text('两把枪这些参数完全相同。',
                  style: TextStyle(color: Colors.grey))
            else
              ...shown.map((r) => _Row(r)),
            const SizedBox(height: 12),
            if (_a!.description.isNotEmpty)
              ExpansionTile(
                title: Text(gunDisplayName(_a!)),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Text(_a!.description),
                  ),
                ],
              ),
            if (_b!.description.isNotEmpty)
              ExpansionTile(
                title: Text(gunDisplayName(_b!)),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Text(_b!.description),
                  ),
                ],
              ),
          ] else
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 32),
                child: Text('两把枪都选好后，这里出现对照表'),
              ),
            ),
        ],
      ),
    );
  }
}

class _RowData {
  final String label;
  final String a;
  final String b;
  bool get diff => a != b;
  _RowData(this.label, this.a, this.b);
}

class _Row extends StatelessWidget {
  final _RowData row;
  const _Row(this.row);

  @override
  Widget build(BuildContext context) {
    final diff = row.diff;
    final valueStyle = TextStyle(
        fontSize: 14,
        fontWeight: diff ? FontWeight.bold : FontWeight.normal,
        color: diff ? const Color(0xFFE86A1C) : null);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(row.label,
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ),
          Expanded(child: Text(row.a, style: valueStyle)),
          const SizedBox(width: 8),
          Expanded(child: Text(row.b, style: valueStyle)),
        ],
      ),
    );
  }
}
