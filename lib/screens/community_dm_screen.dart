import 'package:flutter/material.dart';
import '../community_store.dart';
import '../i18n.dart';
import '../widgets/app_top_bar.dart';
import 'community_profile_screen.dart';

/// 私信：会话列表 + 对话页，只在本机账号之间流转（本机版）。
class CommunityDmScreen extends StatelessWidget {
  /// 直接打开和某人的对话时传对方 ID；不传则显示会话列表。
  final String? peerId;
  const CommunityDmScreen({super.key, this.peerId});

  @override
  Widget build(BuildContext context) {
    final me = communityStore.current;
    if (peerId != null) {
      return CommunityDmThreadScreen(peerId: peerId!);
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
        final others = communityStore.accounts
            .where((a) => a.id != me.id)
            .toList();
        return Scaffold(
          appBar: SubPageAppBar(title: '私信'),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [

              if (peerIds.isEmpty)
                const Text('还没有私信会话，点下面的人名开始聊'),
              ...peerIds.map((pid) {
                final peer = communityStore.findAccount(pid);
                if (peer == null) return const SizedBox.shrink();
                final last = communityStore.dms
                    .where((m) =>
                        (m.fromId == me.id && m.toId == pid) ||
                        (m.fromId == pid && m.toId == me.id))
                    .last;
                return ListTile(
                  leading: communityAvatar(
                    bytes: peer.avatarBytes,
                    color: peer.avatarColor,
                    nickname: peer.nickname,
                    radius: 20,
                  ),
                  title: Text(peer.nickname),
                  subtitle: Text(last.content,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Text(CommunityStore.formatTime(last.time),
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 11)),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => CommunityDmThreadScreen(peerId: pid)),
                  ),
                );
              }),
              const Divider(),
              const Text('选择账号',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ...others.map((a) => ListTile(
                    leading: communityAvatar(
                      bytes: a.avatarBytes,
                      color: a.avatarColor,
                      nickname: a.nickname,
                      radius: 16,
                    ),
                    title: Text(a.nickname),
                    subtitle: Text('${tr('id_field')}：${a.id}'),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => CommunityDmThreadScreen(peerId: a.id)),
                    ),
                  )),
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
                                    ? const Color(0xFF6B5B3E)
                                    : grey.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
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
                          decoration: const InputDecoration(
                            hintText: '发私信……',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          final text = _ctrl.text.trim();
                          if (text.isEmpty) return;
                          communityStore.sendDm(peer.id, text);
                          _ctrl.clear();
                        },
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
