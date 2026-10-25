import 'package:flutter/material.dart';
import '../community_store.dart';
import '../i18n.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/level_badge.dart';
import 'community_account_dialogs.dart';
import 'community_collection_screen.dart';
import 'community_dm_screen.dart';
import 'community_notifications_screen.dart';
import 'community_profile_screen.dart';
import 'community_range_screen.dart';
import 'community_tasks_screen.dart';
import 'settings_screen.dart';

/// 我的 Tab：个人中心入口。登录后显示头像、等级铭牌、赛季声望与统计，
/// 下分我的主页、收藏柜、靶场成绩、任务、设置；未登录时显示登录/注册。
class MyScreen extends StatelessWidget {
  const MyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: communityStore,
      builder: (_, __) {
        final me = communityStore.current;
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: const GunsMapAppBar(),
          body: ListView(
            padding: EdgeInsets.fromLTRB(
                16,
                MediaQuery.of(context).padding.top + kToolbarHeight + 16,
                16,
                16),
            children: [
              const Text('我的',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              if (me == null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tr('not_logged'),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(tr('not_logged_sub'),
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () => showLoginDialog(context),
                              child: Text(tr('login')),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: () => showRegisterDialog(context),
                              child: Text(tr('register')),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                Row(
                  children: [
                    communityAvatar(
                      bytes: me.avatarBytes,
                      color: me.avatarColor,
                      nickname: me.nickname,
                      radius: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(me.nickname,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 8),
                              LevelBadge(account: me),
                            ],
                          ),
                          Text('${tr('id_field')}：${me.id}',
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12)),
                          Text(
                              '赛季声望 ${communityStore.seasonPrestige(me)} · 还剩 ${communityStore.seasonRemainingDays} 天',
                              style: const TextStyle(
                                  color: Color(0xFFE86A1C),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                          if (me.bio.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(me.bio),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Builder(builder: (_) {
                  final myPosts = communityStore.posts
                      .where((p) => p.authorId == me.id)
                      .length;
                  final myFavorites = communityStore.posts
                      .where((p) => p.favoritedBy.contains(me.id))
                      .length;
                  final earned =
                      communityStore.earnedMedals(me).length;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _Stat('发帖', '$myPosts'),
                      _Stat('收藏', '$myFavorites'),
                      _Stat('勋章', '$earned/${medalCatalog.length}'),
                      _Stat('藏枪', '${me.collection.length}'),
                    ],
                  );
                }),
                const SizedBox(height: 16),
                _MenuTile(
                  icon: Icons.person_outlined,
                  title: '我的主页',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            CommunityProfileScreen(account: me)),
                  ),
                ),
                Builder(builder: (_) {
                  final unread = communityStore.unreadCount(me.id);
                  final unreadDm = communityStore
                      .notificationsFor(me.id)
                      .where((n) => n.kind == 'dm' && !n.read)
                      .length;
                  return Column(
                    children: [
                      _MenuTile(
                        icon: Icons.notifications_outlined,
                        title: '通知',
                        badge: unread,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const CommunityNotificationsScreen()),
                        ),
                      ),
                      _MenuTile(
                        icon: Icons.mail_outlined,
                        title: '私信',
                        badge: unreadDm,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const CommunityDmScreen()),
                        ),
                      ),
                    ],
                  );
                }),
                _MenuTile(
                  icon: Icons.inventory_2_outlined,
                  title: '我的收藏柜',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            const CommunityCollectionScreen()),
                  ),
                ),
                _MenuTile(
                  icon: Icons.gps_fixed,
                  title: '靶场成绩',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const CommunityRangeScreen()),
                  ),
                ),
                _MenuTile(
                  icon: Icons.task_alt_outlined,
                  title: '任务',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const CommunityTasksScreen()),
                  ),
                ),
                _MenuTile(
                  icon: Icons.settings_outlined,
                  title: '设置',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const SettingsScreen()),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final int badge;
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF8C6A2F)),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: badge > 0
            ? Badge(
                label: Text('$badge'),
                backgroundColor: const Color(0xFFE86A1C),
                child: const Icon(Icons.chevron_right),
              )
            : const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
