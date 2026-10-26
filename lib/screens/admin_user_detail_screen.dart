import 'package:flutter/material.dart';
import '../community_store.dart';
import '../widgets/app_toast.dart';
import '../widgets/app_top_bar.dart';

/// 用户详情（仅管理员）：发帖、评论、被举报、等级、状态一目了然；
/// 在这里改角色、禁言（含时长）、封禁。
class AdminUserDetailScreen extends StatelessWidget {
  final CommunityAccount account;
  const AdminUserDetailScreen({super.key, required this.account});

  String _roleLabel(String role) {
    if (role == 'admin') return '管理员';
    if (role == 'moderator') return '版主';
    return '普通用户';
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

  Future<void> _mute(BuildContext context, CommunityAccount a) async {
    final choice = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('禁言多久？'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
                title: const Text('1 天'),
                onTap: () => Navigator.pop(d, '1')),
            ListTile(
                title: const Text('7 天'),
                onTap: () => Navigator.pop(d, '7')),
            ListTile(
                title: const Text('30 天'),
                onTap: () => Navigator.pop(d, '30')),
            ListTile(
                title: const Text('永久'),
                onTap: () => Navigator.pop(d, 'forever')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(d),
              child: const Text('取消')),
        ],
      ),
    );
    if (choice == null || !context.mounted) return;
    DateTime? until;
    if (choice != 'forever') {
      until = DateTime.now().add(Duration(days: int.parse(choice)));
    }
    final err =
        communityStore.setUserStatus(a, 'muted', mutedUntil: until);
    if (context.mounted) showAppToast(context, err ?? '已禁言');
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final grey = dark ? const Color(0xFF8A8578) : const Color(0xFF9A917F);
    return Scaffold(
      appBar: const SubPageAppBar(title: '用户详情'),
      body: AnimatedBuilder(
        animation: communityStore,
        builder: (_, __) {
          final a = communityStore.findAccount(account.id) ?? account;
          final myPosts =
              communityStore.posts.where((p) => p.authorId == a.id).toList();
          var myComments = 0;
          for (final p in communityStore.posts) {
            myComments +=
                p.comments.where((c) => c.authorId == a.id).length;
          }
          final reportedMine =
              myPosts.where((p) => p.reported).length;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  communityAvatar(
                    bytes: a.avatarBytes,
                    color: a.avatarColor,
                    nickname: a.nickname,
                    radius: 28,
                    frame: a.avatarFrame,
                    verified: isSpecialAccount(a),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.nickname,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18)),
                        Text('ID ${a.id} · ${_roleLabel(a.role)}',
                            style: TextStyle(color: grey, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _row('状态', _statusLabel(a)),
              _row('等级', 'LV${a.level} · ${a.tierName}'),
              _row('经验', '${a.totalXp} XP'),
              _row('发帖', '${myPosts.length} 条'),
              _row('评论', '$myComments 条'),
              _row('被举报帖子', '$reportedMine 条'),
              _row('收藏', '${a.collection.length} 把'),
              _row('靶场成绩', '${a.rangeScores.length} 条'),
              _row('注册时间',
                  a.createdAt == null ? '未记录' : a.createdAt.toString().substring(0, 10)),
              if (a.bio.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('简介：${a.bio}',
                    style: TextStyle(color: grey, fontSize: 13)),
              ],
              const SizedBox(height: 20),
              const Text('管理操作',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                      onPressed: () {
                        final err =
                            communityStore.setUserRole(a, 'user');
                        if (context.mounted) {
                          showAppToast(context, err ?? '已设为普通用户');
                        }
                      },
                      child: const Text('设为普通用户')),
                  OutlinedButton(
                      onPressed: () {
                        final err =
                            communityStore.setUserRole(a, 'moderator');
                        if (context.mounted) {
                          showAppToast(context, err ?? '已设为版主');
                        }
                      },
                      child: const Text('设为版主')),
                  OutlinedButton(
                      onPressed: () {
                        final err =
                            communityStore.setUserRole(a, 'admin');
                        if (context.mounted) {
                          showAppToast(context, err ?? '已设为管理员');
                        }
                      },
                      child: const Text('设为管理员')),
                  OutlinedButton(
                      onPressed: () => _mute(context, a),
                      child: const Text('禁言')),
                  if (a.status == 'muted')
                    OutlinedButton(
                        onPressed: () {
                          final err = communityStore.setUserStatus(
                              a, 'active');
                          if (context.mounted) {
                            showAppToast(context, err ?? '已解除禁言');
                          }
                        },
                        child: const Text('解除禁言')),
                  OutlinedButton(
                      style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red),
                      onPressed: () {
                        final err = communityStore.setUserStatus(
                            a, a.status == 'banned' ? 'active' : 'banned');
                        if (context.mounted) {
                          showAppToast(context, err ?? '已更新');
                        }
                      },
                      child: Text(a.status == 'banned' ? '解除封禁' : '封禁')),
                ],
              ),
              const SizedBox(height: 8),
              Text('禁言到期后自动恢复正常，无需手动解除；创始账号与初始管理员不受禁言封禁限制。',
                  style: TextStyle(color: grey, fontSize: 12)),
            ],
          );
        },
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
              width: 80,
              child: Text(label,
                  style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
