import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/app_top_bar.dart';

/// 弹药库存：工具向，不用登录，纯本机记录。
/// 经 gunsmap/prefs 存本机（key ammo_inventory_v1），重启不丢。
/// 只记你手头的弹药现存发数，不提供价格、不卖弹药、不做任何交易。
class AmmoItem {
  String caliber;
  String name;
  int quantity;
  String note;
  AmmoItem(
      {required this.caliber,
      required this.name,
      required this.quantity,
      this.note = ''});

  Map<String, dynamic> toJson() => {
        'caliber': caliber,
        'name': name,
        'quantity': quantity,
        'note': note,
      };

  factory AmmoItem.fromJson(Map<String, dynamic> j) => AmmoItem(
        caliber: j['caliber'] as String? ?? '',
        name: j['name'] as String? ?? '',
        quantity: (j['quantity'] as num?)?.toInt() ?? 0,
        note: j['note'] as String? ?? '',
      );
}

class AmmoInventoryScreen extends StatefulWidget {
  const AmmoInventoryScreen({super.key});

  @override
  State<AmmoInventoryScreen> createState() => _AmmoInventoryScreenState();
}

class _AmmoInventoryScreenState extends State<AmmoInventoryScreen> {
  static const _prefsChannel = MethodChannel('gunsmap/prefs');
  static const _prefsKey = 'ammo_inventory_v1';
  final _items = <AmmoItem>[];
  final _caliberCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _caliberCtrl.dispose();
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final raw = await _prefsChannel
          .invokeMethod<String>('getString', {'key': _prefsKey})
          .timeout(const Duration(seconds: 2));
      if (raw == null || raw.isEmpty || !mounted) return;
      final list = (jsonDecode(raw) as List)
          .map((e) => AmmoItem.fromJson(e as Map<String, dynamic>))
          .toList();
      setState(() {
        _items
          ..clear()
          ..addAll(list);
      });
    } catch (_) {}
  }

  void _save() {
    try {
      _prefsChannel.invokeMethod('setString', {
        'key': _prefsKey,
        'value': jsonEncode(_items.map((e) => e.toJson()).toList()),
      });
    } catch (_) {}
  }

  void _add() {
    final caliber = _caliberCtrl.text.trim();
    final name = _nameCtrl.text.trim();
    final qty = int.tryParse(_qtyCtrl.text.trim()) ?? 0;
    if (caliber.isEmpty || name.isEmpty) return;
    setState(() {
      _items.add(AmmoItem(
          caliber: caliber,
          name: name,
          quantity: qty < 0 ? 0 : qty,
          note: _noteCtrl.text.trim()));
      _caliberCtrl.clear();
      _nameCtrl.clear();
      _qtyCtrl.clear();
      _noteCtrl.clear();
    });
    _save();
  }

  void _bump(AmmoItem item, int delta) {
    setState(() {
      item.quantity = (item.quantity + delta).clamp(0, 100000000);
    });
    _save();
  }

  @override
  Widget build(BuildContext context) {
    final total = _items.fold<int>(0, (s, e) => s + e.quantity);
    return Scaffold(
      appBar: const SubPageAppBar(title: '弹药库存'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('只记你手头的现存发数，不提供价格、不做交易；数据只存本机。',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 12),
          Text('现存合计：$total 发（${_items.length} 种）',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE86A1C),
                  fontSize: 15)),
          const SizedBox(height: 16),
          const Text('新增弹药',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
              controller: _caliberCtrl,
              decoration: const InputDecoration(labelText: '口径，如 9×19mm')),
          const SizedBox(height: 8),
          TextField(
              controller: _nameCtrl,
              decoration:
                  const InputDecoration(labelText: '弹药名称，如 124gr 全金属被甲')),
          const SizedBox(height: 8),
          TextField(
              controller: _qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '现存发数')),
          const SizedBox(height: 8),
          TextField(
              controller: _noteCtrl,
              decoration: const InputDecoration(labelText: '备注（可选）')),
          const SizedBox(height: 12),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE86A1C)),
            onPressed: _add,
            child: const Text('加入库存',
                style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(height: 20),
          if (_items.isEmpty)
            const Text('还没有库存记录，在上面填口径和弹药名称即可加入。',
                style: TextStyle(color: Colors.grey))
          else
            ..._items.map((item) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text('${item.name} · ${item.caliber}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () {
                                setState(() => _items.remove(item));
                                _save();
                              },
                            ),
                          ],
                        ),
                        if (item.note.isNotEmpty)
                          Text(item.note,
                              style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text('现存 ${item.quantity} 发',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFE86A1C))),
                            const SizedBox(width: 12),
                            OutlinedButton(
                                onPressed: () => _bump(item, -10),
                                child: const Text('-10')),
                            OutlinedButton(
                                onPressed: () => _bump(item, 10),
                                child: const Text('+10')),
                            OutlinedButton(
                                onPressed: () => _bump(item, 50),
                                child: const Text('+50')),
                          ],
                        ),
                      ],
                    ),
                  ),
                )),
        ],
      ),
    );
  }
}
