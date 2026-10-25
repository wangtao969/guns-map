import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../community_store.dart';
import '../i18n.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/community_theme.dart';
import '../widgets/level_badge.dart';
import 'community_account_dialogs.dart';
import 'community_board_screen.dart';
import 'community_compose_screen.dart';
import 'community_leaderboard_screen.dart';
import 'community_onboarding_screen.dart';
import 'community_post_detail_screen.dart';
import 'community_profile_screen.dart';
import 'community_tasks_screen.dart';

/// 社区页（1.9.0 重构）：
/// 顶部两个入口：动态 / 社区，切换带淡入滑动动画。
/// - 动态：关注的人 + 全站用户的微博式图文分享（最新 / 推荐 / 关注三档）。
/// - 社区：板块入口、平台活动预留、排行榜、任务区、热聊板块、其它板块。
/// 个人资料块已拿掉（入口在“我的”Tab，通知 / 私信也随之挪过去）；
/// 收藏柜只在“我的”页，不再出现在这里。
/// 数据保存在本机（见 community_store.dart），调试提示只在 debug 构建显示。
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  String _view = 'feed'; // feed 动态 / home 社区
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

  Future<void> _openComposer() async {
    if (communityStore.current == null) {
      askLoginDialog(context);
      return;
    }
    final autoChecked = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CommunityComposeScreen()),
    );
    if (autoChecked == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('发布成功，已自动签到')),
      );
    }
  }

  void _openDraft() {
    if (communityStore.draft == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('暂无草稿')),
      );
      return;
    }
    _openComposer();
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

  int _boardCount(String board) =>
      communityStore.posts.where((p) => p.board == board).length;

  void _openBoard(String board) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CommunityBoardScreen(board: board)),
    );
  }

  void _showEventSoon() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('平台活动'),
        content: const Text('平台活动随线上版上线，敬请期待。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
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

  Widget _sectionTitle(String title, {VoidCallback? onViewAll}) {
    return Row(
      children: [
        Text(title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        const Spacer(),
        if (onViewAll != null)
          TextButton(onPressed: onViewAll, child: const Text('查看全部')),
      ],
    );
  }

  Widget _topSwitch() {
    const bronze = Color(0xFF6B5B3E);
    Widget tab(IconData icon, String label, String view) {
      final selected = _view == view;
      return Expanded(
        child: InkWell(
          onTap: () => setState(() => _view = view),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: selected ? bronze : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    size: 18,
                    color: selected ? Colors.white : null),
                const SizedBox(width: 6),
                Text(label,
                    style: TextStyle(
                        color: selected ? Colors.white : null,
                        fontWeight: selected
                            ? FontWeight.bold
                            : FontWeight.normal)),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          tab(Icons.dynamic_feed_outlined, '动态', 'feed'),
          tab(Icons.forum_outlined, '社区', 'home'),
        ],
      ),
    );
  }

  Widget _feedView(CommunityAccount? current, Color grey) {
    final feed = _feedPosts(current);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
      children: [
        if (!kReleaseMode) ...[
          Text(tr('community_note'),
              style: TextStyle(color: grey, fontSize: 12)),
          const SizedBox(height: 10),
        ],
        // 搜索收进小药丸，点击展开输入框；发动态与草稿箱在右下角小圆钮。
        InkWell(
          onTap: () => setState(() => _showSearch = !_showSearch),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, size: 18),
                const SizedBox(width: 8),
                Text('搜索帖子标题、内容、话题',
                    style: TextStyle(color: grey, fontSize: 13)),
                const Spacer(),
                if (_showSearch) const Icon(Icons.close, size: 18),
              ],
            ),
          ),
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
                      borderRadius: BorderRadius.all(Radius.circular(20)),
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
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _boardGridItem(String board, Color grey) {
    final count = _boardCount(board);
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => _openBoard(board),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 44,
                child: Image.asset(boardCover(board), fit: BoxFit.contain),
              ),
              const SizedBox(height: 6),
              Text(board,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13)),
              Text('$count 帖', style: TextStyle(color: grey, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _eventRow(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF8C6A2F), width: 1.5),
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF8C6A2F)),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: communityAccent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text('敬请期待',
            style: TextStyle(
                color: communityAccent,
                fontSize: 12,
                fontWeight: FontWeight.bold)),
      ),
      onTap: _showEventSoon,
    );
  }

  Widget _rankNumber(int rank) {
    final color = rank == 1
        ? const Color(0xFFD4AF37)
        : rank == 2
            ? const Color(0xFF9AA0A6)
            : rank == 3
                ? const Color(0xFFCD7F32)
                : Colors.grey;
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: Text('$rank',
          style: const TextStyle(
              color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _rankingSection(CommunityAccount? current, Color grey) {
    final accounts = communityStore.accounts.toList();
    accounts.sort((a, b) => b.totalXp.compareTo(a.totalXp));
    final boards = communityBoards.toList();
    boards.sort((a, b) =>
        communityStore.boardHeat(b).compareTo(communityStore.boardHeat(a)));
    int? myRank;
    if (current != null) {
      final i = accounts.indexWhere((a) => a.id == current.id);
      if (i >= 0) myRank = i + 1;
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (current != null && myRank != null) ...[
              Row(
                children: [
                  communityAvatar(
                    bytes: current.avatarBytes,
                    color: current.avatarColor,
                    nickname: current.nickname,
                    radius: 16,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('我的排名：本机第 $myRank 名',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  LevelBadge(account: current),
                ],
              ),
              const Divider(height: 24),
            ],
            const Text('经验榜',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            if (accounts.isEmpty)
              Text('暂无本机账号，注册后参与排行',
                  style: TextStyle(color: grey, fontSize: 13))
            else
              for (var i = 0; i < accounts.length && i < 3; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      _rankNumber(i + 1),
                      const SizedBox(width: 10),
                      communityAvatar(
                        bytes: accounts[i].avatarBytes,
                        color: accounts[i].avatarColor,
                        nickname: accounts[i].nickname,
                        radius: 14,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(accounts[i].nickname,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Text('经验 ${accounts[i].totalXp}',
                          style: TextStyle(color: grey, fontSize: 12)),
                    ],
                  ),
                ),
            const Divider(height: 24),
            const Text('板块热度榜',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            for (var i = 0; i < boards.length && i < 3; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    _rankNumber(i + 1),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color(0xFF8C6A2F), width: 1.5),
                      ),
                      child: Icon(boardIcon(boards[i]),
                          size: 14, color: const Color(0xFF8C6A2F)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(boards[i],
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Text(
                        '${_boardCount(boards[i])} 帖 · 热度 ${communityStore.boardHeat(boards[i])}',
                        style: TextStyle(color: grey, fontSize: 12)),
                  ],
                ),
              ),
            Text('本机排行榜，仅含本机注册账号',
                style: TextStyle(color: grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  /// 签到区：做小一点、暗红色，放在活动下面。
  Widget _tasksSection(CommunityAccount? current, Color grey) {
    const darkRed = Color(0xFF8B1E1E);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (current == null)
              Row(
                children: [
                  Expanded(
                    child: Text('登录后参与每日签到与任务',
                        style: TextStyle(color: grey)),
                  ),
                  TextButton(
                    onPressed: () => showLoginDialog(context),
                    child: Text(tr('login')),
                  ),
                ],
              )
            else ...[
              XpProgressRow(
                account: current,
                accent: darkRed,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const CommunityTasksScreen()),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _checkIn,
                      icon: Icon(
                          current.checkedInToday
                              ? Icons.check_circle
                              : Icons.event_available_outlined,
                          size: 18),
                      label: Text(current.checkedInToday
                          ? '已签到 · 连签 ${current.checkInStreak} 天'
                          : '每日签到'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: darkRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CommunityTasksScreen()),
                      ),
                      child: const Text('查看任务'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _homeView(CommunityAccount? current, Color grey) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle('平台活动'),
        const SizedBox(height: 10),
        Card(
          child: Column(
            children: [
              _eventRow(Icons.emoji_events_outlined, '晒枪大赛', '全站晒枪主题活动'),
              const Divider(height: 1),
              _eventRow(Icons.calendar_month_outlined, '每月主题', '每月一期枪械主题讨论'),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _sectionTitle('签到'),
        const SizedBox(height: 10),
        _tasksSection(current, grey),
        const SizedBox(height: 20),
        _sectionTitle('全部板块'),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.95,
          children: [
            for (final b in communityBoards) _boardGridItem(b, grey),
          ],
        ),
        const SizedBox(height: 20),
        _sectionTitle('排行榜', onViewAll: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const CommunityLeaderboardScreen()),
          );
        }),
        const SizedBox(height: 10),
        _rankingSection(current, grey),
        const SizedBox(height: 8),
      ],
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
          return Scaffold(
            extendBodyBehindAppBar: true,
            appBar: const GunsMapAppBar(),
            body: Padding(
              padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + kToolbarHeight),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: _topSwitch(),
                  ),
                Expanded(
                  child: Stack(
                    children: [
                      AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeIn,
                    // 只淡入，不上下滑动：上下一震的动效就是这里的 Slide 造成的。
                    transitionBuilder: (child, anim) =>
                        FadeTransition(opacity: anim, child: child),
                    child: KeyedSubtree(
                      key: ValueKey(_view),
                      child: _view == 'feed'
                          ? _feedView(current, grey)
                          : _homeView(current, grey),
                    ),
                  ),
                      // 动态页右下角小圆钮：上面草稿箱、下面发动态。
                      if (_view == 'feed')
                        Positioned(
                          right: 16,
                          bottom: 16,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FloatingActionButton.small(
                                heroTag: 'draft',
                                onPressed: _openDraft,
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF6B5B3E),
                                child: const Icon(Icons.drafts_outlined,
                                    size: 20),
                              ),
                              const SizedBox(height: 10),
                              FloatingActionButton.small(
                                heroTag: 'compose',
                                onPressed: _openComposer,
                                backgroundColor: const Color(0xFF6B5B3E),
                                foregroundColor: Colors.white,
                                child: const Icon(Icons.edit_outlined,
                                    size: 20),
                              ),
                            ],
                          ),
                        ),
                    ],
                ),
                ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
