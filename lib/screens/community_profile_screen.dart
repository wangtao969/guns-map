import 'package:flutter/material.dart';
import '../community_store.dart';
import '../i18n.dart';
import '../widgets/community_theme.dart';
import '../widgets/level_badge.dart';
import 'community_account_dialogs.dart';
import 'community_dm_screen.dart';
import 'community_post_detail_screen.dart';

/// 用户主页：头像 + LV + 铭牌 + 统计，下分 帖子 / 收藏 / 勋章墙 / 历史 四栏。
/// 自己的主页全可见；别人的主页：收藏按对方的“收藏对外可见”开关决定是否展示。
class CommunityProfileScreen extends StatefulWidget {
  final CommunityAccount account;
  const CommunityProfileScreen({super.key, required this.account});

  @override
  State<CommunityProfileScreen> createState() =>
      _CommunityProfileScreenState();
}

class _CommunityProfileScreenState extends State<CommunityProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _openPost(CommunityPost p) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CommunityPostDetailScreen(post: p)),
    );
  }

  void _showAccountList(String title, List<CommunityAccount> list) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          child: list.isEmpty
              ? const Text('还没有')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final a = list[i];
                    return ListTile(
                      leading: communityAvatar(
                        bytes: a.avatarBytes,
                        color: a.avatarColor,
                        nickname: a.nickname,
                        radius: 16,
                      ),
                      title: Text(a.nickname),
                      subtitle:
                          Text('${tr('id_field')}：${a.id}'),
                      onTap: () {
                        Navigator.of(dialogContext).pop();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  CommunityProfileScreen(account: a)),
                        );
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(tr('close')),
          ),
        ],
      ),
    );
  }

  Widget _medalWall(CommunityAccount account, Color grey) {
    final earned = communityStore.earnedMedals(account);
    final earnedIds = earned.map((m) => m.id).toSet();
    const groups = ['签到', '收藏', '发帖', '获赞', '靶场', '品类', '赛季', '彩蛋'];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(Icons.emoji_events_outlined,
                    color: communityAccent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '已获得 ${earned.length} / ${medalCatalog.length}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        for (final g in groups) ...[
          Builder(builder: (_) {
            final medals =
                medalCatalog.where((m) => m.group == g).toList();
            final got =
                medals.where((m) => earnedIds.contains(m.id)).length;
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ExpansionTile(
                title: Text('$g（$got/${medals.length}）',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                children: medals.map((m) {
                  final has = earnedIds.contains(m.id);
                  return ListTile(
                    leading: MedalRingBadge(
                        medal: m, earned: has, size: 40),
                    title: Text(m.name,
                        style: TextStyle(
                            color: has ? null : Colors.grey)),
                    subtitle: Text(m.desc,
                        style: TextStyle(
                            color: has ? grey : Colors.grey,
                            fontSize: 12)),
                    trailing: Text(m.rarity,
                        style: TextStyle(
                            color: rarityColor(m.rarity),
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  );
                }).toList(),
              ),
            );
          }),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final grey = communitySecondary(dark);
    return AnimatedBuilder(
      animation: communityStore,
      builder: (_, __) {
        final account = widget.account;
        final me = communityStore.current;
        final isMine = me != null && me.id == account.id;
        final myPosts = communityStore.posts
            .where((p) => p.authorId == account.id)
            .toList();
        final myFavorites = communityStore.posts
            .where((p) => p.favoritedBy.contains(account.id))
            .toList();
        final followers = communityStore.accounts
            .where((a) => a.followingIds.contains(account.id))
            .toList();
        final following = communityStore.accounts
            .where((a) => account.followingIds.contains(a.id))
            .toList();
        final myComments = <({CommunityPost post, CommunityComment comment})>[];
        for (final p in communityStore.posts) {
          for (final c in p.comments) {
            if (c.authorId == account.id) {
              myComments.add((post: p, comment: c));
            }
          }
        }
        myComments.sort((a, b) => b.comment.time.compareTo(a.comment.time));
        final canSeeFavorites = isMine || account.favoritesPublic;
        // 个人资料页不显示应用栏（应用名）和返回箭头：返回走系统返回，
        // 标题只留“我的主页 / 昵称”，不再跟主页面重复。
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(isMine ? '我的主页' : account.nickname,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                      ),
                      if (isMine)
                        TextButton(
                          onPressed: () => showEditProfileDialog(context),
                          child: Text(tr('edit_profile')),
                        ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    communityAvatar(
                      bytes: account.avatarBytes,
                      color: account.avatarColor,
                      nickname: account.nickname,
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
                                child: Text(account.nickname,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 8),
                              LevelBadge(account: account),
                            ],
                          ),
                          Text('${tr('id_field')}：${account.id}',
                              style:
                                  TextStyle(color: grey, fontSize: 12)),
                          Text(
                              account.role == 'admin'
                                  ? '管理员'
                                  : account.role == 'moderator'
                                      ? '版主'
                                      : '普通用户',
                              style:
                                  TextStyle(color: grey, fontSize: 12)),
                          Text(
                              '赛季声望 ${communityStore.seasonPrestige(account)} · 还剩 ${communityStore.seasonRemainingDays} 天',
                              style: TextStyle(
                                  color: communityAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                          if (account.bio.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(account.bio),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _Stat('发帖', '${myPosts.length}', null),
                  _Stat('关注', '${following.length}',
                      () => _showAccountList('关注', following)),
                  _Stat('粉丝', '${followers.length}',
                      () => _showAccountList('粉丝', followers)),
                  _Stat('收藏',
                      canSeeFavorites ? '${myFavorites.length}' : '—', null),
                ],
              ),
              if (!isMine && me != null) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              communityStore.toggleFollow(account.id),
                          child: Text(me.followingIds.contains(account.id)
                              ? '已关注'
                              : '关注'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => CommunityDmScreen(
                                    peerId: account.id)),
                          ),
                          child: const Text('私信'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TabBar(
                controller: _tabs,
                tabs: const [
                  Tab(text: '帖子'),
                  Tab(text: '收藏'),
                  Tab(text: '勋章墙'),
                  Tab(text: '历史'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    // 帖子
                    myPosts.isEmpty
                        ? Center(
                            child: Text('还没有发过帖子',
                                style: TextStyle(color: grey)))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: myPosts.length,
                            itemBuilder: (_, i) {
                              final p = myPosts[i];
                              return ListTile(
                                title: Text(p.title),
                                subtitle: Text(
                                    '${p.board} · ${CommunityStore.formatTime(p.time)} · ${p.likedBy.length}赞 ${p.comments.length}评'),
                                onTap: () => _openPost(p),
                              );
                            },
                          ),
                    // 收藏
                    !canSeeFavorites
                        ? Center(
                            child: Text('对方设置了收藏不对外可见',
                                style: TextStyle(color: grey)))
                        : myFavorites.isEmpty
                            ? Center(
                                child: Text('还没有收藏',
                                    style: TextStyle(color: grey)))
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: myFavorites.length,
                                itemBuilder: (_, i) {
                                  final p = myFavorites[i];
                                  return ListTile(
                                    title: Text(p.title),
                                    subtitle: Text(
                                        '${p.authorNickname} · ${p.board} · ${CommunityStore.formatTime(p.time)}'),
                                    onTap: () => _openPost(p),
                                  );
                                },
                              ),
                    // 勋章墙
                    _medalWall(account, grey),
                    // 历史：我的评论记录
                    myComments.isEmpty
                        ? Center(
                            child: Text('还没有评论记录',
                                style: TextStyle(color: grey)))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: myComments.length,
                            itemBuilder: (_, i) {
                              final entry = myComments[i];
                              return ListTile(
                                title: Text(entry.comment.content),
                                subtitle: Text(
                                    '回复《${entry.post.title}》· ${CommunityStore.formatTime(entry.comment.time)}'),
                                onTap: () => _openPost(entry.post),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ],
          ),
          ),
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;
  const _Stat(this.label, this.value, this.onTap);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
            Text(label,
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
