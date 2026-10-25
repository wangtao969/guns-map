import 'package:flutter/material.dart';
import '../community_store.dart';
import 'community_theme.dart';

/// 等级铭牌：段位配色底 + LV.x + 段位名，挂在每条帖子作者名旁。
/// 外框高度严格等于昵称字号（nicknameFontSize），不比昵称字大，
/// 保证各页视觉协调；铭牌内文字按比例缩小。
class LevelBadge extends StatelessWidget {
  final CommunityAccount account;
  final double nicknameFontSize;
  const LevelBadge(
      {super.key, required this.account, this.nicknameFontSize = 14});

  @override
  Widget build(BuildContext context) {
    final c = account.tierColor;
    final h = nicknameFontSize;
    return GestureDetector(
      onTap: () => showLevelSystemDialog(context, account),
      child: Container(
        height: h,
        padding: EdgeInsets.symmetric(horizontal: h * 0.32),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(h / 2),
          border: Border.all(color: c),
        ),
        child: Text(
          'LV${account.level} · ${account.tierName}',
          style: TextStyle(
              color: c,
              fontSize: h * 0.68,
              fontWeight: FontWeight.bold,
              height: 1),
        ),
      ),
    );
  }
}

/// 等级制度弹窗：点铭牌弹出，列出六档段位、等级区间与所需累计经验。
void showLevelSystemDialog(BuildContext context, CommunityAccount account) {
  const tiers = [
    ('铁灰', 'LV 1–10', 1, Color(0xFF8A8D91)),
    ('铜', 'LV 11–20', 11, Color(0xFFB08D57)),
    ('银', 'LV 21–35', 21, Color(0xFFB9C0C7)),
    ('金', 'LV 36–48', 36, Color(0xFFD4A017)),
    ('钛', 'LV 49–55', 49, Color(0xFF7FA8BC)),
    ('曜石', 'LV 56–60', 56, Color(0xFF4A4A5A)),
  ];
  final lv = account.level;
  final toNext = lv >= 60
      ? '已满级'
      : '距 LV${lv + 1} 还差 ${CommunityAccount.xpForLevel(lv + 1) - account.totalXp} 经验';
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('用户等级'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('当前：LV$lv · ${account.tierName}（累计 ${account.totalXp} 经验）',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(toNext, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            for (final t in tiers)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                          color: t.$4, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Text(t.$1,
                        style: TextStyle(
                            fontWeight: account.tierName == t.$1
                                ? FontWeight.bold
                                : FontWeight.normal)),
                    const SizedBox(width: 8),
                    Text(t.$2,
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 12)),
                    const Spacer(),
                    Text(
                        t.$3 == 1
                            ? '0 经验起'
                            : '需 ${CommunityAccount.xpForLevel(t.$3)} 经验',
                        style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            const Text('经验来源：签到、发帖、评论、获赞、收藏登记、靶场成绩；每日封顶 120。',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('知道了'),
        ),
      ],
    ),
  );
}

/// 身份制度弹窗：点身份弹出，列出软件内设定的全部用户身份与权限。
void showRoleSystemDialog(BuildContext context) {
  const roles = [
    ('创始用户', 'ID 10000 的账号', '软件全部权限：人员管理、帖子审核、板块开关、赛季与公告配置，不受禁言封禁限制。'),
    ('管理员', 'role 为 admin 的账号', '人员管理、帖子审核、板块开关、赛季与公告配置。'),
    ('版主', 'role 为 moderator 的账号', '帖子审核：取消举报、置顶、加精、删除。'),
    ('普通用户', '默认身份', '发帖、评论、收藏、关注、私信，参与赛季、签到与勋章。'),
  ];
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('用户身份'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final r in roles) ...[
              Text(r.$1, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(r.$2, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              Text(r.$3, style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('知道了'),
        ),
      ],
    ),
  );
}

/// 创始用户铭牌：金底小药丸，与等级铭牌同高（等于昵称字号）。
class FounderBadge extends StatelessWidget {
  final double nicknameFontSize;
  const FounderBadge({super.key, this.nicknameFontSize = 14});

  @override
  Widget build(BuildContext context) {
    const c = Color(0xFFD4A017);
    final h = nicknameFontSize;
    return Container(
      height: h,
      padding: EdgeInsets.symmetric(horizontal: h * 0.32),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(h / 2),
        border: Border.all(color: c),
      ),
      child: Text(
        '创始用户',
        style: TextStyle(
            color: c,
            fontSize: h * 0.68,
            fontWeight: FontWeight.bold,
            height: 1),
      ),
    );
  }
}

/// 勋章圆环徽记：圆环边用稀有度色，未获得时灰化 + 锁形。
class MedalRingBadge extends StatelessWidget {
  final MedalDef medal;
  final bool earned;
  final double size;
  const MedalRingBadge(
      {super.key, required this.medal, required this.earned, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final c = earned ? rarityColor(medal.rarity) : Colors.grey;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: c.withValues(alpha: earned ? 0.16 : 0.08),
        border: Border.all(color: c, width: 2),
      ),
      child: Center(
        child: earned
            ? Text(
                medal.name.characters.first,
                style: TextStyle(
                    color: c,
                    fontSize: size * 0.36,
                    fontWeight: FontWeight.bold),
              )
            : Icon(Icons.lock_outline, size: size * 0.4, color: c),
      ),
    );
  }
}

/// 今日经验条：今日 X/120 + 进度，点击进任务页。
/// 默认橙色；社区签到区传入暗红。
class XpProgressRow extends StatelessWidget {
  final CommunityAccount account;
  final VoidCallback onTap;
  final Color accent;
  const XpProgressRow(
      {super.key,
      required this.account,
      required this.onTap,
      this.accent = communityAccent});

  @override
  Widget build(BuildContext context) {
    final today = account.todayXp;
    const cap = 120;
    final progress = (today / cap).clamp(0.0, 1.0);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(Icons.bolt, size: 18, color: accent),
            const SizedBox(width: 6),
            Text('今日 $today/$cap',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(width: 10),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.grey.withValues(alpha: 0.25),
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, size: 18),
          ],
        ),
      ),
    );
  }
}
