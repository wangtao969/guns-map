import 'package:flutter/material.dart';
import '../widgets/app_toast.dart';
import '../widgets/glass_dialog.dart';
import '../community_store.dart';
import '../i18n.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/community_theme.dart';
import 'community_account_dialogs.dart';
import 'gun_picker_dialog.dart';

/// 靶场成绩：分组、距离、发数，绑定枪种；成绩直接喂靶场勋章。
class CommunityRangeScreen extends StatelessWidget {
  const CommunityRangeScreen({super.key});

  Future<void> _addScore(BuildContext context) async {
    final gun = await showGunPickerDialog(context);
    if (gun == null || !context.mounted) return;
    final distanceCtrl = TextEditingController(text: '100');
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
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: shotsCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '发数',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: groupCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: '分组（厘米，弹着散布）',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: scoreCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '环数 / 得分（可选）',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: position,
                decoration: const InputDecoration(
                  labelText: '射击姿势',
                  border: OutlineInputBorder(),
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
                  border: OutlineInputBorder(),
                ),
                items: targets
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) =>
                    setDialogState(() => target = v ?? target),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ammoCtrl,
                decoration: const InputDecoration(
                  labelText: '弹药（品牌 / 型号，可选）',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: weatherCtrl,
                      decoration: const InputDecoration(
                        labelText: '天气（可选）',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: windCtrl,
                      decoration: const InputDecoration(
                        labelText: '风速风向（可选）',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(
                  labelText: '备注（可选）',
                  border: OutlineInputBorder(),
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
      communityStore.addRangeScore(RangeScore(
        gunName: gun.name,
        distance: int.tryParse(distanceCtrl.text) ?? 100,
        shots: int.tryParse(shotsCtrl.text) ?? 5,
        groupSize: double.tryParse(groupCtrl.text) ?? 0,
        note: noteCtrl.text.trim(),
        caliber: gun.caliber,
        ammo: ammoCtrl.text.trim(),
        position: position,
        target: target,
        score: scoreCtrl.text.trim(),
        weather: weatherCtrl.text.trim(),
        wind: windCtrl.text.trim(),
      ));
      showAppToast(context, '成绩已记录 +5 经验');
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
                ...me.rangeScores.map((r) => Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const Icon(Icons.gps_fixed,
                            color: communityAccent),
                        title: Text(r.gunName),
                        subtitle: Text(
                            '${r.distance} 米 · ${r.shots} 发 · 分组 ${r.groupSize} 厘米${r.score.isNotEmpty ? ' · ${r.score} 环' : ''}${r.position.isNotEmpty ? ' · ${r.position}' : ''}${r.target.isNotEmpty ? ' · ${r.target}' : ''} · ${CommunityStore.formatTime(r.date)}${r.ammo.isNotEmpty ? ' · ${r.ammo}' : ''}${r.weather.isNotEmpty ? ' · ${r.weather}' : ''}${r.wind.isNotEmpty ? ' · ${r.wind}' : ''}${r.note.isNotEmpty ? ' · ${r.note}' : ''}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          onPressed: () =>
                              communityStore.removeRangeScore(r),
                        ),
                      ),
                    )),
            ],
          ),
        );
      },
    );
  }
}
