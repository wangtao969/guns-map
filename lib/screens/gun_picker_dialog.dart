import 'package:flutter/material.dart';
import '../data.dart';
import '../models.dart';

/// 从图鉴选一把枪：搜索框 + 列表，收藏柜与靶场成绩共用。
Future<Gun?> showGunPickerDialog(BuildContext context) async {
  final ctrl = TextEditingController();
  var query = '';
  final picked = await showDialog<Gun>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (_, setDialogState) {
        final q = query.trim().toLowerCase();
        final results = q.isEmpty
            ? guns.take(60).toList()
            : guns
                .where((g) =>
                    g.name.toLowerCase().contains(q) ||
                    g.vendor.toLowerCase().contains(q) ||
                    g.caliber.toLowerCase().contains(q))
                .take(60)
                .toList();
        return AlertDialog(
          title: const Text('选一把枪'),
          content: SizedBox(
            width: double.maxFinite,
            height: 420,
            child: Column(
              children: [
                TextField(
                  controller: ctrl,
                  onChanged: (v) => setDialogState(() => query = v),
                  decoration: const InputDecoration(
                    hintText: '搜枪名、厂商、口径',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: results.isEmpty
                      ? const Center(child: Text('没有匹配的枪'))
                      : ListView.builder(
                          itemCount: results.length,
                          itemBuilder: (_, i) {
                            final g = results[i];
                            return ListTile(
                              title: Text(g.name),
                              subtitle:
                                  Text('${g.vendor} · ${g.caliber}'),
                              onTap: () => Navigator.of(dialogContext)
                                  .pop(g),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('取消'),
            ),
          ],
        );
      },
    ),
  );
  ctrl.dispose();
  return picked;
}
