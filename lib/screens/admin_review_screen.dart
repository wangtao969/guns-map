import 'package:flutter/material.dart';
import '../community_store.dart';
import '../widgets/app_top_bar.dart';

/// 帖子审核（管理员 / 版主）：处理被举报的帖子。
class AdminReviewScreen extends StatelessWidget {
  const AdminReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final grey = dark ? const Color(0xFF8A8578) : const Color(0xFF9A917F);
    return Scaffold(
      appBar: const SubPageAppBar(title: '帖子审核'),
      body: AnimatedBuilder(
        animation: communityStore,
        builder: (_, __) {
          final reported = communityStore.posts
              .where((p) => p.reported)
              .toList()
            ..sort((a, b) => b.reportCount.compareTo(a.reportCount));
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              if (reported.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Center(
                    child: Text('暂无被举报的帖子', style: TextStyle(color: grey)),
                  ),
                ),
              for (final p in reported)
                Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 2),
                        Text(
                            '${p.board} · ${p.authorNickname} · ${p.time.year}-${p.time.month}-${p.time.day}',
                            style: TextStyle(color: grey, fontSize: 12)),
                        if (p.reportReasons.isNotEmpty)
                          Text(
                              '举报 ${p.reportCount} 次：${p.reportReasons.join('、')}',
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 12)),
                        const SizedBox(height: 6),
                        Text(p.content,
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          children: [
                            OutlinedButton(
                              onPressed: () =>
                                  communityStore.clearReport(p),
                              child: const Text('取消举报'),
                            ),
                            OutlinedButton(
                              onPressed: () => communityStore
                                  .setPinned(p, !p.pinned),
                              child: Text(p.pinned ? '取消置顶' : '置顶'),
                            ),
                            OutlinedButton(
                              onPressed: () => communityStore
                                  .setEssence(p, !p.essence),
                              child: Text(p.essence ? '取消精华' : '加精'),
                            ),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red),
                              onPressed: () async {
                                final ok = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('删除这条帖子？'),
                                    content: const Text('删除后不可恢复。'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('取消'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text('删除'),
                                      ),
                                    ],
                                  ),
                                );
                                if (ok == true) {
                                  communityStore.deletePost(p);
                                }
                              },
                              child: const Text('删除'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
