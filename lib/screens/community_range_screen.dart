import 'package:flutter/material.dart';
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
    final noteCtrl = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(gun.name),
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
              controller: noteCtrl,
              decoration: const InputDecoration(
                labelText: '备注（可选）',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(tr('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(tr('save')),
          ),
        ],
      ),
    );
    if (saved == true && context.mounted) {
      communityStore.addRangeScore(RangeScore(
        gunName: gun.name,
        distance: int.tryParse(distanceCtrl.text) ?? 100,
        shots: int.tryParse(shotsCtrl.text) ?? 5,
        groupSize: double.tryParse(groupCtrl.text) ?? 0,
        note: noteCtrl.text.trim(),
      ));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('成绩已记录 +5 经验')),
      );
    }
    distanceCtrl.dispose();
    shotsCtrl.dispose();
    groupCtrl.dispose();
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
          appBar: const GunsMapAppBar(),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const Expanded(
                    child: Text('靶场成绩',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
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
                        Text('记下分组、距离与发数，成绩直接喂靶场勋章',
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
                            '${r.distance} 米 · ${r.shots} 发 · 分组 ${r.groupSize} 厘米 · ${CommunityStore.formatTime(r.date)}${r.note.isNotEmpty ? ' · ${r.note}' : ''}'),
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
