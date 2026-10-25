import 'package:flutter/material.dart';
import '../community_store.dart';
import '../i18n.dart';
import '../widgets/app_top_bar.dart';
import 'community_compose_screen.dart';
import 'community_post_detail_screen.dart';
import 'community_profile_screen.dart';

/// 板块论坛页：点板块大卡片进来后的帖子列表，像论坛主题帖一样排。
/// board 为 '全部' 时显示全部帖子；支持站内搜索、最新/最热排序、话题筛选。
class CommunityBoardScreen extends StatefulWidget {
  final String board;
  final String initialQuery;
  final String? initialTag;
  const CommunityBoardScreen({
    super.key,
    required this.board,
    this.initialQuery = '',
    this.initialTag,
  });

  @override
  State<CommunityBoardScreen> createState() => _CommunityBoardScreenState();
}

class _CommunityBoardScreenState extends State<CommunityBoardScreen> {
  late String _query;
  String _sort = 'time'; // time 最新 / hot 最热
  String? _tag;
  final _expandedReported = <String>{};
  late final TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery;
    _tag = widget.initialTag;
    _searchCtrl = TextEditingController(text: widget.initialQuery);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<CommunityPost> _visiblePosts() {
    var list = communityStore.posts.where((p) {
      if (widget.board != '全部' && p.board != widget.board) return false;
      if (_tag != null && !p.tags.contains(_tag)) return false;
      if (_query.isNotEmpty) {
        final q = _query.toLowerCase();
        if (!p.title.toLowerCase().contains(q) &&
            !p.content.toLowerCase().contains(q) &&
            !p.tags.any((t) => t.toLowerCase().contains(q))) {
          return false;
        }
      }
      return true;
    }).toList();
    final pinned = list.where((p) => p.pinned).toList();
    final rest = list.where((p) => !p.pinned).toList();
    if (_sort == 'hot') {
      rest.sort((a, b) => b.hotScore.compareTo(a.hotScore));
    } else {
      rest.sort((a, b) => b.time.compareTo(a.time));
    }
    return [...pinned, ...rest];
  }

