import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../community_store.dart';
import '../models.dart';
import '../widgets/app_toast.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/glass_dialog.dart';
import 'maintenance_screen.dart';

/// 单枪射击数据本（DOPE）：归零卡 + 该枪靶场成绩趋势 + 常用弹药 +
/// 收藏柜发数与上次保养。归零记录只存本机，不用登录；成绩、收藏、
/// 保养来自本机已有数据，没有就明示、不编。
class DopeScreen extends StatefulWidget {
  final Gun gun;
  const DopeScreen({super.key, required this.gun});

  @override
  State<DopeScreen> createState() => _DopeScreenState();
}

class _ZeroRecord {
  final String gunName;
  final int distance;
  final String ammo;
  final String clicks;
  final String note;
  final String date;
  _ZeroRecord({
    required this.gunName,
    required this.distance,
    required this.ammo,
    required this.clicks,
    required this.note,
    required this.date,
  });
  Map<String, dynamic> toJson() => {
        'gunName': gunName,
        'distance': distance,
        'ammo': ammo,
        'clicks': clicks,
        'note': note,
        'date': date,
      };
  static _ZeroRecord fromJson(Map<String, dynamic> j) => _ZeroRecord(
        gunName: j['gunName'] as String? ?? '',
        distance: (j['distance'] as num? ?? 100).toInt(),
        ammo: j['ammo'] as String? ?? '',
        clicks: j['clicks'] as String? ?? '',
        note: j['note'] as String? ?? '',
        date: j['date'] as String? ?? '',
      );
}

