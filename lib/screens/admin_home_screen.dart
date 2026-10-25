import 'package:flutter/material.dart';
import '../community_store.dart';
import '../widgets/app_top_bar.dart';
import 'admin_config_screen.dart';
import 'admin_personnel_screen.dart';
import 'admin_review_screen.dart';

/// 后台首页：仅管理员 / 版主可见（入口在“我的”页，登录态决定）。
/// 本地版：数据只保存在本机；正式版接服务器后由服务器验权与同步。
class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final grey = dark ? const Color(0xFF8A8578) : const Color(0xFF9A917F);
    return Scaffold(
      appBar: const SubPageAppBar(title: '后台管理'),
      body: AnimatedBuilder(
        animation: communityStore,
        builder: (_, __) {
          final isAdmin = communityStore.isAdmin;
          final posts = communityStore.posts;
          final comments =
              posts.fold<int>(0, (sum, p) => sum + p.comments.length);
          final reported = posts.where((p) => p.reported).length;
          final announcements = communityStore.notifications
              .where((n) => n.kind == 'system')
              .length;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    '本地版后台：数据只保存在本机，正式版接服务器后由服务器验权与同步。初始管理员为 ID 为 10000 的账号（旧版 wangtao969 账号仍可进后台）；管理员可任命其他管理员与版主。',
                    style: TextStyle(color: grey, fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 1.6,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [
                  _stat('注册用户', '${communityStore.accounts.length}'),
                  _stat('帖子', '${posts.length}'),
                  _stat('评论', '$comments'),
                  _stat('被举报帖子', '$reported'),
                  _stat('系统公告', '$announcements'),
                  _stat('赛季剩余', '${communityStore.seasonRemainingDays} 天'),
                ],
              ),
              const SizedBox(height: 16),
              if (isAdmin)
                _entry(context, Icons.people_outlined, '人员管理',
                    '任命版主 / 管理员，禁言、封禁、撤销权限', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AdminPersonnelScreen()),
                  );
                }),
              _entry(context, Icons.report_outlined, '帖子审核', '处理被举报的帖子：恢复、置顶、加精、删除',
                  () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AdminReviewScreen()),
                );
              }),
              if (isAdmin)
                _entry(context, Icons.tune_outlined, '板块 / 赛季 / 公告',
                    '板块开关、赛季长度、发布系统公告', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AdminConfigScreen()),
                  );
                }),
            ],
          );
        },
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Card(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _entry(BuildContext context, IconData icon, String title,
      String subtitle, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF8C6A2F)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
