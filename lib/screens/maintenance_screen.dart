import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/app_top_bar.dart';

/// 保养清洁换件记录：工具向，不用登录，纯本机记录。
/// 经 gunsmap/prefs 存本机（key maintenance_log_v1），重启不丢。
/// 每条记枪名、日期、类型（清洁 / 换件 / 其他）、内容与当时已打发数；
/// 不教拆解、不教改装、不涉及任何制造与交易内容。
class MaintenanceRecord {
  String gunName;
  String date;
  String type;
  String detail;
  int roundsAt;
  MaintenanceRecord(
      {required this.gunName,
      required this.date,
      required this.type,
      required this.detail,
      this.roundsAt = 0});

  Map<String, dynamic> toJson() => {
        'gunName': gunName,
        'date': date,
        'type': type,
        'detail': detail,
        'roundsAt': roundsAt,
      };

  factory MaintenanceRecord.fromJson(Map<String, dynamic> j) =>
      MaintenanceRecord(
        gunName: j['gunName'] as String? ?? '',
        date: j['date'] as String? ?? '',
        type: j['type'] as String? ?? '清洁',
        detail: j['detail'] as String? ?? '',
        roundsAt: (j['roundsAt'] as num?)?.toInt() ?? 0,
      );
}

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  static const _prefsChannel = MethodChannel('gunsmap/prefs');
  static const _prefsKey = 'maintenance_log_v1';
  final _records = <MaintenanceRecord>[];
  final _gunCtrl = TextEditingController();
  final _detailCtrl = TextEditingController();
  final _roundsCtrl = TextEditingController();
  String _type = '清洁';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _gunCtrl.dispose();
    _detailCtrl.dispose();
    _roundsCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final raw = await _prefsChannel
          .invokeMethod<String>('getString', {'key': _prefsKey})
          .timeout(const Duration(seconds: 2));
      if (raw == null || raw.isEmpty || !mounted) return;
      final list = (jsonDecode(raw) as List)
          .map((e) => MaintenanceRecord.fromJson(e as Map<String, dynamic>))
          .toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      setState(() {
        _records
          ..clear()
          ..addAll(list);
      });
    } catch (_) {}
  }

  void _save() {
    try {
      _prefsChannel.invokeMethod('setString', {
        'key': _prefsKey,
        'value': jsonEncode(_records.map((e) => e.toJson()).toList()),
      });
    } catch (_) {}
  }

  String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  void _add() {
    final gun = _gunCtrl.text.trim();
    final detail = _detailCtrl.text.trim();
    if (gun.isEmpty || detail.isEmpty) return;
    final rounds = int.tryParse(_roundsCtrl.text.trim()) ?? 0;
    setState(() {
      _records.insert(
          0,
          MaintenanceRecord(
              gunName: gun,
              date: _today(),
              type: _type,
              detail: detail,
              roundsAt: rounds < 0 ? 0 : rounds));
      _gunCtrl.clear();
      _detailCtrl.clear();
      _roundsCtrl.clear();
    });
    _save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SubPageAppBar(title: '保养记录'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('只记你做过的清洁与换件，不教拆解、不教改装；数据只存本机。',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 16),
          const Text('新增记录',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
              controller: _gunCtrl,
              decoration: const InputDecoration(labelText: '枪名')),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('类型：'),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _type,
                items: const [
                  DropdownMenuItem(value: '清洁', child: Text('清洁')),
                  DropdownMenuItem(value: '换件', child: Text('换件')),
                  DropdownMenuItem(value: '其他', child: Text('其他')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _type = v);
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
              controller: _detailCtrl,
              decoration: const InputDecoration(
                  labelText: '内容，如 擦拭枪膛、更换复进簧')),
          const SizedBox(height: 8),
          TextField(
              controller: _roundsCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: '当时已打发数（可选，不填记 0）')),
          const SizedBox(height: 12),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE86A1C)),
            onPressed: _add,
            child:
                const Text('记一条', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(height: 20),
          if (_records.isEmpty)
            const Text('还没有保养记录，在上面填枪名和内容即可记一条。',
                style: TextStyle(color: Colors.grey))
          else
            ..._records.map((r) => Card(
                  child: ListTile(
                    title: Text('${r.gunName} · ${r.type}'),
                    subtitle: Text(
                        '${r.date}${r.roundsAt > 0 ? ' · 已打 ${r.roundsAt} 发' : ''}\n${r.detail}'),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () {
                        setState(() => _records.remove(r));
                        _save();
                      },
                    ),
                  ),
                )),
        ],
      ),
    );
  }
}
