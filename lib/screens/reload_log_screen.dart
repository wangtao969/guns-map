import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data.dart';
import '../widgets/app_toast.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/glass_dialog.dart';
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
  // 放行标记：只有通过完整性与 SOP 检测的记录才会保存，旧记录默认已放行。
  final bool released;
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
    this.released = true,
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
        'released': released,
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
        released: j['released'] as bool? ?? true,
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

  /// 放行检测：SOP 必须全部打勾；配方、组件与试射字段必须填完整；
  /// 装药量、弹长、数量、弹壳使用次数必须是大于 0 的数字。
  /// 返回缺失/不合格项，空表即放行。
  List<String> _missing() {
    final miss = <String>[];
    final doneCount = _done.where((d) => d).length;
    if (doneCount != reloadSopSteps.length) {
      miss.add('SOP 未全部打勾（$doneCount/${reloadSopSteps.length}）');
    }
    if (_caliber == null) miss.add('口径');
    final fields = {
      '弹头': _bulletCtrl.text.trim(),
      '火药': _powderCtrl.text.trim(),
      '装药量': _chargeCtrl.text.trim(),
      '弹长 COL': _colCtrl.text.trim(),
      '数量': _roundsCtrl.text.trim(),
      '底火': _primerCtrl.text.trim(),
      '火药/底火批号': _lotCtrl.text.trim(),
      '弹壳品牌': _caseBrandCtrl.text.trim(),
      '弹壳使用次数': _caseTimesCtrl.text.trim(),
      '初速': _velocityCtrl.text.trim(),
      '散布': _groupCtrl.text.trim(),
      '试射枪械': _firearmCtrl.text.trim(),
      '天气/温度': _weatherCtrl.text.trim(),
    };
    fields.forEach((k, v) {
      if (v.isEmpty) miss.add(k);
    });
    double? num(String v) => double.tryParse(v);
    if (_chargeCtrl.text.trim().isNotEmpty &&
        (num(_chargeCtrl.text.trim()) ?? 0) <= 0) {
      miss.add('装药量须为大于 0 的数字');
    }
    if (_colCtrl.text.trim().isNotEmpty &&
        (num(_colCtrl.text.trim()) ?? 0) <= 0) {
      miss.add('弹长 COL 须为大于 0 的数字');
    }
    if (_roundsCtrl.text.trim().isNotEmpty &&
        (num(_roundsCtrl.text.trim()) ?? 0) <= 0) {
      miss.add('数量须为大于 0 的数字');
    }
    if (_caseTimesCtrl.text.trim().isNotEmpty &&
        (num(_caseTimesCtrl.text.trim()) ?? 0) < 1) {
      miss.add('弹壳使用次数须为大于等于 1 的数字');
    }
    return miss;
  }

  void _clearForm() {
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
    _caliber = null;
    _done = List<bool>.filled(reloadSopSteps.length, false);
  }

  Future<void> _tryRelease() async {
    final miss = _missing();
    if (miss.isNotEmpty) {
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (ctx) => GlassDialog(
          title: '未通过放行检测',
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('以下内容未填完整或不符合 SOP，补齐后才能放行记录：'),
              const SizedBox(height: 8),
              ...miss.map((m) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('· $m'),
                  )),
            ],
          ),
          actions: [glassPrimaryButton(ctx, '知道了')],
        ),
      );
      return;
    }
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
            released: true,
          ));
      _save();
      _clearForm();
    });
    if (mounted) showAppToast(context, '已通过 SOP 检测，放行并保存记录');
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
          Text('按步骤打勾，全部完成才能记一条；记录保存在本机，重启不丢。Tick off the SOP steps; all must be complete before a record can be released. Records stay on this device.',
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
          const SizedBox(height: 4),
          Text('四步填完：配方 → 组件 → 试射 → 放行检测。带 * 的必须填完整，备注选填；弹头、火药、底火、弹壳、枪械边输边从数据库里搜，点一下即填入，数据库里没有的也可手动填写。Complete in four steps: Recipe → Components → Test Results → Release Check. Fields marked * are required; Notes are optional.',
              style: TextStyle(color: grey, fontSize: 12)),
          const SizedBox(height: 12),
          const Text('配方 Load Recipe *', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _caliber,
            decoration: const InputDecoration(
              labelText: '口径 * / Caliber',
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
            ),
            items: reloadCalibers
                .map((c) => DropdownMenuItem(
                    value: c.caliber, child: Text(c.caliber)))
                .toList(),
            onChanged: (v) => setState(() => _caliber = v),
          ),
          const SizedBox(height: 8),
          _SuggestField(controller: _bulletCtrl, label: '弹头 * / Bullet（品牌/重量/型号）', kind: '弹头'),
          const SizedBox(height: 8),
          _SuggestField(controller: _powderCtrl, label: '火药 * / Powder（品牌/型号）', kind: '火药'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chargeCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '装药量 * / Powder Charge（gr）',
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _colCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '弹长 COL * / Overall Length（″）',
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _roundsCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '数量 * / Rounds（发）',
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
            ),
          ),
          const SizedBox(height: 16),
          const Text('组件与批号 Components & Lot *', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _SuggestField(controller: _primerCtrl, label: '底火 * / Primer（品牌/型号）', kind: '底火'),
          const SizedBox(height: 8),
          TextField(
            controller: _lotCtrl,
            decoration: const InputDecoration(
              labelText: '火药/底火批号 * / Powder & Primer Lot',
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _SuggestField(controller: _caseBrandCtrl, label: '弹壳品牌 * / Case Brand', kind: '弹壳'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _caseTimesCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '弹壳使用次数 * / Case Firings',
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('试射结果 Test Results *', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _SuggestField(
            controller: _firearmCtrl,
            label: '试射枪械 * / Test Firearm',
            kind: '',
            customItems: guns.map((g) => '${g.vendor} ${g.name}').toList(),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _velocityCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '初速 * / Muzzle Velocity（fps）',
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _groupCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '散布 * / Group Size（100 码，″）',
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _weatherCtrl,
            decoration: const InputDecoration(
              labelText: '天气/温度 * / Weather & Temperature',
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _noteCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: '备注 / Notes（选填 Optional：批次、试射结果等）',
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
            ),
          ),
          const SizedBox(height: 12),
          Builder(builder: (_) {
            final miss = _missing();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      miss.isEmpty ? Icons.verified_outlined : Icons.pending_outlined,
                      size: 18,
                      color: miss.isEmpty ? Colors.green : grey,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        miss.isEmpty
                            ? '放行检测已通过：SOP 全部完成，必填项齐全'
                            : '放行检测：还差 ${miss.length} 项（${miss.take(3).join('、')}${miss.length > 3 ? '…' : ''}）',
                        style: TextStyle(
                            color: miss.isEmpty ? Colors.green : grey,
                            fontSize: 13,
                            fontWeight: miss.isEmpty ? FontWeight.bold : FontWeight.normal),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _tryRelease,
                    child: const Text('检测并放行记录 / Verify & Release'),
                  ),
                ),
                if (miss.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('点“检测并放行记录”会列出全部未通过项',
                        style: TextStyle(color: grey, fontSize: 12)),
                  ),
              ],
            );
          }),
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
                            child: Row(
                              children: [
                                Text('${l.date} · ${l.caliber}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                if (l.released) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text('已放行',
                                        style: TextStyle(
                                            color: Colors.green, fontSize: 11)),
                                  ),
                                ],
                              ],
                            ),
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

