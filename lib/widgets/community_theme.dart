import 'package:flutter/material.dart';

/// 社区共用视觉：
/// - 次要文字：浅色底用深暖灰、深色底用浅暖灰，正文次要文字对比度 ≥4.5:1；
/// - 强调色橙：只用于经验 / 勋章 / 未读，奖励感的唯一视觉出口；
/// - 板块图标与封面：图标统一放进圆环容器（枪形圆环语言），封面用品类抠图。
Color communitySecondary(bool dark) =>
    dark ? const Color(0xFFB8B0A0) : const Color(0xFF6E6557);

const communityAccent = Color(0xFFE86A1C);

Color rarityColor(String rarity) {
  switch (rarity) {
    case 'R':
      return const Color(0xFF4A90D9);
    case 'SR':
      return const Color(0xFF9B59B6);
    case 'SSR':
      return communityAccent;
    default:
      return const Color(0xFF8A8D91);
  }
}

IconData boardIcon(String board) {
  switch (board) {
    case '晒枪':
      return Icons.photo_camera_outlined;
    case '复装心得':
      return Icons.build_outlined;
    case '求助问答':
      return Icons.help_outline;
    case '资讯':
      return Icons.newspaper_outlined;
    case '枪械评测':
      return Icons.rate_review_outlined;
    case '新手入门':
      return Icons.school_outlined;
    case '配件分享':
      return Icons.widgets_outlined;
    case '射击技巧':
      return Icons.gps_fixed;
    case '历史名枪':
      return Icons.history;
    case '靶场日记':
      return Icons.book_outlined;
    default:
      return Icons.forum_outlined;
  }
}

/// 板块封面兜底图（有帖子图时优先用帖子图）：品类透明底抠图。
String boardCover(String board) {
  switch (board) {
    case '晒枪':
      return 'assets/images/category-handgun.png';
    case '复装心得':
      return 'assets/images/category-antimateriel.png';
    case '求助问答':
      return 'assets/images/category-dmr.png';
    case '资讯':
      return 'assets/images/category-sniper.png';
    case '枪械评测':
      return 'assets/images/category-mg.png';
    case '新手入门':
      return 'assets/images/category-shotgun.png';
    case '配件分享':
      return 'assets/images/category-smg.png';
    case '靶场日记':
      return 'assets/images/category-shotgun.png';
    default:
      return 'assets/images/category-rifle.png';
  }
}
