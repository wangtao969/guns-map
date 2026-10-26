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
  bool _showSettings = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
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
          appBar: SubPageAppBar(title: '通知'),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    TextButton.icon(
                      onPressed: () =>
                          setState(() => _showSettings = !_showSettings),
                      icon: const Icon(Icons.tune, size: 18),
                      label: const Text('提醒设置'),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: me == null
                          ? null
                          : () => communityStore.markAllNotificationsRead(me.id),
                      child: const Text('全部已读'),
                    ),
                  ],
                ),
              ),
              if (_showSettings) ...[
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
              ],
              // 四栏改成个人主页同款文字 Tab：大字 + 选中下铜橙下划线；
              // 左右滑动切换（TabBarView）不变，只换按钮样式，不用默认 TabBar。
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AnimatedBuilder(
                  animation: _tabCtrl,
                  builder: (_, __) {
                    const labels = ['全部', '系统公告', '互动', '私信'];
                    return Column(
                      children: [
                        Row(
                          children: [
                            for (var i = 0; i < labels.length; i++)
                              Padding(
                                padding: EdgeInsets.only(
                                    right: i == labels.length - 1 ? 0 : 28),
                                child: InkWell(
                                  onTap: () => _tabCtrl.animateTo(i),
                                  child: Column(
                                    children: [
                                      Text(labels[i],
                                          style: TextStyle(
                                              fontSize: 17,
                                              fontWeight:
                                                  _tabCtrl.index == i
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                              color: _tabCtrl.index == i
                                                  ? null
                                                  : grey)),
                                      const SizedBox(height: 6),
                                      Container(
                                        width: 26,
                                        height: 3,
                                        decoration: BoxDecoration(
                                          color: _tabCtrl.index == i
                                              ? const Color(0xFFE86A1C)
                                              : Colors.transparent,
                                          borderRadius:
                                              BorderRadius.circular(2),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: 0.5,
                          color: grey.withValues(alpha: 0.25),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _NotificationList(items: mine, grey: grey),
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

  /// X 风格行：种类小圆标 + 粗标题 + 正文 + 时间，未读右上角蓝点，行间细线。
  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(child: Text('暂无通知', style: TextStyle(color: grey)));
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final n = items[i];
        final IconData icon;
        final Color iconColor;
        switch (n.kind) {
          case 'system':
            icon = Icons.campaign_outlined;
            iconColor = const Color(0xFFE86A1C);
            break;
          case 'dm':
            icon = Icons.mail_outlined;
            iconColor = const Color(0xFF4A90D9);
            break;
          default:
            icon = Icons.favorite_border;
            iconColor = const Color(0xFFE0245E);
        }
        return InkWell(
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
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 20, color: iconColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(n.title,
                          style: TextStyle(
                              fontWeight: n.read
                                  ? FontWeight.normal
                                  : FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(n.body, style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(CommunityStore.formatTime(n.time),
                          style: TextStyle(color: grey, fontSize: 11)),
                    ],
                  ),
                ),
                if (!n.read) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1D9BF0),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
