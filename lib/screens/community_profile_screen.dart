import 'package:flutter/material.dart';
import '../community_store.dart';
import '../i18n.dart';
import '../widgets/app_top_bar.dart';
import 'community_dm_screen.dart';
import 'community_post_detail_screen.dart';

/// 用户主页：简介、发帖历史、收藏、关注/粉丝。
/// 自己的主页全可见；别人的主页：收藏按对方的“收藏对外可见”开关决定是否展示。
class CommunityProfileScreen extends StatelessWidget {
  final CommunityAccount account;
  const CommunityProfileScreen({super.key, required this.account});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final grey = dark ? const Color(0xFF8A8578) : const Color(0xFF9A917F);
    return AnimatedBuilder(
      animation: communityStore,
      builder: (_, __) {
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
        final canSeeFavorites = isMine || account.favoritesPublic;
        return Scaffold(
          appBar: const GunsMapAppBar(),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Expanded(
                    child: Text(isMine ? '我的主页' : account.nickname,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
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
                        Text(account.nickname,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('${tr('id_field')}：${account.id}',
                            style: TextStyle(color: grey, fontSize: 12)),
                        Text(
                            account.role == 'admin'
                                ? '管理员'
                                : account.role == 'moderator'
                                    ? '版主'
                                    : '普通用户',
                            style: TextStyle(color: grey, fontSize: 12)),
                        if (account.bio.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(account.bio),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _Stat('发帖', '${myPosts.length}'),
                  _Stat('关注', '${following.length}'),
                  _Stat('粉丝', '${followers.length}'),
                  _Stat('收藏', canSeeFavorites ? '${myFavorites.length}' : '—'),
                ],
              ),
              const SizedBox(height: 12),
              if (!isMine && me != null) ...[
                Row(
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
                              builder: (_) =>
                                  CommunityDmScreen(peerId: account.id)),
                        ),
                        child: const Text('私信'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              const Text('发帖历史',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              if (myPosts.isEmpty)
                Text('还没有发过帖子', style: TextStyle(color: grey)),
              ...myPosts.map((p) => ListTile(
                    title: Text(p.title),
                    subtitle: Text(
                        '${p.board} · ${CommunityStore.formatTime(p.time)} · ${p.likedBy.length}赞 ${p.comments.length}评'),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              CommunityPostDetailScreen(post: p)),
                    ),
                  )),
              const SizedBox(height: 16),
              const Text('收藏',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              if (!canSeeFavorites)
                Text('对方设置了收藏不对外可见', style: TextStyle(color: grey)),
              if (canSeeFavorites && myFavorites.isEmpty)
                Text('还没有收藏', style: TextStyle(color: grey)),
              if (canSeeFavorites)
                ...myFavorites.map((p) => ListTile(
                      title: Text(p.title),
                      subtitle: Text(
                          '${p.authorNickname} · ${p.board} · ${CommunityStore.formatTime(p.time)}'),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                CommunityPostDetailScreen(post: p)),
                      ),
                    )),
              const SizedBox(height: 16),
              const Text('关注列表',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              if (following.isEmpty)
                Text('还没有关注任何人', style: TextStyle(color: grey)),
              ...following.map((a) => ListTile(
                    leading: communityAvatar(
                      bytes: a.avatarBytes,
                      color: a.avatarColor,
                      nickname: a.nickname,
                      radius: 16,
                    ),
                    title: Text(a.nickname),
                    subtitle: Text('${tr('id_field')}：${a.id}'),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              CommunityProfileScreen(account: a)),
                    ),
                  )),
              const SizedBox(height: 16),
              const Text('粉丝列表',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              if (followers.isEmpty)
                Text('还没有粉丝', style: TextStyle(color: grey)),
              ...followers.map((a) => ListTile(
                    leading: communityAvatar(
                      bytes: a.avatarBytes,
                      color: a.avatarColor,
                      nickname: a.nickname,
                      radius: 16,
                    ),
                    title: Text(a.nickname),
                    subtitle: Text('${tr('id_field')}：${a.id}'),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              CommunityProfileScreen(account: a)),
                    ),
                  )),
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
