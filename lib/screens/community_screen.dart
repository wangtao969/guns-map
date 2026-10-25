import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../community_store.dart';
import '../i18n.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/community_theme.dart';
import '../widgets/level_badge.dart';
import 'community_account_dialogs.dart';
import 'community_board_screen.dart';
import 'community_collection_screen.dart';
import 'community_compose_screen.dart';
import 'community_dm_screen.dart';
import 'community_notifications_screen.dart';
import 'community_onboarding_screen.dart';
import 'community_post_detail_screen.dart';
import 'community_profile_screen.dart';
import 'community_tasks_screen.dart';

/// 社区首屏（P0 重构后）：
/// 顶部一行用户卡（头像 + LV + 铭牌 + 搜索/通知/私信）→ 经验条 →
/// 发动态 / 每日签到双行动 → 内容流（最新 / 推荐 / 关注）→ 横滑板块入口。
/// 数据保存在本机（见 community_store.dart），调试提示只在 debug 构建显示。
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  String _feedTab = 'latest'; // latest 最新 / hot 推荐 / following 关注
  bool _showSearch = false;
  bool _onboardingShown = false;
  late final TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _maybeOnboarding(CommunityAccount? current) {
    if (current == null || current.onboarded || _onboardingShown) return;
    _onboardingShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CommunityOnboardingScreen()),
      );
    });
  }

  void _openComposer() {
    if (communityStore.current == null) {
      askLoginDialog(context);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CommunityComposeScreen()),
    );
  }

  void _search(String q) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) =>
              CommunityBoardScreen(board: '全部', initialQuery: q.trim())),
    );
  }

  void _checkIn() {
    final me = communityStore.current;
    if (me == null) {
      askLoginDialog(context);
      return;
    }
    final granted = communityStore.checkIn();
    if (granted < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('今天已经签到过了，连签 ${me.checkInStreak} 天')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(granted > 0
              ? '签到成功 +$granted 经验，连签 ${me.checkInStreak} 天'
              : '签到成功，连签 ${me.checkInStreak} 天')),
    );
  }

  List<CommunityPost> _feedPosts(CommunityAccount? me) {
    final all = communityStore.posts;
    switch (_feedTab) {
      case 'hot':
        final list = all.toList();
        list.sort((a, b) {
          final ea = a.essence ? 1 : 0;
          final eb = b.essence ? 1 : 0;
          if (eb != ea) return eb - ea;
          return b.hotScore.compareTo(a.hotScore);
        });
        return list;
      case 'following':
        if (me == null) return [];
        final list = all
            .where((p) =>
                me.followedBoards.contains(p.board) ||
                me.followingIds.contains(p.authorId))
            .toList();
        list.sort((a, b) => b.time.compareTo(a.time));
        return list;
      default:
        final list = all.toList();
        list.sort((a, b) => b.time.compareTo(a.time));
        return list;
    }
  }

  Widget _segTab(String label, bool selected, VoidCallback onTap) {
    const bronze = Color(0xFF6B5B3E);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? bronze : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: selected
                    ? bronze
                    : Colors.grey.withValues(alpha: 0.4)),
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                    color: selected ? Colors.white : null,
                    fontWeight:
                        selected ? FontWeight.bold : FontWeight.normal)),
          ),
        ),
      ),
    );
  }

  Widget _postCard(CommunityPost p, Color grey) {
    final authorAccount = communityStore.findAccount(p.authorId);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => CommunityPostDetailScreen(post: p)),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  if (authorAccount != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => CommunityProfileScreen(
                              account: authorAccount)),
                    );
                  }
                },
                child: communityAvatar(
                  bytes: p.authorAvatar,
                  color: p.authorColor,
                  nickname: p.authorNickname,
                  radius: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(p.authorNickname,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                        ),
                        if (authorAccount != null) ...[
                          const SizedBox(width: 6),
                          LevelBadge(account: authorAccount),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(p.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    if (p.content.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(p.content,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: grey, fontSize: 13)),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      '${CommunityStore.formatTime(p.time)} · ${p.board} · 回复 ${p.comments.length} · 点赞 ${p.likedBy.length}',
                      style: TextStyle(color: grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (p.images.isNotEmpty) ...[
                const SizedBox(width: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    p.images.first,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _boardChip(String board, int count, String? latest, Color grey) {
    final latestPost = communityStore.posts
        .where((p) => board == '全部' || p.board == board)
        .toList();
    latestPost.sort((a, b) => b.time.compareTo(a.time));
    final cover = latestPost.isNotEmpty && latestPost.first.images.isNotEmpty
        ? null
        : boardCover(board);
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 10),
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => CommunityBoardScreen(board: board)),
          ),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 56,
                  width: double.infinity,
                  child: cover != null
                      ? Image.asset(cover, fit: BoxFit.contain)
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            latestPost.first.images.first,
                            fit: BoxFit.cover,
                          ),
                        ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color(0xFF8C6A2F), width: 1.5),
                      ),
                      child: Icon(boardIcon(board),
                          size: 14, color: const Color(0xFF8C6A2F)),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(board,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('$count 帖',
                    style: TextStyle(color: grey, fontSize: 12)),
                const SizedBox(height: 2),
                if (latest != null)
                  Text('最新：$latest',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: grey, fontSize: 12))
                else
                  TextButton(
                    style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 28),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    onPressed: _openComposer,
                    child: const Text('来发第一条', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final grey = communitySecondary(dark);
    return ValueListenableBuilder<String>(
      valueListenable: localeNotifier,
      builder: (_, __, ___) => AnimatedBuilder(
        animation: communityStore,
        builder: (_, __) {
          final current = communityStore.current;
          _maybeOnboarding(current);
          final unread = current == null
              ? 0
              : communityStore.unreadCount(current.id);
          final unreadDm = current == null
              ? 0
              : communityStore
                  .notificationsFor(current.id)
                  .where((n) => n.kind == 'dm' && !n.read)
                  .length;
          final feed = _feedPosts(current);
          return Scaffold(
            appBar: const GunsMapAppBar(),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 顶部一行用户卡：头像 + LV + 铭牌 + 搜索 / 通知 / 私信。
                Row(
                  children: [
                    if (current == null) ...[
                      const CircleAvatar(
                          radius: 20, child: Icon(Icons.person)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(tr('not_logged'),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                      ),
                      TextButton(
                        onPressed: () => showLoginDialog(context),
                        child: Text(tr('login')),
                      ),
                      TextButton(
                        onPressed: () => showRegisterDialog(context),
                        child: Text(tr('register')),
                      ),
                    ] else ...[
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  CommunityProfileScreen(account: current)),
                        ),
                        child: communityAvatar(
                          bytes: current.avatarBytes,
                          color: current.avatarColor,
                          nickname: current.nickname,
                          radius: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => CommunityProfileScreen(
                                    account: current)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(current.nickname,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15)),
                              const SizedBox(height: 2),
                              LevelBadge(account: current),
                            ],
                          ),
                        ),
                      ),
                    ],
                    IconButton(
                      onPressed: () =>
                          setState(() => _showSearch = !_showSearch),
                      icon: const Icon(Icons.search),
                    ),
                    IconButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const CommunityNotificationsScreen()),
                      ),
                      icon: Badge(
                        isLabelVisible: unread > 0,
                        label: Text('$unread'),
                        backgroundColor: communityAccent,
                        child: const Icon(Icons.notifications_outlined),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CommunityDmScreen()),
                      ),
                      icon: Badge(
                        isLabelVisible: unreadDm > 0,
                        label: Text('$unreadDm'),
                        backgroundColor: communityAccent,
                        child: const Icon(Icons.mail_outlined),
                      ),
                    ),
                  ],
                ),
                if (!kReleaseMode) ...[
                  const SizedBox(height: 6),
                  Text(tr('community_note'),
                      style: TextStyle(color: grey, fontSize: 12)),
                ],
                if (current != null) ...[
                  const SizedBox(height: 6),
                  XpProgressRow(
                    account: current,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CommunityTasksScreen()),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                // 两个主行动并排：发动态 + 每日签到。
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _openComposer,
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: Text(communityStore.draft == null
                            ? tr('post_new')
                            : '继续写草稿'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _checkIn,
                        icon: Icon(
                            current != null && current.checkedInToday
                                ? Icons.check_circle
                                : Icons.event_available_outlined,
                            size: 18),
                        label: Text(current != null && current.checkedInToday
                            ? '已签到 · 连签 ${current.checkInStreak} 天'
                            : '每日签到'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: communityAccent,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_showSearch) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          autofocus: true,
                          onSubmitted: _search,
                          decoration: const InputDecoration(
                            hintText: '搜索帖子标题、内容、话题',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(20)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _showSearch = false);
                        },
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                // 内容流三档：最新 / 推荐 / 关注。
                Row(
                  children: [
                    _segTab('最新', _feedTab == 'latest',
                        () => setState(() => _feedTab = 'latest')),
                    const SizedBox(width: 8),
                    _segTab('推荐', _feedTab == 'hot',
                        () => setState(() => _feedTab = 'hot')),
                    const SizedBox(width: 8),
                    _segTab('关注', _feedTab == 'following',
                        () => setState(() => _feedTab = 'following')),
                  ],
                ),
                const SizedBox(height: 12),
                if (feed.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.forum_outlined, size: 48, color: grey),
                          const SizedBox(height: 12),
                          Text(
                            _feedTab == 'following'
                                ? '还没有关注任何板块或用户'
                                : '还没有人晒枪 · 去图鉴选一把，发第一条',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: grey),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: _openComposer,
                            child: const Text('发第一条'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...feed.map((p) => _postCard(p, grey)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('板块',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CommunityTasksScreen()),
                      ),
                      child: const Text('任务'),
                    ),
                    TextButton(
                      onPressed: () {
                        if (current == null) {
                          askLoginDialog(context);
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const CommunityCollectionScreen()),
                        );
                      },
                      child: const Text('我的收藏柜'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 168,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _boardChip(
                        '全部',
                        communityStore.posts.length,
                        communityStore.posts.isEmpty
                            ? null
                            : communityStore.posts.first.title,
                        grey,
                      ),
                      for (final b in communityBoards)
                        _boardChip(
                          b,
                          communityStore.posts
                              .where((p) => p.board == b)
                              .length,
                          communityStore.posts
                                  .where((p) => p.board == b)
                                  .isEmpty
                              ? null
                              : communityStore.posts
                                  .where((p) => p.board == b)
                                  .first
                                  .title,
                          grey,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }
}
