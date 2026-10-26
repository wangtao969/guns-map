import 'package:flutter/material.dart';
import '../community_store.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/community_theme.dart';
import '../widgets/level_badge.dart';
import 'community_board_screen.dart';

/// 排行榜页：经验榜（本机注册账号按总经验排）+ 板块热度榜（按板块热度排）。
/// 本机数据，不含任何线上用户；榜单说明在页脚明示。
class CommunityLeaderboardScreen extends StatelessWidget {
  const CommunityLeaderboardScreen({super.key});

  Widget _rankNumber(int rank) {
    final color = rank == 1
        ? const Color(0xFFD4AF37)
        : rank == 2
            ? const Color(0xFF9AA0A6)
            : rank == 3
                ? const Color(0xFFCD7F32)
                : Colors.grey;
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: Text('$rank',
          style: const TextStyle(
              color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final grey = communitySecondary(dark);
    return AnimatedBuilder(
      animation: communityStore,
      builder: (_, __) {
        final accounts = communityStore.accounts.toList();
        accounts.sort((a, b) => b.totalXp.compareTo(a.totalXp));
        final boards = communityBoards.toList();
        boards.sort((a, b) =>
            communityStore.boardHeat(b).compareTo(communityStore.boardHeat(a)));
        return Scaffold(
          appBar: SubPageAppBar(title: '排行榜'),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('经验榜',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: accounts.isEmpty
                      ? Text('暂无本机账号，注册后参与排行',
                          style: TextStyle(color: grey))
                      : Column(
                          children: [
                            for (var i = 0; i < accounts.length; i++)
                              Padding(
                                padding:
                                    EdgeInsets.only(bottom: i == accounts.length - 1 ? 0 : 12),
                                child: Row(
                                  children: [
                                    _rankNumber(i + 1),
                                    const SizedBox(width: 10),
                                    communityAvatar(
                                      bytes: accounts[i].avatarBytes,
                                      color: accounts[i].avatarColor,
                                      nickname: accounts[i].nickname,
                                      radius: 18,
                                      frame: accounts[i].avatarFrame,
                                      verified: isSpecialAccount(accounts[i]),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                    accounts[i].nickname,
                                                    maxLines: 1,
                                                    overflow: TextOverflow
                                                        .ellipsis,
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold)),
                                              ),
                                              const SizedBox(width: 6),
                                              LevelBadge(
                                                  account: accounts[i]),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                              '经验 ${accounts[i].totalXp} · 发帖 ${communityStore.posts.where((p) => p.authorId == accounts[i].id).length} · 获赞 ${communityStore.posts.where((p) => p.authorId == accounts[i].id).fold(0, (s, p) => s + p.likedBy.length)}',
                                              style: TextStyle(
                                                  color: grey, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('板块热度榜',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Card(
                child: Column(
                  children: [
                    for (var i = 0; i < boards.length; i++) ...[
                      if (i > 0) const Divider(height: 1),
                      ListTile(
                        leading: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _rankNumber(i + 1),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: const Color(0xFF8C6A2F),
                                    width: 1.5),
                              ),
                              child: Icon(boardIcon(boards[i]),
                                  size: 16,
                                  color: const Color(0xFF8C6A2F)),
                            ),
                          ],
                        ),
                        title: Text(boards[i],
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                        subtitle: Text(
                            '${communityStore.posts.where((p) => p.board == boards[i]).length} 帖'),
                        trailing: Text(
                            '热度 ${communityStore.boardHeat(boards[i])}',
                            style: TextStyle(color: grey, fontSize: 12)),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  CommunityBoardScreen(board: boards[i])),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('本机排行榜，仅含本机注册账号；板块热度按帖数与互动累计。',
                  style: TextStyle(color: grey, fontSize: 12)),
            ],
          ),
        );
      },
    );
  }
}
