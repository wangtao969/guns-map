import 'package:flutter/material.dart';
import '../community_store.dart';
import '../widgets/app_top_bar.dart';

/// 全部帖子管理（管理员 / 版主）：不只被举报的，全部帖子都可搜、
/// 可置顶、加精、删除；被举报的带举报次数与原因标记。
class AdminPostsScreen extends StatefulWidget {
  const AdminPostsScreen({super.key});

  @override
  State<AdminPostsScreen> createState() => _AdminPostsScreenState();
}

class _AdminPostsScreenState extends State<AdminPostsScreen> {
  final _queryCtrl = TextEditingController();

  @override
  void dispose() {
    _queryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final grey = dark ? const Color(0xFF8A8578) : const Color(0xFF9A917F);
    return Scaffold(
      appBar: const SubPageAppBar(title: '全部帖子'),
      body: AnimatedBuilder(
        animation: communityStore,
        builder: (_, __) {
          final q = _queryCtrl.text.trim().toLowerCase();
          final posts = communityStore.posts.where((p) {
            if (q.isEmpty) return true;
            return p.title.toLowerCase().contains(q) ||
                p.authorNickname.toLowerCase().contains(q) ||
                p.board.toLowerCase().contains(q);
          }).toList();
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              TextField(
                controller: _queryCtrl,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: '搜标题 / 作者 / 板块',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
              ),
              const SizedBox(height: 12),
              if (posts.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Center(
                    child: Text('没有符合的帖子', style: TextStyle(color: grey)),
                  ),
                ),
              for (final p in posts)
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
                            '${p.board} · ${p.authorNickname} · ${p.time.year}-${p.time.month}-${p.time.day}${p.pinned ? ' · 已置顶' : ''}${p.essence ? ' · 精华' : ''}',
                            style: TextStyle(color: grey, fontSize: 12)),
                        if (p.reported)
                          Text(
                              '被举报 ${p.reportCount} 次：${p.reportReasons.join('、')}',
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
                              onPressed: () => communityStore
                                  .setPinned(p, !p.pinned),
                              child: Text(p.pinned ? '取消置顶' : '置顶'),
                            ),
                            OutlinedButton(
                              onPressed: () => communityStore
                                  .setEssence(p, !p.essence),
                              child: Text(p.essence ? '取消精华' : '加精'),
                            ),
                            if (p.reported)
                              OutlinedButton(
                                onPressed: () =>
                                    communityStore.clearReport(p),
                                child: const Text('取消举报'),
                              ),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red),
                              onPressed: () async {
                                final ok = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('删除这条帖子？'),
                                    content:
                                        const Text('删除后本机数据无法恢复。'),
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
