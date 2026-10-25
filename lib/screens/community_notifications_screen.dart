import 'package:flutter/material.dart';
import '../community_store.dart';
import '../widgets/app_top_bar.dart';
import 'community_post_detail_screen.dart';

/// 通知中心：系统公告 / 互动 / 私信三类，开关可独立控制。
/// 本机版没有 APP 推送（推送要后端），通知只在 App 内查看。
class CommunityNotificationsScreen extends StatefulWidget {
  const CommunityNotificationsScreen({super.key});

  @override
  State<CommunityNotificationsScreen> createState() =>
      _CommunityNotificationsScreenState();
}

class _CommunityNotificationsScreenState
    extends State<CommunityNotificationsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final grey = dark ? const Color(0xFF8A8578) : const Color(0xFF9A917F);
    final me = communityStore.current;
    return AnimatedBuilder(
      animation: communityStore,
      builder: (_, __) {
        final mine =
            me == null ? <CommunityNotification>[] : communityStore.notificationsFor(me.id);
        final byKind = {
          'system': mine.where((n) => n.kind == 'system').toList(),
          'interaction': mine.where((n) => n.kind == 'interaction').toList(),
          'dm': mine.where((n) => n.kind == 'dm').toList(),
        };
        return Scaffold(
          appBar: const GunsMapAppBar(),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    const Expanded(
                      child: Text('通知',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                    TextButton(
                      onPressed: me == null
                          ? null
                          : () => communityStore.markAllNotificationsRead(me.id),
                      child: const Text('全部已读'),
                    ),
                  ],
                ),
              ),
              TabBar(
                controller: _tabCtrl,
                tabs: const [
                  Tab(text: '系统公告'),
                  Tab(text: '互动'),
                  Tab(text: '私信'),
                ],
              ),
              SwitchListTile(
                title: const Text('系统公告提醒'),
                value: communityStore.notifySystem,
                onChanged: (v) => setState(() {
                  communityStore.notifySystem = v;
                  communityStore.refresh();
                }),
              ),
              SwitchListTile(
                title: const Text('互动提醒（回复、点赞、@、关注）'),
                value: communityStore.notifyInteraction,
                onChanged: (v) => setState(() {
                  communityStore.notifyInteraction = v;
                  communityStore.refresh();
                }),
              ),
              SwitchListTile(
                title: const Text('私信提醒'),
                value: communityStore.notifyDm,
                onChanged: (v) => setState(() {
                  communityStore.notifyDm = v;
                  communityStore.refresh();
                }),
              ),
              const Divider(height: 1),
              Expanded(
                child: TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _NotificationList(
                        items: byKind['system']!, grey: grey),
                    _NotificationList(
                        items: byKind['interaction']!, grey: grey),
                    _NotificationList(items: byKind['dm']!, grey: grey),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NotificationList extends StatelessWidget {
  final List<CommunityNotification> items;
  final Color grey;
  const _NotificationList({required this.items, required this.grey});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
          child: Text('暂无通知', style: TextStyle(color: grey)));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: items.map((n) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(n.title,
                style: TextStyle(
                    fontWeight:
                        n.read ? FontWeight.normal : FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(n.body),
                const SizedBox(height: 4),
                Text(CommunityStore.formatTime(n.time),
                    style: TextStyle(color: grey, fontSize: 11)),
              ],
            ),
            onTap: () {
              communityStore.markNotificationRead(n);
              if (n.postId != null) {
                final post = communityStore.findPost(n.postId!);
                if (post != null && context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            CommunityPostDetailScreen(post: post)),
                  );
                }
              }
            },
          ),
        );
      }).toList(),
    );
  }
}