class _DopeScreenState extends State<DopeScreen> {
  static const _prefsChannel = MethodChannel('gunsmap/prefs');
  static const _zeroKey = 'dope_zero_v1';
  var _zeros = <_ZeroRecord>[];
  var _lastMaintenance = '';
  var _maintenanceDays = -1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final raw = await _prefsChannel
          .invokeMethod<String>('getString', {'key': _zeroKey})
          .timeout(const Duration(seconds: 2));
      if (raw != null && raw.isNotEmpty && mounted) {
        setState(() {
          _zeros = (jsonDecode(raw) as List)
              .map((e) => _ZeroRecord.fromJson(e as Map<String, dynamic>))
              .where((z) => z.gunName == widget.gun.name)
              .toList();
        });
      }
    } catch (_) {}
    try {
      final raw = await _prefsChannel
          .invokeMethod<String>(
              'getString', {'key': 'maintenance_log_v1'})
          .timeout(const Duration(seconds: 2));
      if (raw != null && raw.isNotEmpty && mounted) {
        final recs = (jsonDecode(raw) as List)
            .map((e) => MaintenanceRecord.fromJson(e as Map<String, dynamic>))
            .where((r) => r.gunName == widget.gun.name)
            .toList();
        if (recs.isNotEmpty) {
          recs.sort((a, b) => b.date.compareTo(a.date));
          final latest = DateTime.tryParse(recs.first.date);
          setState(() {
            _lastMaintenance = recs.first.date;
            _maintenanceDays = latest == null
                ? -1
                : DateTime.now().difference(latest).inDays;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _saveZeros() async {
    try {
      final raw = await _prefsChannel
          .invokeMethod<String>('getString', {'key': _zeroKey})
          .timeout(const Duration(seconds: 2));
      var all = <_ZeroRecord>[];
      if (raw != null && raw.isNotEmpty) {
        all = (jsonDecode(raw) as List)
            .map((e) => _ZeroRecord.fromJson(e as Map<String, dynamic>))
            .where((z) => z.gunName != widget.gun.name)
            .toList();
      }
      all.addAll(_zeros);
      await _prefsChannel.invokeMethod(
          'setString', {'key': _zeroKey, 'value': jsonEncode(all)});
    } catch (_) {}
  }

  Future<void> _addZero() async {
    final distCtrl = TextEditingController(text: '100');
    final ammoCtrl = TextEditingController();
    final clicksCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => GlassDialog(
        title: '记一张归零卡',
        subtitle: widget.gun.name,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: distCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '归零距离（米）',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12))),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ammoCtrl,
              decoration: const InputDecoration(
                labelText: '用弹（可选）',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12))),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: clicksCtrl,
              decoration: const InputDecoration(
                labelText: '瞄具调节（可选，如：右 4 格、上 2 格）',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12))),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(
                labelText: '备注（可选）',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12))),
              ),
            ),
          ],
        ),
        actions: [
          glassCancelButton(ctx, '取消'),
          glassPrimaryButton(ctx, '保存', popTrue: true),
        ],
      ),
    );
    if (saved == true && mounted) {
      final now = DateTime.now();
      final date =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      setState(() {
        _zeros.insert(
            0,
            _ZeroRecord(
              gunName: widget.gun.name,
              distance: int.tryParse(distCtrl.text) ?? 100,
              ammo: ammoCtrl.text.trim(),
              clicks: clicksCtrl.text.trim(),
              note: noteCtrl.text.trim(),
              date: date,
            ));
      });
      await _saveZeros();
      showAppToast(context, '归零卡已记下');
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final grey = dark ? const Color(0xFF8A8578) : const Color(0xFF9A917F);
    final gun = widget.gun;
    final account = communityStore.current;
    final scores = (account?.rangeScores ?? [])
        .where((s) => s.gunName == gun.name)
        .toList();
    // 常用弹药：按该枪成绩里的弹药名计频，前 5。
    final ammoCount = <String, int>{};
    for (final s in scores) {
      if (s.ammo.trim().isNotEmpty) {
        ammoCount[s.ammo.trim()] = (ammoCount[s.ammo.trim()] ?? 0) + 1;
      }
    }
    final topAmmo = ammoCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    CollectionItem? collection;
    for (final c in account?.collection ?? []) {
      if (c.gunName == gun.name && c.kind == 'gun') collection = c;
    }
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: SubPageAppBar(title: '${gun.name} · 射击数据本'),
      body: SafeArea(
        top: true,
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8 + kToolbarHeight, 16, 110),
          children: [
            Text(gun.vendor.isNotEmpty ? '${gun.vendor} · ${gun.caliber}' : gun.caliber,
                style: TextStyle(color: grey, fontSize: 13)),
            const SizedBox(height: 16),
            // 归零卡
            Row(
              children: [
                const Text('归零卡',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton.icon(
                  onPressed: _addZero,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('记一张'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (_zeros.isEmpty)
              Text('还没记过归零卡：归零距离、用弹、瞄具调节记下来，下次换场子不用重摸。',
                  style: TextStyle(color: grey, fontSize: 13)),
            for (final z in _zeros)
              Card(
                margin: const EdgeInsets.only(bottom: 6),
                child: ListTile(
                  title: Text('${z.distance} 米归零 · ${z.date}'),
                  subtitle: Text(
                      [
                        if (z.ammo.isNotEmpty) '用弹：${z.ammo}',
                        if (z.clicks.isNotEmpty) '调节：${z.clicks}',
                        if (z.note.isNotEmpty) z.note,
                      ].join(' · '),
                      style: TextStyle(color: grey, fontSize: 12)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () async {
                      setState(() => _zeros.remove(z));
                      await _saveZeros();
                    },
                  ),
                ),
              ),
            const SizedBox(height: 16),
            // 分组趋势：该枪成绩按时间倒序，带 MOA。
            const Text('分组趋势（该枪成绩）',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            if (account == null)
              Text('登录后记的靶场成绩会按枪归集到这里，现在还没有可看的成绩。',
                  style: TextStyle(color: grey, fontSize: 13))
            else if (scores.isEmpty)
              Text('这把枪还没有靶场成绩，去靶场成绩里记一组就会出现在这里。',
                  style: TextStyle(color: grey, fontSize: 13)),
            for (final s in scores.take(20))
              Card(
                margin: const EdgeInsets.only(bottom: 6),
                child: ListTile(
                  title: Text(s.groupSize > 0
                      ? '分组 ${s.groupSize.toStringAsFixed(1)} 厘米'
                          '${s.distance > 0 ? '（${(s.groupSize / (s.distance * 0.02909)).toStringAsFixed(2)} MOA）' : ''}'
                      : '未记分组'),
                  subtitle: Text(
                      '${s.date.toString().substring(0, 10)} · ${s.distance} 米 · ${s.shots} 发'
                      '${s.ammo.isNotEmpty ? ' · ${s.ammo}' : ''}',
                      style: TextStyle(color: grey, fontSize: 12)),
                ),
              ),
            const SizedBox(height: 16),
            const Text('常用弹药',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            if (topAmmo.isEmpty)
              Text('还没有该枪带弹药信息的成绩，记成绩时填弹药就会统计出来。',
                  style: TextStyle(color: grey, fontSize: 13)),
            for (final e in topAmmo.take(5))
              Card(
                margin: const EdgeInsets.only(bottom: 6),
                child: ListTile(
                  title: Text(e.key),
                  trailing: Text('${e.value} 次',
                      style: TextStyle(color: grey, fontSize: 13)),
                ),
              ),
            const SizedBox(height: 16),
            const Text('收藏与保养',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
                collection == null
                    ? '这把枪还没进收藏柜，进收藏柜后这里显示累计发数。'
                    : '收藏柜：已打 ${collection.rounds} 发',
                style: TextStyle(color: grey, fontSize: 13)),
            const SizedBox(height: 4),
            Text(
                _lastMaintenance.isEmpty
                    ? '暂无保养记录。'
                    : '上次保养：$_lastMaintenance'
                        '${_maintenanceDays >= 0 ? '（${_maintenanceDays} 天前）' : ''}',
                style: TextStyle(color: grey, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
