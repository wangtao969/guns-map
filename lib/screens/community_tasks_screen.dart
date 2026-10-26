import 'package:flutter/material.dart';
import '../widgets/app_toast.dart';
import '../community_store.dart';
import '../i18n.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/community_theme.dart';
import '../widgets/level_badge.dart';
import 'community_account_dialogs.dart';
import 'community_board_screen.dart';
import 'community_collection_screen.dart';
import 'community_compose_screen.dart';
import 'community_range_screen.dart';

/// 任务页：今日经验进度 + 等级 / 本期挑战 + 每日任务 + 经验规则。
/// 经验只来自真实动作：签到、发帖（满 20 字）、评论、收藏登记、靶场成绩。
class CommunityTasksScreen extends StatelessWidget {
  const CommunityTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final grey = communitySecondary(dark);
    return AnimatedBuilder(
      animation: communityStore,
      builder: (_, __) {
        final me = communityStore.current;
        return Scaffold(
          appBar: SubPageAppBar(title: '任务'),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [

              if (me == null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tr('not_logged'),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () => showLoginDialog(context),
                              child: Text(tr('login')),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: () => showRegisterDialog(context),
                              child: Text(tr('register')),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(me.nickname,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                            ),
                            LevelBadge(account: me, nicknameFontSize: 16),
                          ],
                        ),
                        const SizedBox(height: 8),
                        XpProgressRow(account: me, onTap: () {}),
                        const SizedBox(height: 4),
                        Text(
                            '下一级还需 ${me.xpNeedLevel - me.xpIntoLevel} 经验',
                            style: TextStyle(color: grey, fontSize: 12)),
                        const SizedBox(height: 8),
                        Text(
                            '本期挑战 ${communityStore.challengeDone(me)}/${challengeCatalog.length} 已完成',
                            style: const TextStyle(
                                color: communityAccent,
                                fontSize: 13,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        const Text('本期挑战',
                            style: TextStyle(
                                fontSize: 17, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        for (final c in challengeCatalog)
                          _TaskTile(
                            title: c.title,
                            subtitle: c.desc,
                            done: c.test(communityStore, me),
                            actionLabel: c.test(communityStore, me)
                                ? '已完成'
                                : (c.id == 'challenge_streak_3'
                                    ? '见上方签到'
                                    : '去做'),
                            onAction: c.test(communityStore, me)
                                ? null
                                : () {
                                    if (c.id == 'challenge_streak_3') return;
                                    final target =
                                        c.id.contains('range')
                                            ? const CommunityRangeScreen()
                                            : c.id.contains('post')
                                                ? const CommunityComposeScreen()
                                                : const CommunityCollectionScreen();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => target),
                                    );
                                  },
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('每日任务',
                    style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _TaskTile(
                  title: '每日签到',
                  subtitle: '每天一次，+10 经验',
                  done: me.checkedInToday,
                  actionLabel: me.checkedInToday
                      ? '已签到 · 连签 ${me.checkInStreak} 天'
                      : '签到',
                  onAction: me.checkedInToday
                      ? null
                      : () {
                          final granted = communityStore.checkIn();
                          showAppToast(context, granted > 0
                                    ? '签到成功 +$granted 经验'
                                    : '签到成功');
                        },
                ),
                _TaskTile(
                  title: '发一条动态',
                  subtitle: '内容满 20 字才计经验，当日首条 +5，之后 +2',
                  done: false,
                  actionLabel: '去发帖',
                  onAction: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const CommunityComposeScreen()),
                  ),
                ),
                _TaskTile(
                  title: '发表一条评论',
                  subtitle: '当日头 3 条 +2，之后 +1',
                  done: false,
                  actionLabel: '去评论',
                  onAction: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            const CommunityBoardScreen(board: '全部')),
                  ),
                ),
                _TaskTile(
                  title: '登记一把收藏',
                  subtitle: '收藏柜每登记一把 +3 经验',
                  done: false,
                  actionLabel: '去收藏柜',
                  onAction: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            const CommunityCollectionScreen()),
                  ),
                ),
                _TaskTile(
                  title: '记录一条靶场成绩',
                  subtitle: '每条成绩 +5 经验，成绩直接喂靶场勋章',
                  done: false,
                  actionLabel: '去记录',
                  onAction: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const CommunityRangeScreen()),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('经验规则',
                    style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  '· 每日经验封顶 120，封顶后当天不再涨经验，明天再来。\n'
                  '· 水贴不计经验：帖子内容不满 20 字不给经验。\n'
                  '· 精华、置顶不直接给经验，防自授；获赞给作者 +1。\n'
                  '· 本期挑战不过期、不清零：完成一项算一项，奖励永久保留。',
                  style: TextStyle(color: grey, fontSize: 13),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _TaskTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool done;
  final String actionLabel;
  final VoidCallback? onAction;
  const _TaskTile({
    required this.title,
    required this.subtitle,
    required this.done,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final grey = communitySecondary(dark);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(done ? Icons.check_circle : Icons.circle_outlined,
                color: done ? communityAccent : grey),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(color: grey, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: onAction,
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
