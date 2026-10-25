import 'package:flutter/material.dart';
import '../community_store.dart';
import '../i18n.dart';
import '../widgets/app_top_bar.dart';
import 'community_profile_screen.dart';

/// 私信：会话列表 + 对话页，只在本机账号之间流转（本机版）。
/// 列表按 X 风格：顶部搜索框、头像 + 名字 + ID + 时间 + 一行摘要，行间细线。
class CommunityDmScreen extends StatefulWidget {
  /// 直接打开和某人的对话时传对方 ID；不传则显示会话列表。
  final String? peerId;
  const CommunityDmScreen({super.key, this.peerId});

  @override
  State<CommunityDmScreen> createState() => _CommunityDmScreenState();
}

class _CommunityDmScreenState extends State<CommunityDmScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final me = communityStore.current;
    if (widget.peerId != null) {
      return CommunityDmThreadScreen(peerId: widget.peerId!);
    }
    return AnimatedBuilder(
      animation: communityStore,
      builder: (_, __) {
        if (me == null) {
          return Scaffold(
            appBar: SubPageAppBar(title: '私信'),
            body: Center(child: Text(tr('login_required_body'))),
          );
        }
        final peerIds = <String>{};
        for (final m in communityStore.dms) {
          if (m.fromId == me.id) peerIds.add(m.toId);
          if (m.toId == me.id) peerIds.add(m.fromId);
        }
        final q = _query.trim().toLowerCase();
        bool matches(CommunityAccount a) =>
            q.isEmpty ||
            a.nickname.toLowerCase().contains(q) ||
            a.id.toLowerCase().contains(q);
        final sessions = peerIds
            .map(communityStore.findAccount)
            .whereType<CommunityAccount>()
            .where(matches)
            .toList();
        final others = communityStore.accounts
            .where((a) => a.id != me.id && matches(a))
            .toList();
        return Scaffold(
          appBar: SubPageAppBar(title: '私信'),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: '搜索会话或用户',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => setState(() {
                              _searchCtrl.clear();
                              _query = '';
                            }),
                          ),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: sessions.length +
                      (sessions.isEmpty ? 1 : 0) +
                      1 +
                      others.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1),
                  itemBuilder: (_, index) {
                    if (sessions.isEmpty && index == 0) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('还没有私信会话，点下面的人名开始聊'),
                      );
                    }
                    final i = sessions.isEmpty ? index - 1 : index;
                    if (i < sessions.length) {
                      final peer = sessions[i];
                      final last = communityStore.dms
                          .where((m) =>
                              (m.fromId == me.id && m.toId == peer.id) ||
                              (m.fromId == peer.id && m.toId == me.id))
                          .last;
                      return InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  CommunityDmThreadScreen(peerId: peer.id)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              communityAvatar(
                                bytes: peer.avatarBytes,
                                color: peer.avatarColor,
                                nickname: peer.nickname,
                                radius: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(peer.nickname,
                                              maxLines: 1,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold)),
                                        ),
                                        const SizedBox(width: 6),
                                        Text('ID：${peer.id}',
                                            style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12)),
                                        const Spacer(),
                                        Text(
                                            CommunityStore.formatTime(
                                                last.time),
                                            style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 11)),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(last.content,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 13)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    if (i == sessions.length) {
                      return const Padding(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text('开始新对话',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      );
                    }
                    final a = others[i - sessions.length - 1];
                    return ListTile(
                      leading: communityAvatar(
                        bytes: a.avatarBytes,
                        color: a.avatarColor,
                        nickname: a.nickname,
                        radius: 20,
                      ),
                      title: Text(a.nickname),
                      subtitle: Text('${tr('id_field')}：${a.id}'),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                CommunityDmThreadScreen(peerId: a.id)),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class CommunityDmThreadScreen extends StatefulWidget {
  final String peerId;
  const CommunityDmThreadScreen({super.key, required this.peerId});

  @override
  State<CommunityDmThreadScreen> createState() => _CommunityDmThreadScreenState();
}

class _CommunityDmThreadScreenState extends State<CommunityDmThreadScreen> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final grey = dark ? const Color(0xFF8A8578) : const Color(0xFF9A917F);
    final me = communityStore.current;
    final peer = communityStore.findAccount(widget.peerId);
    return AnimatedBuilder(
      animation: communityStore,
      builder: (_, __) {
        if (me == null || peer == null) {
          return Scaffold(
            appBar: SubPageAppBar(title: '私信'),
            body: const Center(child: Text('对方账号不存在')),
          );
        }
        final thread = communityStore.dms
            .where((m) =>
                (m.fromId == me.id && m.toId == peer.id) ||
                (m.fromId == peer.id && m.toId == me.id))
            .toList();
        return Scaffold(
          appBar: SubPageAppBar(title: '私信'),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 16, 16, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                CommunityProfileScreen(account: peer)),
                      ),
                      child: communityAvatar(
                        bytes: peer.avatarBytes,
                        color: peer.avatarColor,
                        nickname: peer.nickname,
                        radius: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(peer.nickname,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: thread.isEmpty
                    ? Center(
                        child: Text('还没有消息，打个招呼吧',
                            style: TextStyle(color: grey)))
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: thread.map((m) {
                          final mine = m.fromId == me.id;
                          return Align(
                            alignment: mine
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: mine
                                    ? const Color(0xFFE86A1C)
                                    : grey.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(18),
                                  topRight: const Radius.circular(18),
                                  bottomLeft: Radius.circular(mine ? 18 : 4),
                                  bottomRight: Radius.circular(mine ? 4 : 18),
                                ),
                              ),
                              child: Text(
                                m.content,
                                style: TextStyle(
                                    color: mine
                                        ? Colors.white
                                        : null),
                              ),
                            ),
                          );
                        }).toList(),
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
                          controller: _ctrl,
                          decoration: InputDecoration(
                            hintText: '发私信……',
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFFE86A1C),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: () {
                            final text = _ctrl.text.trim();
                            if (text.isEmpty) return;
                            communityStore.sendDm(peer.id, text);
                            _ctrl.clear();
                          },
                          icon: const Icon(Icons.send,
                              size: 20, color: Colors.white),
                        ),
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
