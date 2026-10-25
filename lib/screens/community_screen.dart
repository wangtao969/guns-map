import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../community_store.dart';
import '../i18n.dart';
import '../widgets/app_top_bar.dart';
import 'community_board_screen.dart';
import 'community_compose_screen.dart';
import 'community_dm_screen.dart';
import 'community_notifications_screen.dart';
import 'community_profile_screen.dart';

/// 社区本机版首页：账号卡、搜索、板块、排序、帖子列表。
/// 数据只在内存里（见 community_store.dart），不联网、不落盘。
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {

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

  void _search(String q) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) =>
              CommunityBoardScreen(board: '全部', initialQuery: q.trim())),
    );
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
                  onSubmitted: _search,
                  decoration: const InputDecoration(
                    hintText: '搜索帖子标题、内容、话题',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('板块',
                    style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.6,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: communityBoards.length + 1,
                  itemBuilder: (context, i) {
                    if (i == 0) {
                      final all = communityStore.posts;
                      return _BoardCard(
                        icon: Icons.forum_outlined,
                        name: '全部帖子',
                        count: all.length,
                        latest: all.isEmpty ? null : all.first.title,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const CommunityBoardScreen(
                                  board: '全部')),
                        ),
                      );
                    }
                    final b = communityBoards[i - 1];
                    final inBoard = communityStore.posts
                        .where((p) => p.board == b)
                        .toList();
                    return _BoardCard(
                      icon: _boardIcon(b),
                      name: b,
                      count: inBoard.length,
                      latest:
                          inBoard.isEmpty ? null : inBoard.first.title,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                CommunityBoardScreen(board: b)),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// 板块大卡片：图标 + 板块名 + 帖子数 + 最新帖标题，点进去是论坛式列表。
class _BoardCard extends StatelessWidget {
  final IconData icon;
  final String name;
  final int count;
  final String? latest;
  final VoidCallback onTap;
  const _BoardCard({
    required this.icon,
    required this.name,
    required this.count,
    required this.latest,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final grey = dark ? const Color(0xFF8A8578) : const Color(0xFF9A917F);
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 22, color: const Color(0xFF8C6A2F)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('$count 帖',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: grey, fontSize: 12)),
              const SizedBox(height: 4),
              Text(latest == null ? '暂无帖子' : '最新：$latest',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: grey, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _boardIcon(String board) {
  switch (board) {
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
