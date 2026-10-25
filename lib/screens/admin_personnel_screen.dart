import 'package:flutter/material.dart';
import '../widgets/app_toast.dart';
import '../community_store.dart';
import '../widgets/app_top_bar.dart';

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

String _statusLabel(String status) {
  switch (status) {
    case 'muted':
      return '禁言中';
    case 'banned':
      return '已封禁';
    default:
      return '正常';
  }
}

/// 人员管理（仅管理员）：任命 / 撤销角色，禁言 / 封禁 / 恢复。
/// 不能改自己，不能改初始管理员（ID wangtao969）。
class AdminPersonnelScreen extends StatelessWidget {
  const AdminPersonnelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final grey = dark ? const Color(0xFF8A8578) : const Color(0xFF9A917F);
    return Scaffold(
      appBar: const SubPageAppBar(title: '人员管理'),
      body: AnimatedBuilder(
        animation: communityStore,
        builder: (_, __) {
          final accounts = communityStore.accounts.toList();
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
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
                    ),
                    title: Text(a.nickname,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        'ID ${a.id} · ${_roleLabel(a.role)} · ${_statusLabel(a.status)} · ${a.totalXp} XP',
                        style: TextStyle(color: grey, fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _manage(context, a),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _manage(BuildContext context, CommunityAccount a) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('${a.nickname}（ID ${a.id}）'),
              subtitle: Text('${_roleLabel(a.role)} · ${_statusLabel(a.status)}'),
            ),
            const Divider(height: 1),
            _item('设为普通用户', 'role_user'),
            _item('设为版主', 'role_moderator'),
            _item('设为管理员', 'role_admin'),
            _item(a.status == 'muted' ? '解除禁言' : '禁言', 'mute_toggle'),
            _item(a.status == 'banned' ? '解除封禁' : '封禁', 'ban_toggle'),
          ],
        ),
      ),
    );
    if (action == null || !context.mounted) return;
    String? err;
    switch (action) {
      case 'role_user':
        err = communityStore.setUserRole(a, 'user');
        break;
      case 'role_moderator':
        err = communityStore.setUserRole(a, 'moderator');
        break;
      case 'role_admin':
        err = communityStore.setUserRole(a, 'admin');
        break;
      case 'mute_toggle':
        err = communityStore
            .setUserStatus(a, a.status == 'muted' ? 'active' : 'muted');
        break;
      case 'ban_toggle':
        err = communityStore
            .setUserStatus(a, a.status == 'banned' ? 'active' : 'banned');
        break;
    }
    if (!context.mounted) return;
    showAppToast(context, err ?? '已更新');
  }

  Widget _item(String label, String value) {
    return Builder(
      builder: (context) => ListTile(
        title: Text(label),
        onTap: () => Navigator.pop(context, value),
      ),
    );
  }
}
