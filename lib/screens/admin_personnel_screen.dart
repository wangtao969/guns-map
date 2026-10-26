import 'package:flutter/material.dart';
import '../community_store.dart';
import '../widgets/app_top_bar.dart';
import 'admin_user_detail_screen.dart';

String _roleLabel(String role) {
  switch (role) {
    case 'admin':
      return '管理员';
    case 'moderator':
      return '版主';
    default:
      return '普通用户';
  }
}

String _statusLabel(CommunityAccount a) {
  if (a.status == 'banned') return '已封禁';
  if (a.status == 'muted') {
    if (a.muteExpired) return '禁言已到期';
    if (a.mutedUntil == null) return '禁言中（永久）';
    return '禁言至 ${a.mutedUntil.toString().substring(0, 10)}';
  }
  return '正常';
}

/// 人员管理（仅管理员）：点用户进详情页改角色、禁言（含时长）、封禁。
/// 不能改自己，不能改初始管理员（ID wangtao969）。
class AdminPersonnelScreen extends StatefulWidget {
  const AdminPersonnelScreen({super.key});

  @override
  State<AdminPersonnelScreen> createState() => _AdminPersonnelScreenState();
}

class _AdminPersonnelScreenState extends State<AdminPersonnelScreen> {
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
      appBar: const SubPageAppBar(title: '人员管理'),
      body: AnimatedBuilder(
        animation: communityStore,
        builder: (_, __) {
          final q = _queryCtrl.text.trim().toLowerCase();
          final accounts = communityStore.accounts.where((a) {
            if (q.isEmpty) return true;
            return a.nickname.toLowerCase().contains(q) ||
                a.id.toLowerCase().contains(q);
          }).toList();
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              TextField(
                controller: _queryCtrl,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: '搜昵称 / ID',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    '权限说明：版主可审核帖子（恢复、置顶、加精、删除被举报帖）；管理员可管理全部人员与配置。禁言后不能发帖评论，封禁后同样不能发帖评论。',
                    style: TextStyle(color: grey, fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (accounts.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Center(
                    child: Text('暂无注册用户', style: TextStyle(color: grey)),
                  ),
                ),
              for (final a in accounts)
                Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: communityAvatar(
                      bytes: a.avatarBytes,
                      color: a.avatarColor,
                      nickname: a.nickname,
                      radius: 20,
                      frame: a.avatarFrame,
                      verified: isSpecialAccount(a),
                    ),
                    title: Text(a.nickname,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        'ID ${a.id} · ${_roleLabel(a.role)} · ${_statusLabel(a)} · ${a.totalXp} XP',
                        style: TextStyle(color: grey, fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              AdminUserDetailScreen(account: a)),
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
