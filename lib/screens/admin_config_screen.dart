import 'package:flutter/material.dart';
import '../widgets/app_toast.dart';
import 'package:flutter/services.dart';
import '../community_store.dart';
import '../widgets/app_top_bar.dart';

/// 后台配置（仅管理员）：板块开关、赛季长度、系统公告。
class AdminConfigScreen extends StatefulWidget {
  const AdminConfigScreen({super.key});

  @override
  State<AdminConfigScreen> createState() => _AdminConfigScreenState();
}

class _AdminConfigScreenState extends State<AdminConfigScreen> {
  late final TextEditingController _seasonCtrl;
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _seasonCtrl = TextEditingController(
        text: communityStore.seasonLengthDays.toString());
  }

  @override
  void dispose() {
    _seasonCtrl.dispose();
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final grey = dark ? const Color(0xFF8A8578) : const Color(0xFF9A917F);
    return Scaffold(
      appBar: const SubPageAppBar(title: '板块 / 赛季 / 公告'),
      body: AnimatedBuilder(
        animation: communityStore,
        builder: (_, __) {
          final announcements = communityStore.notifications
              .where((n) => n.kind == 'system')
              .toList();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('板块开关',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('关闭后板块不再出现在板块入口与发帖选择里，已发帖子不受影响。',
                  style: TextStyle(color: grey, fontSize: 12)),
              const SizedBox(height: 8),
              for (final b in communityBoards)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: SwitchListTile(
                    title: Text(b),
                    subtitle: Text(
                        '热度 ${communityStore.boardHeat(b)} · ${communityStore.posts.where((p) => p.board == b).length} 帖',
                        style: TextStyle(color: grey, fontSize: 12)),
                    value: !communityStore.disabledBoards.contains(b),
                    onChanged: (v) =>
                        communityStore.setBoardDisabled(b, !v),
                  ),
                ),
              const SizedBox(height: 20),
              const Text('赛季长度',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                  '当前赛季剩余 ${communityStore.seasonRemainingDays} 天；每日经验封顶 120 固定不变。',
                  style: TextStyle(color: grey, fontSize: 12)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _seasonCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      decoration: const InputDecoration(
                        labelText: '一季多少天',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final v = int.tryParse(_seasonCtrl.text.trim());
                      if (v == null || v < 7 || v > 365) {
                        showAppToast(context, '请输入 7–365 之间的天数');
                        return;
                      }
                      communityStore.seasonLengthDays = v;
                      communityStore.notifyListeners();
                      showAppToast(context, '赛季长度已改为 $v 天');
                    },
                    child: const Text('保存'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text('发布系统公告',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: '公告标题',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _bodyCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: '公告内容',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  final title = _titleCtrl.text.trim();
                  final body = _bodyCtrl.text.trim();
                  if (title.isEmpty || body.isEmpty) {
                    showAppToast(context, '标题和内容都不能为空');
                    return;
                  }
                  communityStore.publishAnnouncement(title, body);
                  _titleCtrl.clear();
                  _bodyCtrl.clear();
                  showAppToast(context, '公告已发布');
                },
                child: const Text('发布'),
              ),
              const SizedBox(height: 16),
              const Text('已有公告',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (announcements.isEmpty)
                Text('暂无公告', style: TextStyle(color: grey)),
              for (final n in announcements)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(n.title,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(n.body,
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () =>
                          communityStore.deleteAnnouncement(n),
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
