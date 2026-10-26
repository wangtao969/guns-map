import 'package:flutter/material.dart';
import '../community_store.dart';
import '../widgets/app_toast.dart';
import '../widgets/app_top_bar.dart';

/// 敏感词管理（仅管理员）：新增词立即生效，删除后该词不再被替换。
/// 处理方式与现在一致：命中只替换为等长星号，不拦截。
class AdminWordsScreen extends StatefulWidget {
  const AdminWordsScreen({super.key});

  @override
  State<AdminWordsScreen> createState() => _AdminWordsScreenState();
}

class _AdminWordsScreenState extends State<AdminWordsScreen> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final grey = dark ? const Color(0xFF8A8578) : const Color(0xFF9A917F);
    return Scaffold(
      appBar: const SubPageAppBar(title: '敏感词管理'),
      body: AnimatedBuilder(
        animation: communityStore,
        builder: (_, __) {
          final added = communityStore.addedSensitiveWords;
          final effective = communityStore.effectiveSensitiveWords;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('命中只替换为等长星号，不拦截。删除内置词后该词不再被替换，谨慎操作。',
                  style: TextStyle(color: grey, fontSize: 12)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      decoration: const InputDecoration(
                        labelText: '新增敏感词',
                        border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(12))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final err =
                          communityStore.addSensitiveWord(_ctrl.text);
                      if (err != null) {
                        showAppToast(context, err);
                      } else {
                        _ctrl.clear();
                        showAppToast(context, '已新增，立即生效');
                      }
                    },
                    child: const Text('新增'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('生效词库（${effective.length} 条）',
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (added.isNotEmpty) ...[
                Text('管理员追加（${added.length} 条）',
                    style: TextStyle(color: grey, fontSize: 12)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: added
                      .map((w) => Chip(
                            label: Text(w),
                            onDeleted: () {
                              final err =
                                  communityStore.removeSensitiveWord(w);
                              if (err != null) showAppToast(context, err);
                            },
                          ))
                      .toList(),
                ),
                const SizedBox(height: 12),
              ],
              Text('内置词库',
                  style: TextStyle(color: grey, fontSize: 12)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: effective
                    .where((w) => !added.contains(w))
                    .map((w) => Chip(
                          label: Text(w),
                          onDeleted: () async {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (d) => AlertDialog(
                                title: const Text('删除这个内置词？'),
                                content: Text('删除后“$w”不再被替换为星号。'),
                                actions: [
                                  TextButton(
                                      onPressed: () =>
                                          Navigator.pop(d, false),
                                      child: const Text('取消')),
                                  TextButton(
                                      onPressed: () =>
                                          Navigator.pop(d, true),
                                      child: const Text('删除',
                                          style: TextStyle(
                                              color: Colors.red))),
                                ],
                              ),
                            );
                            if (ok == true && context.mounted) {
                              final err =
                                  communityStore.removeSensitiveWord(w);
                              if (err != null) showAppToast(context, err);
                            }
                          },
                        ))
                    .toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}
