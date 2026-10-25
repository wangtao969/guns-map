import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../community_store.dart';
import '../i18n.dart';

/// 社区账号对话框（注册 / 登录 / 编辑资料）：社区首屏、个人主页、
/// 设置页、新手引导共用，逻辑只写一份。
const _avatarColors = [
  Color(0xFF6B5B3E),
  Color(0xFF8C4A2F),
  Color(0xFF2F5D50),
  Color(0xFF3E5C8C),
  Color(0xFF7A4A8C),
  Color(0xFF8C8C3E),
];

const _pickImageChannel = MethodChannel('gunsmap/pick_image');

Future<Uint8List?> _pickAvatar(BuildContext context) async {
  try {
    final bytes = await _pickImageChannel.invokeMethod<Uint8List>('pickImage');
    if (bytes == null || bytes.isEmpty) return null;
    return bytes;
  } catch (_) {
    return null;
  }
}

Widget _avatarPickerRow({
  required BuildContext context,
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
                final bytes = await _pickAvatar(context);
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

Widget _colorPickerRow({
  required Color color,
  required StateSetter setDialogState,
  required ValueChanged<Color> onPick,
}) {
  return Row(
    children: _avatarColors.map((c) {
      final selected = c == color;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: GestureDetector(
          onTap: () => setDialogState(() => onPick(c)),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: c,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? Colors.white : Colors.transparent,
                width: 2,
              ),
            ),
            child: selected
                ? const Icon(Icons.check, size: 18, color: Colors.white)
                : null,
          ),
        ),
      );
    }).toList(),
  );
}

Future<bool> showRegisterDialog(BuildContext context) async {
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
              _colorPickerRow(
                color: color,
                setDialogState: setDialogState,
                onPick: (c) => color = c,
              ),
              const SizedBox(height: 12),
              _avatarPickerRow(
                context: context,
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
  return ok == true;
}

Future<bool> showLoginDialog(BuildContext context) async {
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
  return ok == true;
}

Future<void> showEditProfileDialog(BuildContext context) async {
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
              _colorPickerRow(
                color: color,
                setDialogState: setDialogState,
                onPick: (c) => color = c,
              ),
              const SizedBox(height: 12),
              _avatarPickerRow(
                context: context,
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
                decoration: InputDecoration(
                  labelText: tr('bio_label'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: Text(tr('show_id_switch')),
                value: showId,
                onChanged: (v) => setDialogState(() => showId = v),
              ),
              SwitchListTile(
                title: Text(tr('favorites_public_switch')),
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

/// 未登录时弹的登录/注册二选一。
void askLoginDialog(BuildContext context) {
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
            showLoginDialog(context);
          },
          child: Text(tr('login')),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(dialogContext).pop();
            showRegisterDialog(context);
          },
          child: Text(tr('register')),
        ),
      ],
    ),
  );
}
