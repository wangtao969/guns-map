import 'package:flutter/material.dart';
import '../widgets/app_top_bar.dart';

/// 社区板块：本地动态。暂未接后端，帖子仅保存在本次打开期间，
/// 先把发帖、浏览的架子跑通，后续再接账号与同步。
class CommunityPost {
  final String title;
  final String content;
  final String time;
  CommunityPost(
      {required this.title, required this.content, required this.time});
}

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final _posts = <CommunityPost>[];
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  bool _composing = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  String _now() {
    final n = DateTime.now();
    return '${n.month}月${n.day}日 ${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final grey = dark ? const Color(0xFF8A8578) : const Color(0xFF9A917F);
    final bronze = dark ? const Color(0xFFC9A86A) : const Color(0xFF6B5B3E);
    return Scaffold(
      appBar: const GunsMapAppBar(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('社区',
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('本地动态仅保存在本机，暂未联网同步；发帖、晒图与问答后续接入账号后开放。',
              style: TextStyle(color: grey, fontSize: 12)),
          const SizedBox(height: 12),
          if (!_composing)
            OutlinedButton.icon(
              onPressed: () => setState(() => _composing = true),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('发一条动态'),
            ),
          if (_composing) ...[
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: '标题',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _contentCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: '内容',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    if (_titleCtrl.text.trim().isEmpty &&
                        _contentCtrl.text.trim().isEmpty) {
                      return;
                    }
                    setState(() {
                      _posts.insert(
                          0,
                          CommunityPost(
                            title: _titleCtrl.text.trim().isEmpty
                                ? '无标题'
                                : _titleCtrl.text.trim(),
                            content: _contentCtrl.text.trim(),
                            time: _now(),
                          ));
                      _titleCtrl.clear();
                      _contentCtrl.clear();
                      _composing = false;
                    });
                  },
                  child: const Text('发布'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => setState(() => _composing = false),
                  child: const Text('取消'),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          if (_posts.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.forum_outlined, size: 48, color: grey),
                    const SizedBox(height: 12),
                    Text('还没有动态', style: TextStyle(color: grey)),
                    const SizedBox(height: 4),
                    Text('发一条动态，聊聊你的枪械与复装心得',
                        style: TextStyle(color: grey, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ..._posts.map((p) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: bronze,
                            foregroundColor:
                                dark ? const Color(0xFF121110) : Colors.white,
                            radius: 16,
                            child: const Text('我',
                                style: TextStyle(fontSize: 13)),
                          ),
                          const SizedBox(width: 8),
                          const Text('wangtao969',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          Text(p.time,
                              style: TextStyle(color: grey, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(p.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      if (p.content.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(p.content),
                      ],
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
