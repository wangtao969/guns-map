import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../community_store.dart';
import '../i18n.dart';
import '../widgets/app_top_bar.dart';
import 'community_compose_screen.dart';
import 'community_dm_screen.dart';
import 'community_notifications_screen.dart';
import 'community_post_detail_screen.dart';
import 'community_profile_screen.dart';

/// 社区本机版首页：账号卡、搜索、板块、排序、帖子列表。
/// 数据只在内存里（见 community_store.dart），不联网、不落盘。
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  String _query = '';
  String _board = '全部';
  String _sort = 'time'; // time 最新 / hot 最热
  String? _tag;
  final _expandedReported = <String>{};

  static const _avatarColors = [
    Color(0xFF6B5B3E),
    Color(0xFF8C4A2F),
    Color(0xFF2F5D50),
    Color(0xFF3E5C8C),
    Color(0xFF7A4A8C),
    Color(0xFF8C8C3E),
  ];

  static const _pickImageChannel = MethodChannel('gunsmap/pick_image');

  Future<Uint8List?> _pickAvatar() async {
    try {
      final bytes = await _pickImageChannel.invokeMethod<Uint8List>('pickImage');
      if (bytes == null || bytes.isEmpty) return null;
      return bytes;
    } catch (_) {
      return null;
    }
  }

  Widget _avatarPickerRow({
    required Uint8List? picked,
    required Color color,
    required String nickname,
    required StateSetter setDialogState,
    required ValueChanged<Uint8List?> onPicked,
  }) {
    return Row(
      children: [
        communityAvatar(
            bytes: picked, color: color, nickname: nickname, radius: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OutlinedButton.icon(
                onPressed: () async {
                  final bytes = await _pickAvatar();
                  if (bytes == null) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(tr('pick_failed'))),
                      );
                    }
                    return;
                  }
                  setDialogState(() => onPicked(bytes));
                },
                icon: const Icon(Icons.photo_library_outlined, size: 18),
                label: Text(tr('upload_avatar')),
              ),
              if (picked != null)
                TextButton(
                  onPressed: () => setDialogState(() => onPicked(null)),
                  child: Text(tr('use_color_avatar')),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _register() async {
    final nickCtrl = TextEditingController();
    final idCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    var color = _avatarColors.first;
    Uint8List? pickedAvatar;
    String? error;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          title: Text(tr('register_title')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('avatar_color')),
                const SizedBox(height: 8),
                Row(
                  children: _avatarColors.map((c) {
                    final selected = c == color;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setDialogState(() => color = c),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected
                                  ? Colors.white
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: selected
                              ? const Icon(Icons.check,
                                  size: 18, color: Colors.white)
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                _avatarPickerRow(
                  picked: pickedAvatar,
                  color: color,
                  nickname: nickCtrl.text,
                  setDialogState: setDialogState,
                  onPicked: (b) => pickedAvatar = b,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nickCtrl,
                  decoration: InputDecoration(
                    labelText: tr('nickname_label'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: idCtrl,
                  decoration: InputDecoration(
                    labelText: tr('id_login_hint'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: tr('password_label'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: tr('confirm_password'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(error!, style: const TextStyle(color: Colors.red)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(tr('cancel')),
            ),
            TextButton(
              onPressed: () {
                final nick = nickCtrl.text.trim();
                final id = idCtrl.text.trim();
                final pass = passCtrl.text;
                String? e;
                if (pass != confirmCtrl.text) {
                  e = tr('err_mismatch');
                } else {
                  e = communityStore.register(
                    nickname: nick,
                    id: id,
                    password: pass,
                    avatarColor: color,
                    avatarBytes: pickedAvatar,
                  );
                }
                if (e != null) {
                  setDialogState(() => error = e);
                  return;
                }
                Navigator.of(dialogContext).pop(true);
              },
              child: Text(tr('register')),
            ),
          ],
        ),
      ),
    );
    nickCtrl.dispose();
    idCtrl.dispose();
    passCtrl.dispose();
    confirmCtrl.dispose();
    if (ok == true) setState(() {});
  }

  Future<void> _login() async {
    final idCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String? error;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          title: Text(tr('login')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: idCtrl,
                decoration: InputDecoration(
                  labelText: tr('id_field'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: tr('password_label'),
                  border: const OutlineInputBorder(),
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(error!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(tr('cancel')),
            ),
            TextButton(
              onPressed: () {
                final e = communityStore.login(
                  id: idCtrl.text.trim(),
                  password: passCtrl.text,
                );
                if (e != null) {
                  setDialogState(() => error = e);
                  return;
                }
                Navigator.of(dialogContext).pop(true);
              },
              child: Text(tr('login')),
            ),
          ],
        ),
      ),
    );
    idCtrl.dispose();
    passCtrl.dispose();
    if (ok == true) setState(() {});
  }

  Future<void> _editProfile() async {
    final account = communityStore.current;
    if (account == null) return;
    final nickCtrl = TextEditingController(text: account.nickname);
    final bioCtrl = TextEditingController(text: account.bio);
    var color = account.avatarColor;
    Uint8List? pickedAvatar = account.avatarBytes;
    var showId = account.showIdPublic;
    var favPublic = account.favoritesPublic;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          title: Text(tr('edit_profile')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('avatar_color')),
                const SizedBox(height: 8),
                Row(
                  children: _avatarColors.map((c) {
                    final selected = c == color;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setDialogState(() => color = c),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color:
                                  selected ? Colors.white : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: selected
                              ? const Icon(Icons.check,
                                  size: 18, color: Colors.white)
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                _avatarPickerRow(
                  picked: pickedAvatar,
                  color: color,
                  nickname: nickCtrl.text,
                  setDialogState: setDialogState,
                  onPicked: (b) => pickedAvatar = b,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nickCtrl,
                  decoration: InputDecoration(
                    labelText: tr('nickname_label'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bioCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: '个人简介',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('帖子旁显示 ID'),
                  value: showId,
                  onChanged: (v) => setDialogState(() => showId = v),
                ),
                SwitchListTile(
                  title: const Text('收藏对外可见'),
                  value: favPublic,
                  onChanged: (v) => setDialogState(() => favPublic = v),
                ),
                Text(
                    '${tr('id_field')}：${account.id}${tr('id_fixed_suffix')}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(tr('cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(tr('save')),
            ),
          ],
        ),
      ),
    );
    if (saved == true) {
      if (nickCtrl.text.trim().isNotEmpty) {
        account.nickname = nickCtrl.text.trim();
      }
      account.bio = bioCtrl.text.trim();
      account.avatarColor = color;
      account.avatarBytes = pickedAvatar;
      account.showIdPublic = showId;
      account.favoritesPublic = favPublic;
      communityStore.refresh();
    }
    nickCtrl.dispose();
    bioCtrl.dispose();
  }

  void _askLogin() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tr('login_required_title')),
        content: Text(tr('login_required_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(tr('cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _login();
            },
            child: Text(tr('login')),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _register();
            },
            child: Text(tr('register')),
          ),
        ],
      ),
    );
  }

  void _openComposer() {
    if (communityStore.current == null) {
      _askLogin();
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CommunityComposeScreen()),
    );
  }

  List<CommunityPost> _visiblePosts() {
    var list = communityStore.posts.where((p) {
      if (_board != '全部' && p.board != _board) return false;
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

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final grey = dark ? const Color(0xFF8A8578) : const Color(0xFF9A917F);
    return ValueListenableBuilder<String>(
      valueListenable: localeNotifier,
      builder: (_, __, ___) => AnimatedBuilder(
        animation: communityStore,
        builder: (_, __) {
          final current = communityStore.current;
          final visible = _visiblePosts();
          final unread =
              current == null ? 0 : communityStore.unreadCount(current.id);
          return Scaffold(
            appBar: const GunsMapAppBar(),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(tr('tab_community'),
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(tr('community_note'),
                    style: TextStyle(color: grey, fontSize: 12)),
                const SizedBox(height: 12),
                if (current == null)
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
                              style: TextStyle(color: grey, fontSize: 12)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: _login,
                                child: Text(tr('login')),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                onPressed: _register,
                                child: Text(tr('register')),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                if (current != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              communityAvatar(
                                bytes: current.avatarBytes,
                                color: current.avatarColor,
                                nickname: current.nickname,
                                radius: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(current.nickname,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16)),
                                    const SizedBox(height: 2),
                                    Text(
                                        '${tr('id_field')}：${current.id}',
                                        style: TextStyle(
                                            color: grey, fontSize: 12)),
                                    if (current.bio.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(current.bio,
                                          style: TextStyle(
                                              color: grey, fontSize: 12)),
                                    ],
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: _editProfile,
                                child: Text(tr('edit_profile')),
                              ),
                              TextButton(
                                onPressed: () => communityStore.logout(),
                                child: Text(tr('logout')),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            CommunityProfileScreen(
                                                account: current)),
                                  ),
                                  icon: const Icon(Icons.person_outlined,
                                      size: 18),
                                  label: const Text('我的主页'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const CommunityNotificationsScreen()),
                                  ),
                                  icon: Badge(
                                    isLabelVisible: unread > 0,
                                    label: Text('$unread'),
                                    child: const Icon(
                                        Icons.notifications_outlined,
                                        size: 18),
                                  ),
                                  label: const Text('通知'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const CommunityDmScreen()),
                                  ),
                                  icon: const Icon(Icons.mail_outlined,
                                      size: 18),
                                  label: const Text('私信'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _openComposer,
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(communityStore.draft == null
                      ? tr('post_new')
                      : '继续写草稿'),
                ),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (v) => setState(() => _query = v.trim()),
                  decoration: const InputDecoration(
                    hintText: '搜索帖子标题、内容、话题',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final b in ['全部', ...communityBoards])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(b),
                            selected: _board == b,
                            onSelected: (_) => setState(() => _board = b),
                          ),
                        ),
                    ],
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
                ...visible.map((p) => _PostCard(
                      post: p,
                      grey: grey,
                      reportedExpanded:
                          _expandedReported.contains(p.id),
                      onExpandReported: () =>
                          setState(() => _expandedReported.add(p.id)),
                      onTagTap: (t) => setState(() => _tag = t),
                      onOpen: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                CommunityPostDetailScreen(post: p)),
                      ),
                    )),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// 帖子卡片：作者、板块、置顶/精华、内容预览、首图、标签、互动数。
