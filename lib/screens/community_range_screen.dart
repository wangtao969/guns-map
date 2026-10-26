import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data.dart';
import '../models.dart';
import '../widgets/app_toast.dart';
import '../widgets/glass_dialog.dart';
import '../community_store.dart';
import '../i18n.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/community_theme.dart';
import 'community_account_dialogs.dart';
import 'gun_picker_dialog.dart';
import 'ammo_inventory_screen.dart';
import 'reload_log_screen.dart';
import 'range_tools_screen.dart';

/// 靶场成绩：分组、距离、发数，绑定枪种；成绩直接喂靶场勋章。
/// 顶部统计卡 + 按枪筛选 + 结构化卡片，成绩不再是一长串字；
/// 录入框里可勾选同步：从弹药库存扣发数、计入藏枪已打发数。
class CommunityRangeScreen extends StatefulWidget {
  const CommunityRangeScreen({super.key});

  @override
  State<CommunityRangeScreen> createState() => _CommunityRangeScreenState();
}

class _CommunityRangeScreenState extends State<CommunityRangeScreen> {
  String _filter = '全部';

  String _fmt(double v, [int digits = 2]) {
    var s = v.toStringAsFixed(digits);
    while (s.contains('.') && s.endsWith('0')) {
      s = s.substring(0, s.length - 1);
    }
    if (s.endsWith('.')) s = s.substring(0, s.length - 1);
    return s;
  }

