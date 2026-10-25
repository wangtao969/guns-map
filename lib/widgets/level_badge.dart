import 'package:flutter/material.dart';
import '../community_store.dart';
import 'community_theme.dart';

/// 等级铭牌：段位配色底 + LV.x + 段位名，挂在头像右侧与每条帖子作者名旁。
class LevelBadge extends StatelessWidget {
  final CommunityAccount account;
  final double fontSize;
  const LevelBadge({super.key, required this.account, this.fontSize = 11});

  @override
  Widget build(BuildContext context) {
    final c = account.tierColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c),
      ),
      child: Text(
        'LV${account.level} · ${account.tierName}',
        style: TextStyle(
            color: c, fontSize: fontSize, fontWeight: FontWeight.bold),
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