class _PostCard extends StatelessWidget {
  final CommunityPost post;
  final Color grey;
  final bool reportedExpanded;
  final VoidCallback onExpandReported;
  final ValueChanged<String> onTagTap;
  final VoidCallback onOpen;
  const _PostCard({
    required this.post,
    required this.grey,
    required this.reportedExpanded,
    required this.onExpandReported,
    required this.onTagTap,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final p = post;
    final me = communityStore.current;
    final authorAccount = communityStore.findAccount(p.authorId);
    final showId = authorAccount?.showIdPublic ?? true;
    final reportedHidden = p.reported && !reportedExpanded;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: reportedHidden ? onExpandReported : onOpen,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      final account =
                          communityStore.findAccount(p.authorId);
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
                      radius: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(p.authorNickname,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                            ),
                            if (p.pinned) ...[
                              const SizedBox(width: 6),
                              const _Badge('置顶', Colors.red),
                            ],
                            if (p.essence) ...[
                              const SizedBox(width: 6),
                              const _Badge('精华', Colors.amber),
                            ],
                          ],
                        ),
                        if (showId)
                          Text('${tr('id_field')}：${p.authorId}',
                              style:
                                  TextStyle(color: grey, fontSize: 11)),
                      ],
                    ),
                  ),
                  Text(CommunityStore.formatTime(p.time),
                      style: TextStyle(color: grey, fontSize: 12)),
                ],
              ),
              if (reportedHidden) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: grey.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('该帖已被举报，待审核，点击查看原文'),
                ),
              ] else ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: grey.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(p.board, style: const TextStyle(fontSize: 11)),
                    ),
                    if (p.reported) ...[
                      const SizedBox(width: 6),
                      const _Badge('已举报', Colors.orange),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(p.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                if (p.content.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    p.content,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (p.images.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      p.images.first,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
                if (p.tags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: p.tags
                        .map((t) => GestureDetector(
                              onTap: () => onTagTap(t),
                              child: Chip(
                                label: Text('#$t#'),
                                visualDensity: VisualDensity.compact,
                              ),
                            ))
                        .toList(),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.thumb_up_outlined, size: 15, color: grey),
                    Text(' ${p.likedBy.length}',
                        style: TextStyle(color: grey, fontSize: 12)),
                    const SizedBox(width: 12),
                    Icon(Icons.star_border, size: 15, color: grey),
                    Text(' ${p.favoritedBy.length}',
                        style: TextStyle(color: grey, fontSize: 12)),
                    const SizedBox(width: 12),
                    Icon(Icons.comment_outlined, size: 15, color: grey),
                    Text(' ${p.comments.length}',
                        style: TextStyle(color: grey, fontSize: 12)),
                    const Spacer(),
                    if (me != null && me.id == p.authorId)
                      Text('我的帖子',
                          style: TextStyle(color: grey, fontSize: 11)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
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