  void _openComposer() {
    if (communityStore.current == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('login_required_body'))),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CommunityComposeScreen()),
    );
  }

  Widget _threadRow(CommunityPost p, Color grey) {
    return _ThreadRow(
      post: p,
      grey: grey,
      showBoard: widget.board == '全部',
      reportedExpanded: _expandedReported.contains(p.id),
      onExpandReported: () => setState(() => _expandedReported.add(p.id)),
      onOpen: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => CommunityPostDetailScreen(post: p)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final grey = dark ? const Color(0xFF8A8578) : const Color(0xFF9A917F);
    return AnimatedBuilder(
      animation: communityStore,
      builder: (_, __) {
        final visible = _visiblePosts();
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
                    child: Text(
                      widget.board == '全部'
                          ? '全部帖子'
                          : widget.board,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _openComposer,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: Text(tr('post_new')),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 板块头：贴吧式板块信息区（图标、简介、帖子数）。
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(_boardIcon(widget.board),
                          size: 28, color: const Color(0xFF8C6A2F)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.board == '全部' ? '全部帖子' : widget.board,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _boardDescription(widget.board),
                              style:
                                  TextStyle(color: grey, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      Text('${visible.length} 帖',
                          style: TextStyle(color: grey, fontSize: 12)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v.trim()),
                decoration: const InputDecoration(
                  hintText: '搜索本板块的帖子标题、内容、话题',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('最新'),
                    selected: _sort == 'time',
                    onSelected: (_) => setState(() => _sort = 'time'),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('最热'),
                    selected: _sort == 'hot',
                    onSelected: (_) => setState(() => _sort = 'hot'),
                  ),
                  if (_tag != null) ...[
                    const SizedBox(width: 8),
                    InputChip(
                      label: Text('#$_tag#'),
                      onDeleted: () => setState(() => _tag = null),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              if (visible.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.forum_outlined, size: 48, color: grey),
                        const SizedBox(height: 12),
                        Text(tr('no_posts'),
                            style: TextStyle(color: grey)),
                        const SizedBox(height: 4),
                        Text(tr('no_posts_sub'),
                            style: TextStyle(color: grey, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              // 置顶帖单独成区（贴吧/虎扑式），其余是全部主题。
              if (visible.any((p) => p.pinned)) ...[
                const _SectionLabel('置顶'),
                ...visible
                    .where((p) => p.pinned)
                    .map((p) => _threadRow(p, grey)),
                const _SectionLabel('全部主题'),
                ...visible
                    .where((p) => !p.pinned)
                    .map((p) => _threadRow(p, grey)),
              ] else
                ...visible.map((p) => _threadRow(p, grey)),
            ],
          ),
        );
      },
    );
  }
}

/// 论坛主题行：头像 + 标题 + 摘要 + 作者时间 + 回复点赞数，右侧有图时配缩略图。
class _ThreadRow extends StatelessWidget {
  final CommunityPost post;
  final Color grey;
  final bool showBoard;
  final bool reportedExpanded;
  final VoidCallback onExpandReported;
  final VoidCallback onOpen;
  const _ThreadRow({
    required this.post,
    required this.grey,
    required this.showBoard,
    required this.reportedExpanded,
    required this.onExpandReported,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final p = post;
    final reportedHidden = p.reported && !reportedExpanded;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: reportedHidden ? onExpandReported : onOpen,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  final account = communityStore.findAccount(p.authorId);
                  if (account != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              CommunityProfileScreen(account: account)),
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
                    if (reportedHidden)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: grey.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('该帖已被举报，待审核，点击查看原文'),
                      )
                    else ...[
                      Row(
                        children: [
                          Expanded(
                            child: Text(p.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15)),
                          ),
                          if (p.pinned) ...[
                            const SizedBox(width: 6),
                            const _Badge('置顶', Colors.red),
                          ],
                          if (p.essence) ...[
                            const SizedBox(width: 6),
                            const _Badge('精华', Colors.amber),
                          ],
                          if (p.reported) ...[
                            const SizedBox(width: 6),
                            const _Badge('已举报', Colors.orange),
                          ],
                        ],
                      ),
                      if (p.content.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          p.content,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: grey, fontSize: 13),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${p.authorNickname} · ${CommunityStore.formatTime(p.time)}${showBoard ? ' · ${p.board}' : ''}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  TextStyle(color: grey, fontSize: 12),
                            ),
                          ),
                          Text(
                            '回复 ${p.comments.length} · 点赞 ${p.likedBy.length}',
                            style: TextStyle(color: grey, fontSize: 12),
                          ),
                        ],
                      ),
                      // 论坛式最后回复行：最后一条评论的作者和时间。
                      if (p.comments.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          '最后回复 ${p.comments.last.authorNickname} · ${CommunityStore.formatTime(p.comments.last.time)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: grey, fontSize: 12),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              if (!reportedHidden && p.images.isNotEmpty) ...[
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
}

/// 分区小标题：置顶 / 全部主题。
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Text(text,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8C6A2F))),
    );
  }
}

/// 板块简介（板块头用）。
String _boardDescription(String board) {
  switch (board) {
    case '全部':
      return '全部板块的帖子汇总';
    case '晒枪':
      return '晒出你的装备与收藏';
    case '复装心得':
      return '装药、弹头、工具的实战经验';
    case '求助问答':
      return '新手提问，老手解答';
    case '资讯':
      return '行业新闻与新品动态';
    case '枪械评测':
      return '对着图鉴写评测';
    case '新手入门':
      return '从零开始的入门指南';
    case '配件分享':
      return '瞄具、握把、枪灯的搭配与测评';
    case '射击技巧':
      return '姿势、归零、靶场经验';
    case '历史名枪':
      return '名枪背后的历史与故事';
    case '靶场日记':
      return '打靶记录与日常';
    default:
      return '什么都能聊的综合区';
  }
}

IconData _boardIcon(String board) {
  switch (board) {
    case '全部':
      return Icons.forum_outlined;
    case '晒枪':
      return Icons.photo_camera_outlined;
    case '复装心得':
      return Icons.build_outlined;
    case '求助问答':
      return Icons.help_outline;
    case '资讯':
      return Icons.newspaper_outlined;
    case '枪械评测':
      return Icons.rate_review_outlined;
    case '新手入门':
      return Icons.school_outlined;
    case '配件分享':
      return Icons.widgets_outlined;
    case '射击技巧':
      return Icons.gps_fixed;
    case '历史名枪':
      return Icons.history;
    case '靶场日记':
      return Icons.book_outlined;
    default:
      return Icons.forum_outlined;
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text,
          style: const TextStyle(color: Colors.white, fontSize: 10)),
    );
  }
}
