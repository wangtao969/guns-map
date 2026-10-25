import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../community_store.dart';
import '../i18n.dart';
import '../widgets/app_top_bar.dart';

/// 发帖器：标题、板块、图文混排（文字 + 多张图片）、话题标签、自动草稿。
/// 每敲一个字都更新草稿：写一半切后台再回来，内容还在；
/// 发布成功自动清草稿；草稿保存在本机。
class CommunityComposeScreen extends StatefulWidget {
  const CommunityComposeScreen({super.key});

  @override
  State<CommunityComposeScreen> createState() => _CommunityComposeScreenState();
}

class _CommunityComposeScreenState extends State<CommunityComposeScreen> {
  static const _pickImageChannel = MethodChannel('gunsmap/pick_image');
  late final TextEditingController _titleCtrl;
  late final TextEditingController _contentCtrl;
  String _board = '综合';
  final _images = <Uint8List>[];

  @override
  void initState() {
    super.initState();
    final draft = communityStore.draft;
    _titleCtrl = TextEditingController(text: draft?.title ?? '');
    _contentCtrl = TextEditingController(text: draft?.content ?? '');
    if (draft != null) _board = draft.board;
  }

  @override
  void dispose() {
    _saveDraft();
    communityStore.persist();
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  void _saveDraft() {
    communityStore.saveDraft(
      title: _titleCtrl.text,
      content: _contentCtrl.text,
      board: _board,
    );
  }

  Future<void> _addImage() async {
    try {
      final bytes = await _pickImageChannel.invokeMethod<Uint8List>('pickImage');
      if (bytes == null || bytes.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr('pick_failed'))),
          );
        }
        return;
      }
      setState(() => _images.add(bytes));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('pick_failed'))),
        );
      }
    }
  }

  void _publish() {
    final content = _contentCtrl.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('正文不能为空')),
      );
      return;
    }
    final err = communityStore.createPost(
      title: _titleCtrl.text,
      content: content,
      board: _board,
      images: _images,
    );
    if (err != null) {
      if (err == '请先登录') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('login_required_body'))),
        );
      } else if (err == '账号已被禁言' ||
          err == '账号已被封禁' ||
          err == '该板块已关闭') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err)),
        );
      } else {
        // err 就是命中的敏感词。
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('内容含敏感词“$err”，请修改后重试')),
        );
      }
      return;
    }
    // 发动态自动签到：当天还没签到就顺手签了，返回 true 让动态页提示。
    var autoChecked = false;
    final me = communityStore.current;
    if (me != null && !me.checkedInToday) {
      autoChecked = communityStore.checkIn() >= 0;
    }
    Navigator.of(context).pop(autoChecked);
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final grey = dark ? const Color(0xFF8A8578) : const Color(0xFF9A917F);
    final hasDraft = communityStore.draft != null;
    return Scaffold(
      appBar: SubPageAppBar(title: tr('post_new')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const Spacer(),
              if (hasDraft)
                TextButton(
                  onPressed: () {
                    communityStore.clearDraft();
                    setState(() {
                      _titleCtrl.clear();
                      _contentCtrl.clear();
                      _board = '综合';
                      _images.clear();
                    });
                  },
                  child: const Text('清除草稿'),
                ),
              ElevatedButton(
                onPressed: _publish,
                child: const Text('发布'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleCtrl,
            onChanged: (_) => _saveDraft(),
            decoration: const InputDecoration(
              hintText: '标题（可选）',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          const Text('板块', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: communityBoards
                .where((b) => !communityStore.disabledBoards.contains(b))
                .map((b) => ChoiceChip(
                      label: Text(b),
                      selected: _board == b,
                      onSelected: (_) {
                        setState(() => _board = b);
                        _saveDraft();
                      },
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _contentCtrl,
            onChanged: (_) => _saveDraft(),
            maxLines: 12,
            decoration: const InputDecoration(
              hintText: '写点什么……\n话题用 #话题# 的形式，@ID 可以提醒对方',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Text('话题用 #xxx# 包起来，发布后会变成可点击的标签；@对方 ID 可发提醒。',
              style: TextStyle(color: grey, fontSize: 12)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('图片', style: TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: _addImage,
                icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                label: const Text('添加图片'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_images.isEmpty)
            Text('暂无图片，可添加多张', style: TextStyle(color: grey, fontSize: 12)),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _images.asMap().entries.map((e) {
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      e.value,
                      width: 110,
                      height: 110,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    right: 2,
                    top: 2,
                    child: GestureDetector(
                      onTap: () => setState(() => _images.removeAt(e.key)),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            size: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text('草稿会自动保存，下次打开可以继续写。',
              style: TextStyle(color: grey, fontSize: 12)),
        ],
      ),
    );
  }
}