  Future<void> _addScore(BuildContext context,
      {Gun? presetGun, int? presetDist}) async {
    final gun = presetGun ?? await showGunPickerDialog(context);
    if (gun == null || !context.mounted) return;
    final distanceCtrl =
        TextEditingController(text: '${presetDist ?? 100}');
    // 弹药优先从库存选：该口径有库存时下拉点选，没有再手填。
    final stockItems = await loadAmmoItems();
    if (!context.mounted) return;
    final stockNames = stockItems
        .where((e) => e.caliber == gun.caliber)
        .map((e) => e.name)
        .toSet()
        .toList();
    var ammoChoice = stockNames.isNotEmpty ? stockNames.first : '手动填';
    // 已放行批次：成绩录入时可手选关联，配方卡靠批次号找实测成绩。
    var releasedBatches = <ReloadLogEntry>[];
    try {
      final raw = await const MethodChannel('gunsmap/prefs')
          .invokeMethod<String>('getString', {'key': 'reload_log_v1'})
          .timeout(const Duration(seconds: 2));
      if (raw != null && raw.isNotEmpty) {
        releasedBatches = (jsonDecode(raw) as List)
            .map((e) => ReloadLogEntry.fromJson(e as Map<String, dynamic>))
            .where((e) => e.released && e.batchNo.isNotEmpty)
            .toList();
      }
    } catch (_) {}
    var batchChoice = '不关联';
    // 同步勾选：扣库存只对同口径库存，计入藏枪只对已在收藏柜的枪。
    AmmoItem? deductItem;
    for (final item in stockItems) {
      if (item.caliber == gun.caliber) {
        deductItem = item;
        break;
      }
    }
    final deductItemFinal = deductItem;
    var deductStock = false;
    final inCollection = communityStore.current?.collection
            .any((c) => c.gunName == gun.name) ??
        false;
    var addToCollection = false;
    final shotsCtrl = TextEditingController(text: '5');
    final groupCtrl = TextEditingController(text: '');
    final scoreCtrl = TextEditingController(text: '');
    final ammoCtrl = TextEditingController(text: '');
    final weatherCtrl = TextEditingController(text: '');
    final windCtrl = TextEditingController(text: '');
    final noteCtrl = TextEditingController();
    var position = '站姿';
    var target = '胸环靶';
    const positions = ['站姿', '跪姿', '卧姿', '依托', '坐姿'];
    const targets = ['胸环靶', '精度靶', '人形靶', '钢靶', '其他'];
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setDialogState) => GlassDialog(
          title: gun.name,
          subtitle: gun.caliber.isNotEmpty ? '口径 ${gun.caliber}' : null,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: distanceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '距离（米）',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: shotsCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '发数',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: groupCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: '分组（厘米，弹着散布）',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: scoreCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '环数 / 得分（可选）',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: position,
                decoration: const InputDecoration(
                  labelText: '射击姿势',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
                items: positions
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) =>
                    setDialogState(() => position = v ?? position),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: target,
                decoration: const InputDecoration(
                  labelText: '靶纸类型',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
                items: targets
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) =>
                    setDialogState(() => target = v ?? target),
              ),
              const SizedBox(height: 12),
              if (stockNames.isNotEmpty) ...[
                Row(
                  children: [
                    const Text('弹药：'),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButton<String>(
                        value: ammoChoice,
                        isExpanded: true,
                        items: [
                          ...stockNames.map((n) =>
                              DropdownMenuItem(value: n, child: Text(n))),
                          const DropdownMenuItem(
                              value: '手动填', child: Text('手动填')),
                        ],
                        onChanged: (v) => setDialogState(
                            () => ammoChoice = v ?? ammoChoice),
                      ),
                    ),
                  ],
                ),
                if (ammoChoice == '手动填') ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: ammoCtrl,
                    decoration: const InputDecoration(
                      labelText: '弹药（品牌 / 型号，可选）',
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    ),
                  ),
                ],
              ] else
                TextField(
                  controller: ammoCtrl,
                  decoration: const InputDecoration(
                    labelText: '弹药（品牌 / 型号，可选）',
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                children: ['晴', '阴', '雨', '雪', '室内']
                    .map((w) => ActionChip(
                          label: Text(w),
                          onPressed: () =>
                              setDialogState(() => weatherCtrl.text = w),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: weatherCtrl,
                      decoration: const InputDecoration(
                        labelText: '天气（可选）',
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: windCtrl,
                      decoration: const InputDecoration(
                        labelText: '风速风向（可选）',
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                    ),
                  ),
                ],
              ),
              if (releasedBatches.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('关联复装批次（可选）',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                DropdownButton<String>(
                  value: batchChoice,
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem(
                        value: '不关联', child: Text('不关联')),
                    for (final b in releasedBatches)
                      DropdownMenuItem(
                        value: b.batchNo,
                        child: Text(
                            '${b.batchNo}（${b.caliber} ${b.bullet}）',
                            overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (v) =>
                      setDialogState(() => batchChoice = v ?? '不关联'),
                ),
              ],
              if (deductItemFinal != null || inCollection) ...[
                const SizedBox(height: 12),
                const Text('同步（可选，不勾不做）',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                if (deductItemFinal != null)
                  CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text('从弹药库存扣发数（${deductItemFinal.name}）'),
                    value: deductStock,
                    onChanged: (v) =>
                        setDialogState(() => deductStock = v ?? false),
                  ),
                if (inCollection)
                  CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text('计入藏枪已打发数'),
                    value: addToCollection,
                    onChanged: (v) => setDialogState(
                        () => addToCollection = v ?? false),
                  ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(
                  labelText: '备注（可选）',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
              ),
            ],
          ),
          actions: [
            glassCancelButton(dialogContext, tr('cancel')),
            glassPrimaryButton(dialogContext, tr('save'), popTrue: true),
          ],
        ),
      ),
    );
    if (saved == true && context.mounted) {
      final ammoText = stockNames.isNotEmpty && ammoChoice != '手动填'
          ? ammoChoice
          : ammoCtrl.text.trim();
      final shots = int.tryParse(shotsCtrl.text) ?? 5;
      communityStore.addRangeScore(RangeScore(
        gunName: gun.name,
        distance: int.tryParse(distanceCtrl.text) ?? 100,
        shots: shots,
        groupSize: double.tryParse(groupCtrl.text) ?? 0,
        note: noteCtrl.text.trim(),
        caliber: gun.caliber,
        ammo: ammoText,
        position: position,
        target: target,
        score: scoreCtrl.text.trim(),
        weather: weatherCtrl.text.trim(),
        wind: windCtrl.text.trim(),
        batchNo: batchChoice == '不关联' ? '' : batchChoice,
      ));
      showAppToast(context, '成绩已记录 +5 经验');
      if (deductStock && deductItemFinal != null && shots > 0) {
        final used = shots > deductItemFinal.quantity
            ? deductItemFinal.quantity
            : shots;
        if (used > 0) {
          deductItemFinal.quantity -= used;
          await saveAmmoItems(stockItems);
          await addAmmoMovement(AmmoMovement(
              date: DateTime.now().toString().substring(0, 10),
              name: deductItemFinal.name,
              caliber: deductItemFinal.caliber,
              delta: -used,
              reason: '打靶'));
        }
      }
      if (addToCollection && shots > 0) {
        communityStore.addCollectionRounds(gun.name, shots);
      }
    }
    distanceCtrl.dispose();
    shotsCtrl.dispose();
    groupCtrl.dispose();
    scoreCtrl.dispose();
    ammoCtrl.dispose();
    weatherCtrl.dispose();
    windCtrl.dispose();
    noteCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final grey = communitySecondary(dark);
    return AnimatedBuilder(
      animation: communityStore,
      builder: (_, __) {
        final me = communityStore.current;
        return Scaffold(
          appBar: SubPageAppBar(title: '靶场成绩'),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  const Spacer(),
                  if (me != null)
                    OutlinedButton.icon(
                      onPressed: () => _addScore(context),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('记一条'),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (me == null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tr('not_logged'),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () => showLoginDialog(context),
                              child: Text(tr('login')),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: () => showRegisterDialog(context),
                              child: Text(tr('register')),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              else if (me.rangeScores.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 32),
                    child: Column(
                      children: [
                        Icon(Icons.gps_fixed, size: 48, color: grey),
                        const SizedBox(height: 12),
                        Text('还没有靶场成绩',
                            style: TextStyle(color: grey)),
                        const SizedBox(height: 4),
                        Text('记下距离、姿势、环数与分组，成绩直接喂靶场勋章',
                            style: TextStyle(color: grey, fontSize: 12)),
                      ],
                    ),
                  ),
                )
              else
                Builder(
                  builder: (_) {
                    final scores = me.rangeScores;
                    final totalShots =
                        scores.fold<int>(0, (sum, e) => sum + e.shots);
                    RangeScore? best;
                    for (final r in scores) {
                      if (r.groupSize > 0 &&
                          (best == null || r.groupSize < best.groupSize)) {
                        best = r;
                      }
                    }
                    final gunNames =
                        scores.map((r) => r.gunName).toSet().toList();
                    final shown = _filter == '全部'
                        ? scores
                        : scores
                            .where((r) => r.gunName == _filter)
                            .toList();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${scores.length} 次 · 共 $totalShots 发',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                if (best != null)
                                  Text(
                                      best.distance > 0
                                          ? '最好分组：${_fmt(best.groupSize)} 厘米（${_fmt(best.groupSize / (best.distance * 0.02909))} MOA，${best.distance} 米，${best.gunName}）'
                                          : '最好分组：${_fmt(best.groupSize)} 厘米（${best.gunName}）',
                                      style: const TextStyle(
                                          color: Colors.grey, fontSize: 12)),
                                Text(
                                    '最近一次：${CommunityStore.formatTime(scores.first.date)}',
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 6,
                          children: ['全部', ...gunNames]
                              .map((g) => ChoiceChip(
                                    label: Text(g),
                                    selected: _filter == g,
                                    onSelected: (_) =>
                                        setState(() => _filter = g),
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 12),
                        if (shown.isEmpty)
                          const Text('该枪暂无成绩',
                              style: TextStyle(color: Colors.grey))
                        else
                          ...shown.map((r) {
                            final moa = r.distance > 0 && r.groupSize > 0
                                ? r.groupSize / (r.distance * 0.02909)
                                : 0.0;
                            final details = [
                              if (r.position.isNotEmpty) r.position,
                              if (r.target.isNotEmpty) r.target,
                              if (r.ammo.isNotEmpty) r.ammo,
                              if (r.weather.isNotEmpty) r.weather,
                              if (r.wind.isNotEmpty) r.wind,
                              if (r.note.isNotEmpty) r.note,
                            ].join(' · ');
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(r.gunName,
                                              style: const TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold)),
                                        ),
                                        Text(
                                            CommunityStore.formatTime(
                                                r.date),
                                            style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    if (r.groupSize > 0)
                                      Text(
                                          '分组 ${_fmt(r.groupSize)} 厘米${moa > 0 ? '（${_fmt(moa)} MOA）' : ''}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFFE86A1C),
                                              fontSize: 15))
                                    else
                                      const Text('未记分组',
                                          style: TextStyle(
                                              color: Colors.grey)),
                                    const SizedBox(height: 4),
                                    Text(
                                        '${r.distance} 米 · ${r.shots} 发${r.score.isNotEmpty ? ' · ${r.score} 环' : ''}'),
                                    if (details.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(details,
                                          style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12)),
                                    ],
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.end,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.repeat,
                                              size: 20),
                                          tooltip: '再记一组（同枪同距离）',
                                          onPressed: () {
                                            Gun? found;
                                            for (final g in guns) {
                                              if (g.name == r.gunName) {
                                                found = g;
                                              }
                                            }
                                            if (found != null) {
                                              _addScore(context,
                                                  presetGun: found,
                                                  presetDist: r.distance);
                                            } else {
                                              _addScore(context);
                                            }
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                              Icons.calculate_outlined,
                                              size: 20),
                                          tooltip: '用这次成绩算散布',
                                          onPressed: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  RangeToolsScreen(
                                                initialDistM:
                                                    r.distance.toDouble(),
                                                initialGroupCm: r.groupSize,
                                                initialLabel:
                                                    '靶场成绩 ${r.gunName} · ${r.distance} 米',
                                              ),
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                              Icons.delete_outline,
                                              size: 20),
                                          onPressed: () => communityStore
                                              .removeRangeScore(r),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                      ],
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
