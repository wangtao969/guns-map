import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data.dart';
import '../widgets/app_top_bar.dart';
import '../i18n.dart';

/// 复装记录：按 SOP 一步步打勾执行，并记下每次复装的实际参数。
/// 记录经 gunsmap/prefs 存本机（key reload_log_v1），重启不丢；
/// 字段按 Hornady / Lyman 手册的记录要求：弹头、火药与批号、底火与批号、
/// 弹壳品牌与使用次数、装药量、COL、试射枪械、初速、散布、天气与备注。
class ReloadLogEntry {
  final String date;
  final String caliber;
  final String bullet;
  final String powder;
  final String charge;
  final String col;
  final String rounds;
  final String note;
  final String primer;
  final String caseBrand;
  final String caseTimes;
  final String velocity;
  final String group;
  final String firearm;
  final String lot;
  final String weather;
  ReloadLogEntry({
    required this.date,
    required this.caliber,
    required this.bullet,
    required this.powder,
    required this.charge,
    required this.col,
    required this.rounds,
    required this.note,
    this.primer = '',
    this.caseBrand = '',
    this.caseTimes = '',
    this.velocity = '',
    this.group = '',
    this.firearm = '',
    this.lot = '',
    this.weather = '',
  });

  Map<String, dynamic> toJson() => {
        'date': date,
        'caliber': caliber,
        'bullet': bullet,
        'powder': powder,
        'charge': charge,
        'col': col,
        'rounds': rounds,
        'note': note,
        'primer': primer,
        'caseBrand': caseBrand,
        'caseTimes': caseTimes,
        'velocity': velocity,
        'group': group,
        'firearm': firearm,
        'lot': lot,
        'weather': weather,
      };

  factory ReloadLogEntry.fromJson(Map<String, dynamic> j) => ReloadLogEntry(
        date: j['date'] as String? ?? '',
        caliber: j['caliber'] as String? ?? '',
        bullet: j['bullet'] as String? ?? '',
        powder: j['powder'] as String? ?? '',
        charge: j['charge'] as String? ?? '',
        col: j['col'] as String? ?? '',
        rounds: j['rounds'] as String? ?? '',
        note: j['note'] as String? ?? '',
        primer: j['primer'] as String? ?? '',
        caseBrand: j['caseBrand'] as String? ?? '',
        caseTimes: j['caseTimes'] as String? ?? '',
        velocity: j['velocity'] as String? ?? '',
        group: j['group'] as String? ?? '',
        firearm: j['firearm'] as String? ?? '',
        lot: j['lot'] as String? ?? '',
        weather: j['weather'] as String? ?? '',
      );
}

class ReloadLogScreen extends StatefulWidget {
  const ReloadLogScreen({super.key});

  @override
  State<ReloadLogScreen> createState() => _ReloadLogScreenState();
}

class _ReloadLogScreenState extends State<ReloadLogScreen> {
  late List<bool> _done;
  final _logs = <ReloadLogEntry>[];
  String? _caliber;
  final _bulletCtrl = TextEditingController();
  final _powderCtrl = TextEditingController();
  final _chargeCtrl = TextEditingController();
  final _colCtrl = TextEditingController();
  final _roundsCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _primerCtrl = TextEditingController();
  final _caseBrandCtrl = TextEditingController();
  final _caseTimesCtrl = TextEditingController();
  final _velocityCtrl = TextEditingController();
  final _groupCtrl = TextEditingController();
  final _firearmCtrl = TextEditingController();
  final _lotCtrl = TextEditingController();
  final _weatherCtrl = TextEditingController();
  static const _prefsChannel = MethodChannel('gunsmap/prefs');
  static const _prefsKey = 'reload_log_v1';

  @override
  void initState() {
    super.initState();
    _done = List<bool>.filled(reloadSopSteps.length, false);
    _load();
  }

