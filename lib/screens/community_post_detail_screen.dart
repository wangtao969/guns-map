import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../community_store.dart';
import '../i18n.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/community_theme.dart';
import '../widgets/level_badge.dart';
import 'community_board_screen.dart';
import 'community_profile_screen.dart';

/// 帖子详情：完整内容、图片、@高亮、点赞收藏分享、评论列表、底部快捷回复。
/// 作者本人的管理菜单：置顶 / 精华 / 删除；别人的帖子：举报。
class CommunityPostDetailScreen extends StatefulWidget {
  final CommunityPost post;
  const CommunityPostDetailScreen({super.key, required this.post});

  @override
  State<CommunityPostDetailScreen> createState() =>
      _CommunityPostDetailScreenState();
}

class _CommunityPostDetailScreenState
    extends State<CommunityPostDetailScreen> {
  static const _shareChannel = MethodChannel('gunsmap/share');
  final _replyCtrl = TextEditingController();

  @override
  void dispose() {
    _replyCtrl.dispose();
    super.dispose();
  }

  /// 正文渲染：@ID 高亮为加粗棕色，话题保持原文。
  Widget _richContent(String content) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'@([^\s@#]+)');
    var last = 0;
    for (final m in regex.allMatches(content)) {
      if (m.start > last) {
        spans.add(TextSpan(text: content.substring(last, m.start)));
      }
      spans.add(TextSpan(
        text: m.group(0),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF8C6A2F),
        ),
      ));
      last = m.end;
    }
    if (last < content.length) {
      spans.add(TextSpan(text: content.substring(last)));
    }
    return Text.rich(TextSpan(children: spans, style: const TextStyle(fontSize: 15)));
  }

  Future<void> _share() async {
    final p = widget.post;
    final text = '${p.title}\n${p.content}\n—— 来自 Gun’s Map 社区';
    try {
      await _shareChannel.invokeMethod('shareText', {'text': text});
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('分享失败，系统分享通道不可用')),
        );
      }
    }
  }

  void _sendReply() {
    final me = communityStore.current;
    if (me == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('login_required_body'))),
      );
      return;
    }
    final content = _replyCtrl.text.trim();
    if (content.isEmpty) return;
    final err = communityStore.addComment(widget.post, content);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err)),
      );
      return;
    }
    _replyCtrl.clear();
  }

  Future<void> _managementMenu() async {
    final p = widget.post;
    final me = communityStore.current;
    if (me == null) return;
    final isMine = me.id == p.authorId;
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isMine) ...[
              ListTile(
                leading: const Icon(Icons.push_pin_outlined),
                title: Text(p.pinned ? '取消置顶' : '置顶'),
                onTap: () => Navigator.pop(context, 'pin'),
              ),
              ListTile(
                leading: const Icon(Icons.star_outline),
                title: Text(p.essence ? '取消精华' : '设为精华'),
                onTap: () => Navigator.pop(context, 'essence'),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('删除帖子',
                    style: TextStyle(color: Colors.red)),
                onTap: () => Navigator.pop(context, 'delete'),
              ),
            ] else
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: const Text('举报违规内容'),
                onTap: () => Navigator.pop(context, 'report'),
              ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case 'pin':
        communityStore.setPinned(p, !p.pinned);
        break;
      case 'essence':
        communityStore.setEssence(p, !p.essence);
        break;
      case 'delete':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (d) => AlertDialog(
            title: const Text('删除帖子？'),
            content: const Text('删除后本机数据无法恢复。'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(d, false),
                  child: Text(tr('cancel'))),
              TextButton(
                  onPressed: () => Navigator.pop(d, true),
                  child: const Text('删除',
                      style: TextStyle(color: Colors.red))),
            ],
          ),
        );
        if (confirm == true) {
          communityStore.deletePost(p);
          if (mounted) Navigator.of(context).pop();
        }
        break;
      case 'report':
        communityStore.reportPost(p);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已举报，帖子已标记为待审核')),
          );
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final grey = communitySecondary(dark);
    return AnimatedBuilder(
      animation: communityStore,
      builder: (_, __) {
        final p = widget.post;
        final me = communityStore.current;
        final liked = me != null && p.likedBy.contains(me.id);
        final favorited = me != null && p.favoritedBy.contains(me.id);
        final authorAccount = communityStore.findAccount(p.authorId);
        return Scaffold(
          appBar: SubPageAppBar(title: '帖子详情'),
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(
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
                            radius: 20,
                            frame: p.authorFrame,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
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
                              Text(
                                  '${CommunityStore.formatTime(p.time)} · ${p.board}',
                                  style: TextStyle(color: grey, fontSize: 12)),
                            ],
                          ),
                        ),
                        if (me != null)
                          IconButton(
                            onPressed: _managementMenu,
                            icon: const Icon(Icons.more_horiz),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(p.title,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (p.content.isNotEmpty) _richContent(p.content),
                    if (p.tags.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        children: p.tags
                            .map((t) => GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            CommunityBoardScreen(
                                                board: '全部',
                                                initialTag: t)),
                                  ),
                                  child: Chip(
                                    label: Text('#$t#'),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                    if (p.images.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      for (final img in p.images) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(img, fit: BoxFit.cover),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: me == null
                              ? null
                              : () => communityStore.toggleLike(p),
                          icon: Icon(liked
                              ? Icons.thumb_up
                              : Icons.thumb_up_outlined),
                          label: Text('${p.likedBy.length}'),
                        ),
                        TextButton.icon(
                          onPressed: me == null
                              ? null
                              : () => communityStore.toggleFavorite(p),
                          icon: Icon(
                              favorited ? Icons.star : Icons.star_border),
                          label: Text('${p.favoritedBy.length}'),
                        ),
                        TextButton.icon(
                          onPressed: _share,
                          icon: const Icon(Icons.share_outlined),
                          label: const Text('分享'),
                        ),
                        if (p.reported) ...[
                          const Spacer(),
                          const Text('已举报·待审核',
                              style: TextStyle(
                                  color: Colors.orange, fontSize: 12)),
                        ],
                      ],
                    ),
                    const Divider(),
                    Text('评论（${p.comments.length}）',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (p.comments.isEmpty)
                      Text('还没有评论，来抢沙发',
                          style: TextStyle(color: grey)),
                    ...p.comments.map((c) {
                      final cLiked =
                          me != null && c.likedBy.contains(me.id);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  communityAvatar(
                                    bytes: c.authorAvatar,
                                    color: c.authorColor,
                                    nickname: c.authorNickname,
                                    radius: 14,
                                    frame: c.authorFrame,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(c.authorNickname,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13)),
                                  ),
                                  Builder(builder: (_) {
                                    final account = communityStore
                                        .findAccount(c.authorId);
                                    if (account == null) {
                                      return const SizedBox.shrink();
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                          right: 6),
                                      child: LevelBadge(account: account),
                                    );
                                  }),
                                  const Spacer(),
                                  Text(CommunityStore.formatTime(c.time),
                                      style: TextStyle(
                                          color: grey, fontSize: 11)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              _richContent(c.content),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  TextButton.icon(
                                    onPressed: me == null
                                        ? null
                                        : () => communityStore
                                            .toggleCommentLike(p, c),
                                    icon: Icon(
                                        cLiked
                                            ? Icons.thumb_up
                                            : Icons.thumb_up_outlined,
                                        size: 16),
                                    label: Text('${c.likedBy.length}'),
                                  ),
                                  TextButton(
                                    onPressed: me == null
                                        ? null
                                        : () {
                                            _replyCtrl.text =
                                                '@${c.authorId} ';
                                            _replyCtrl.selection =
                                                TextSelection.fromPosition(
                                              TextPosition(
                                                  offset:
                                                      _replyCtrl.text.length),
                                            );
                                          },
                                    child: const Text('回复'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              SafeArea(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border(
                        top: BorderSide(
                            color: grey.withValues(alpha: 0.3))),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _replyCtrl,
                          decoration: const InputDecoration(
                            hintText: '写下你的回复……（@ID 可提醒对方）',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _sendReply,
                        icon: const Icon(Icons.send),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