/// 边输边搜输入框：输入时从复装组件库（弹头/火药/底火/弹壳）或自定义列表
/// （试射枪械用图鉴枪名）里实时过滤，最多显示 6 条，点一下即填入；
/// 数据库里没有的仍可手动填写，不卡保存。
class _SuggestField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String kind;
  final List<String>? customItems;
  const _SuggestField({
    required this.controller,
    required this.label,
    this.kind = '',
    this.customItems,
  });

  @override
  State<_SuggestField> createState() => _SuggestFieldState();
}

class _SuggestFieldState extends State<_SuggestField> {
  final _focus = FocusNode();
  String _query = '';
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (mounted) setState(() => _focused = _focus.hasFocus);
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  List<String> _suggestions() {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    if (widget.customItems != null) {
      return widget.customItems!
          .where((s) => s.toLowerCase().contains(q))
          .take(6)
          .toList();
    }
    return reloadComponents
        .where((c) =>
            c.kind == widget.kind &&
            ('${c.vendor} ${c.name} ${c.spec}'.toLowerCase().contains(q)))
        .map((c) => '${c.vendor} ${c.name}')
        .take(6)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final sug = _suggestions();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.controller,
          focusNode: _focus,
          onChanged: (v) => setState(() => _query = v),
          decoration: InputDecoration(
            labelText: widget.label,
            border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12))),
            suffixIcon: widget.controller.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      widget.controller.clear();
                      setState(() => _query = '');
                    },
                  ),
          ),
        ),
        if (_focused && _query.trim().isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: sug.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(10),
                    child: Text('数据库里没有这个型号，仍可手动填写',
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                  )
                : Column(
                    children: sug
                        .map((s) => ListTile(
                              dense: true,
                              title: Text(s, style: const TextStyle(fontSize: 14)),
                              onTap: () {
                                widget.controller.text = s;
                                setState(() => _query = '');
                                _focus.unfocus();
                              },
                            ))
                        .toList(),
                  ),
          ),
      ],
    );
  }
}