  Future<void> _load() async {
    try {
      final raw = await _prefsChannel
          .invokeMethod<String>('getString', {'key': _prefsKey}).timeout(
              const Duration(seconds: 2));
      if (raw == null || raw.isEmpty || !mounted) return;
      final list = (jsonDecode(raw) as List)
          .map((e) => ReloadLogEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      setState(() {
        _logs
          ..clear()
          ..addAll(list);
      });
    } catch (_) {}
  }

  void _save() {
    try {
      _prefsChannel.invokeMethod('setString', {
        'key': _prefsKey,
        'value': jsonEncode(_logs.map((e) => e.toJson()).toList()),
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _bulletCtrl.dispose();
    _powderCtrl.dispose();
    _chargeCtrl.dispose();
    _colCtrl.dispose();
    _roundsCtrl.dispose();
    _noteCtrl.dispose();
    _primerCtrl.dispose();
    _caseBrandCtrl.dispose();
    _caseTimesCtrl.dispose();
    _velocityCtrl.dispose();
    _groupCtrl.dispose();
    _firearmCtrl.dispose();
    _lotCtrl.dispose();
    _weatherCtrl.dispose();
    super.dispose();
  }

  String _today() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final grey = dark ? const Color(0xFF8A8578) : const Color(0xFF9A917F);
    final bronze = dark ? const Color(0xFFC9A86A) : const Color(0xFF6B5B3E);
    final doneCount = _done.where((d) => d).length;
    final allDone = doneCount == reloadSopSteps.length;
    return Scaffold(
      appBar: SubPageAppBar(title: '复装记录 · SOP 执行'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('复装记录 · SOP 执行',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('按步骤打勾，全部完成才能记一条；记录保存在本机，重启不丢。',
              style: TextStyle(color: grey, fontSize: 12)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: doneCount / reloadSopSteps.length,
                  backgroundColor: grey.withValues(alpha: 0.25),
                  color: bronze,
                ),
              ),
              const SizedBox(width: 8),
              Text('$doneCount/${reloadSopSteps.length}'),
            ],
          ),
          const SizedBox(height: 4),
          if (allDone)
            const Text('✓ SOP 全部完成，可以记录本次复装',
                style: TextStyle(
                    color: Colors.green, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...reloadSopSteps.asMap().entries.map((e) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: CheckboxListTile(
                  value: _done[e.key],
                  onChanged: (v) =>
                      setState(() => _done[e.key] = v ?? false),
                  title: Text(e.value),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              )),
          TextButton(
            onPressed: () =>
                setState(() => _done = List<bool>.filled(reloadSopSteps.length, false)),
            child: const Text('重置 SOP 打勾'),
          ),
          const SizedBox(height: 16),
          Text(tr('safety_rules'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            color: const Color(0xFF4A1500),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: reloadSafetyRules
                    .map((r) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text('· $r',
                              style:
                                  const TextStyle(color: Colors.amber)),
                        ))
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(tr('log_new'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _caliber,
            decoration: const InputDecoration(
              labelText: '口径',
              border: OutlineInputBorder(),
            ),
            items: reloadCalibers
                .map((c) => DropdownMenuItem(
                    value: c.caliber, child: Text(c.caliber)))
                .toList(),
            onChanged: (v) => setState(() => _caliber = v),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _bulletCtrl,
            decoration: const InputDecoration(
              labelText: '弹头（品牌/重量/型号）',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _powderCtrl,
            decoration: const InputDecoration(
              labelText: '火药（品牌/型号）',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chargeCtrl,
                  decoration: const InputDecoration(
                    labelText: '装药量（gr）',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _colCtrl,
                  decoration: const InputDecoration(
                    labelText: '弹长 COL（″）',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _roundsCtrl,
            decoration: const InputDecoration(
              labelText: '数量（发）',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _primerCtrl,
                  decoration: const InputDecoration(
                    labelText: '底火（品牌/型号）',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _lotCtrl,
                  decoration: const InputDecoration(
                    labelText: '火药/底火批号',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _caseBrandCtrl,
                  decoration: const InputDecoration(
                    labelText: '弹壳品牌',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _caseTimesCtrl,
                  decoration: const InputDecoration(
                    labelText: '弹壳使用次数',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _velocityCtrl,
                  decoration: const InputDecoration(
                    labelText: '初速（fps）',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _groupCtrl,
                  decoration: const InputDecoration(
                    labelText: '散布（100 码，″）',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _firearmCtrl,
                  decoration: const InputDecoration(
                    labelText: '试射枪械',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _weatherCtrl,
                  decoration: const InputDecoration(
                    labelText: '天气/温度',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _noteCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: '备注（批次、试射结果等）',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: (!allDone || _caliber == null)
                ? null
                : () {
                    setState(() {
                      _logs.insert(
                          0,
                          ReloadLogEntry(
                            date: _today(),
                            caliber: _caliber!,
                            bullet: _bulletCtrl.text.trim(),
                            powder: _powderCtrl.text.trim(),
                            charge: _chargeCtrl.text.trim(),
                            col: _colCtrl.text.trim(),
                            rounds: _roundsCtrl.text.trim(),
                            note: _noteCtrl.text.trim(),
                            primer: _primerCtrl.text.trim(),
                            caseBrand: _caseBrandCtrl.text.trim(),
                            caseTimes: _caseTimesCtrl.text.trim(),
                            velocity: _velocityCtrl.text.trim(),
                            group: _groupCtrl.text.trim(),
                            firearm: _firearmCtrl.text.trim(),
                            lot: _lotCtrl.text.trim(),
                            weather: _weatherCtrl.text.trim(),
                          ));
                      _save();
                      _bulletCtrl.clear();
                      _powderCtrl.clear();
                      _chargeCtrl.clear();
                      _colCtrl.clear();
                      _roundsCtrl.clear();
                      _noteCtrl.clear();
                      _primerCtrl.clear();
                      _caseBrandCtrl.clear();
                      _caseTimesCtrl.clear();
                      _velocityCtrl.clear();
                      _groupCtrl.clear();
                      _firearmCtrl.clear();
                      _lotCtrl.clear();
                      _weatherCtrl.clear();
                      _done = List<bool>.filled(
                          reloadSopSteps.length, false);
                    });
                  },
            child: const Text('保存这条记录'),
          ),
          if (!allDone)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('SOP 未全部打勾时不能保存记录',
                  style: TextStyle(color: grey, fontSize: 12)),
            ),
          const SizedBox(height: 16),
          Text('已记 ${_logs.length} 条',
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (_logs.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Center(
                  child: Text(tr('no_logs'), style: TextStyle(color: grey))),
            ),
          ..._logs.map((l) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text('${l.date} · ${l.caliber}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20),
                            onPressed: () {
                              setState(() => _logs.remove(l));
                              _save();
                            },
                          ),
                        ],
                      ),
                      if (l.bullet.isNotEmpty) Text('弹头：${l.bullet}'),
                      if (l.powder.isNotEmpty) Text('火药：${l.powder}'),
                      if (l.charge.isNotEmpty) Text('装药：${l.charge} gr'),
                      if (l.col.isNotEmpty) Text('弹长 COL：${l.col}″'),
                      if (l.rounds.isNotEmpty) Text('数量：${l.rounds} 发'),
                      if (l.primer.isNotEmpty) Text('底火：${l.primer}'),
                      if (l.lot.isNotEmpty) Text('批号：${l.lot}'),
                      if (l.caseBrand.isNotEmpty)
                        Text('弹壳：${l.caseBrand}${l.caseTimes.isNotEmpty ? '（第 ${l.caseTimes} 次）' : ''}'),
                      if (l.velocity.isNotEmpty) Text('初速：${l.velocity} fps'),
                      if (l.group.isNotEmpty) Text('散布：${l.group}″'),
                      if (l.firearm.isNotEmpty) Text('试射枪械：${l.firearm}'),
                      if (l.weather.isNotEmpty) Text('天气：${l.weather}'),
                      if (l.note.isNotEmpty) Text('备注：${l.note}'),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
