import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../i18n.dart';
import '../widgets/app_top_bar.dart';

/// 社区板块：本地动态 + 本地账号（注册 / 登录）。
/// 暂未接后端：账号与帖子仅保存在本次打开期间，密码只留在内存里；
/// 后续接后端时再做真正的注册登录与同步，届时账号体系直接沿用。
class CommunityPost {
  final String title;
  final String content;
  final String time;
  final String authorNickname;
  final String authorId;
  final Color authorColor;
  final Uint8List? authorAvatar;
  CommunityPost({
    required this.title,
    required this.content,
    required this.time,
    required this.authorNickname,
    required this.authorId,
    required this.authorColor,
    this.authorAvatar,
  });
}

/// 本地账号：昵称、ID、密码、头像颜色或上传头像。ID 注册后不可改。
/// 上传头像只保存在内存里（与账号体系一样，本次打开期间有效）。
class CommunityAccount {
  String nickname;
  final String id;
  final String password;
  Color avatarColor;
  Uint8List? avatarBytes;
  CommunityAccount({
    required this.nickname,
    required this.id,
    required this.password,
    required this.avatarColor,
    this.avatarBytes,
  });
}

/// 头像显示：有上传头像用图片，没有则用颜色圆 + 昵称首字。
Widget communityAvatar({
  required Uint8List? bytes,
  required Color color,
  required String nickname,
  required double radius,
}) {
  if (bytes != null) {
    return CircleAvatar(
      backgroundImage: MemoryImage(bytes),
      radius: radius,
    );
  }
  return CircleAvatar(
    backgroundColor: color,
    foregroundColor: Colors.white,
    radius: radius,
    child: Text(
      nickname.isEmpty ? '枪' : nickname.characters.first,
      style: TextStyle(fontSize: radius * 0.75),
    ),
  );
}

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final _posts = <CommunityPost>[];
  final _accounts = <CommunityAccount>[];
  CommunityAccount? _current;
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  bool _composing = false;

  static const _avatarColors = [
    Color(0xFF6B5B3E),
    Color(0xFF8C4A2F),
    Color(0xFF2F5D50),
    Color(0xFF3E5C8C),
    Color(0xFF7A4A8C),
    Color(0xFF8C8C3E),
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  String _now() {
    final n = DateTime.now();
    return '${n.month}月${n.day}日 ${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}';
  }

  /// 原生选图：走 gunsmap/pick_image 通道调系统相册，原生侧缩放到 512px 内再回传。
  /// 没装相册应用或用户没选图时返回 null。
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

  /// 注册/编辑资料共用的头像行：上传图片预览 + 上传按钮，已上传时可改回颜色头像。
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

  /// 注册：昵称、ID、密码、确认密码；ID 不可重复，注册成功自动登录。
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
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: idCtrl,
                  decoration: InputDecoration(
                    labelText: tr('id_login_hint'),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: tr('password_label'),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: tr('confirm_password'),
                    border: OutlineInputBorder(),
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
                final confirm = confirmCtrl.text;
                String? e;
                if (nick.isEmpty || id.isEmpty || pass.isEmpty) {
                  e = tr('err_empty');
                } else if (pass != confirm) {
                  e = tr('err_mismatch');
                } else if (_accounts.any((a) => a.id == id)) {
                  e = tr('err_dup');
                }
                if (e != null) {
                  setDialogState(() => error = e);
                  return;
                }
                final account = CommunityAccount(
                  nickname: nick,
                  id: id,
                  password: pass,
                  avatarColor: color,
                  avatarBytes: pickedAvatar,
                );
                _accounts.add(account);
                _current = account;
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

  /// 登录：ID + 密码，对上本地账号才能进。
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
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: tr('password_label'),
                  border: OutlineInputBorder(),
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
                final id = idCtrl.text.trim();
                final pass = passCtrl.text;
                CommunityAccount? found;
                for (final a in _accounts) {
                  if (a.id == id && a.password == pass) found = a;
                }
                if (found == null) {
                  setDialogState(() => error = tr('err_login'));
                  return;
                }
                _current = found;
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

  /// 已登录账号改资料：昵称与头像颜色可改，ID 注册后固定。
  Future<void> _editProfile() async {
    final account = _current;
    if (account == null) return;
    final nickCtrl = TextEditingController(text: account.nickname);
    var color = account.avatarColor;
    Uint8List? pickedAvatar = account.avatarBytes;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          title: Text(tr('edit_profile')),
          content: Column(
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
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Text('${tr('id_field')}：${account.id}${tr('id_fixed_suffix')}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
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
      setState(() {
        if (nickCtrl.text.trim().isNotEmpty) {
          account.nickname = nickCtrl.text.trim();
        }
        account.avatarColor = color;
        account.avatarBytes = pickedAvatar;
      });
    }
    nickCtrl.dispose();
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

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final grey = dark ? const Color(0xFF8A8578) : const Color(0xFF9A917F);
    final current = _current;
    // 语言切换时整页重译。
    return ValueListenableBuilder<String>(
      valueListenable: localeNotifier,
      builder: (_, __, ___) => Scaffold(
      appBar: const GunsMapAppBar(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(tr('tab_community'),
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(tr('community_note'),
              style: TextStyle(color: grey, fontSize: 12)),
          const SizedBox(height: 12),
          // 账号区：未登录显示登录/注册，已登录显示资料卡。
          if (current == null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr('not_logged'),
                        style: TextStyle(fontWeight: FontWeight.bold)),
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
                child: Row(
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
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 2),
                          Text('${tr('id_field')}：${current.id}',
                              style: TextStyle(color: grey, fontSize: 12)),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: _editProfile,
                      child: Text(tr('edit_profile')),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _current = null),
                      child: Text(tr('logout')),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          if (!_composing)
            OutlinedButton.icon(
              onPressed: () {
                if (_current == null) {
                  _askLogin();
                } else {
                  setState(() => _composing = true);
                }
              },
              icon: const Icon(Icons.edit_outlined),
              label: Text(tr('post_new')),
            ),
          if (_composing) ...[
            TextField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                labelText: tr('post_title_label'),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _contentCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: tr('post_content_label'),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    final author = _current;
                    if (author == null) return;
                    if (_titleCtrl.text.trim().isEmpty &&
                        _contentCtrl.text.trim().isEmpty) {
                      return;
                    }
                    setState(() {
                      _posts.insert(
                          0,
                          CommunityPost(
                            title: _titleCtrl.text.trim().isEmpty
                                ? tr('post_no_title')
                                : _titleCtrl.text.trim(),
                            content: _contentCtrl.text.trim(),
                            time: _now(),
                            authorNickname: author.nickname,
                            authorId: author.id,
                            authorColor: author.avatarColor,
                            authorAvatar: author.avatarBytes,
                          ));
                      _titleCtrl.clear();
                      _contentCtrl.clear();
                      _composing = false;
                    });
                  },
                  child: Text(tr('publish')),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => setState(() => _composing = false),
                  child: Text(tr('cancel')),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          if (_posts.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.forum_outlined, size: 48, color: grey),
                    const SizedBox(height: 12),
                    Text(tr('no_posts'), style: TextStyle(color: grey)),
                    const SizedBox(height: 4),
                    Text(tr('no_posts_sub'),
                        style: TextStyle(color: grey, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ..._posts.map((p) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          communityAvatar(
                            bytes: p.authorAvatar,
                            color: p.authorColor,
                            nickname: p.authorNickname,
                            radius: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.authorNickname,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                Text('${tr('id_field')}：${p.authorId}',
                                    style: TextStyle(
                                        color: grey, fontSize: 11)),
                              ],
                            ),
                          ),
                          Text(p.time,
                              style: TextStyle(color: grey, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(p.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      if (p.content.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(p.content),
                      ],
                    ],
                  ),
                ),
              )),
        ],
      ),
      ),
    );
  }
}
