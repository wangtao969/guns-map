import 'package:flutter/material.dart';
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
  CommunityPost({
    required this.title,
    required this.content,
    required this.time,
    required this.authorNickname,
    required this.authorId,
    required this.authorColor,
  });
}

/// 本地账号：昵称、ID、密码、头像颜色。ID 注册后不可改。
class CommunityAccount {
  String nickname;
  final String id;
  final String password;
  Color avatarColor;
  CommunityAccount({
    required this.nickname,
    required this.id,
    required this.password,
    required this.avatarColor,
  });
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

  /// 注册：昵称、ID、密码、确认密码；ID 不可重复，注册成功自动登录。
  Future<void> _register() async {
    final nickCtrl = TextEditingController();
    final idCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    var color = _avatarColors.first;
    String? error;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          title: const Text('注册账号'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('头像颜色'),
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
                const SizedBox(height: 16),
                TextField(
                  controller: nickCtrl,
                  decoration: const InputDecoration(
                    labelText: '昵称',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: idCtrl,
                  decoration: const InputDecoration(
                    labelText: 'ID（登录用，不可重复）',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: '密码',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: '确认密码',
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
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                final nick = nickCtrl.text.trim();
                final id = idCtrl.text.trim();
                final pass = passCtrl.text;
                final confirm = confirmCtrl.text;
                String? e;
                if (nick.isEmpty || id.isEmpty || pass.isEmpty) {
                  e = '昵称、ID、密码都不能为空';
                } else if (pass != confirm) {
                  e = '两次密码不一致';
                } else if (_accounts.any((a) => a.id == id)) {
                  e = '这个 ID 已经被注册了';
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
                );
                _accounts.add(account);
                _current = account;
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('注册'),
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
          title: const Text('登录'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: idCtrl,
                decoration: const InputDecoration(
                  labelText: 'ID',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '密码',
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
              child: const Text('取消'),
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
                  setDialogState(() => error = 'ID 或密码不对');
                  return;
                }
                _current = found;
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('登录'),
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
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          title: const Text('编辑资料'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('头像颜色'),
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
              const SizedBox(height: 16),
              TextField(
                controller: nickCtrl,
                decoration: const InputDecoration(
                  labelText: '昵称',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Text('ID：${account.id}（注册后不可改）',
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('保存'),
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
      });
    }
    nickCtrl.dispose();
  }

  void _askLogin() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('发帖需要先登录'),
        content: const Text('登录已有账号，或者注册一个新账号。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _login();
            },
            child: const Text('登录'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _register();
            },
            child: const Text('注册'),
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
    return Scaffold(
      appBar: const GunsMapAppBar(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('社区',
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('本地账号与动态仅保存在本机当次有效，暂未联网同步；后续接后端后账号体系直接沿用。',
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
                    const Text('你还没有登录',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('登录后才能发帖，账号只保存在本机。',
                        style: TextStyle(color: grey, fontSize: 12)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _login,
                          child: const Text('登录'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: _register,
                          child: const Text('注册'),
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
                    CircleAvatar(
                      backgroundColor: current.avatarColor,
                      foregroundColor: Colors.white,
                      radius: 24,
                      child: Text(
                        current.nickname.isEmpty
                            ? '枪'
                            : current.nickname.characters.first,
                        style: const TextStyle(fontSize: 18),
                      ),
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
                          Text('ID：${current.id}',
                              style: TextStyle(color: grey, fontSize: 12)),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: _editProfile,
                      child: const Text('编辑资料'),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _current = null),
                      child: const Text('退出'),
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
              label: const Text('发一条动态'),
            ),
          if (_composing) ...[
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: '标题',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _contentCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: '内容',
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
                                ? '无标题'
                                : _titleCtrl.text.trim(),
                            content: _contentCtrl.text.trim(),
                            time: _now(),
                            authorNickname: author.nickname,
                            authorId: author.id,
                            authorColor: author.avatarColor,
                          ));
                      _titleCtrl.clear();
                      _contentCtrl.clear();
                      _composing = false;
                    });
                  },
                  child: const Text('发布'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => setState(() => _composing = false),
                  child: const Text('取消'),
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
                    Text('还没有动态', style: TextStyle(color: grey)),
                    const SizedBox(height: 4),
                    Text('登录后发一条动态，聊聊你的枪械与复装心得',
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
                          CircleAvatar(
                            backgroundColor: p.authorColor,
                            foregroundColor: Colors.white,
                            radius: 16,
                            child: Text(
                              p.authorNickname.isEmpty
                                  ? '枪'
                                  : p.authorNickname.characters.first,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.authorNickname,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                Text('ID：${p.authorId}',
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
    );
  }
}
