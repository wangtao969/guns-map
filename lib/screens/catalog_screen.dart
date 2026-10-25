import 'package:flutter/material.dart';
import '../community_store.dart';
import '../data.dart';
import '../haptics.dart';
import '../i18n.dart';
import '../models.dart';
import '../widgets/category_silhouette.dart';
import '../widgets/app_top_bar.dart';
import 'community_collection_screen.dart';
import '../news_data.dart';
import 'news_screen.dart';
import 'community_tasks_screen.dart';
import 'gun_list_screen.dart';
import 'gun_detail_screen.dart';
import 'legend_list_screen.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  String _query = '';
  bool _searchExpanded = false;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final grey = dark ? const Color(0xFF8A8578) : const Color(0xFF9A917F);
    final bronze = dark ? const Color(0xFFC9A86A) : const Color(0xFF6B5B3E);
    final ink = dark ? const Color(0xFFEDE8DF) : const Color(0xFF2E2A24);
    final cardBg = dark ? const Color(0xFF1E1C19) : Colors.white;
    final q = _query.trim().toLowerCase();
    final results = q.isEmpty
        ? <Gun>[]
        : guns
            .where((g) =>
                g.name.toLowerCase().contains(q) ||
                g.vendor.toLowerCase().contains(q) ||
                g.caliber.toLowerCase().contains(q))
            .toList();
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: const GunsMapAppBar(),
      body: SafeArea(
        top: true,
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12 + kToolbarHeight, 16, 16),
          children: [
            // 搜索：平时只显示一个放大镜圆钮，点开才展开成输入框；
            // 收起时清空搜索，避免看不见的筛选条件留在后台。
            if (!_searchExpanded)
              Row(
                children: [
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() => _searchExpanded = true),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: cardBg,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(Icons.search, color: bronze, size: 22),
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: tr('search_gun_hint'),
                          hintStyle: TextStyle(color: grey),
                          prefixIcon: Icon(Icons.search, color: bronze),
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onChanged: (v) => setState(() => _query = v),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() {
                      _searchExpanded = false;
                      _query = '';
                    }),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: cardBg,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(Icons.close, color: grey, size: 20),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            // 枪械资讯入口：页头太空，补一条厂商与弹药商资讯快讯；搜索时隐藏。
            if (_query.isEmpty)
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    tapHaptic();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const NewsScreen()),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: bronze,
                          ),
                          child: Icon(Icons.newspaper_outlined,
                              size: 20,
                              color: dark
                                  ? const Color(0xFF121110)
                                  : Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('枪械资讯',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
                              const SizedBox(height: 2),
                              Text(
                                newsItems.first.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: grey, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: grey),
                      ],
                    ),
                  ),
                ),
              ),
            // 收藏完成度 + 赛季倒计时（登录后显示，点进收藏柜 / 任务页）。
            AnimatedBuilder(
              animation: communityStore,
              builder: (_, __) {
                final me = communityStore.current;
                if (me == null) return const SizedBox.shrink();
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const CommunityCollectionScreen()),
                            ),
                            child: Text(
                                '我的收藏 ${me.collection.length} / ${guns.length}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13)),
                          ),
                        ),
                        InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const CommunityTasksScreen()),
                          ),
                          child: Text(
                              '赛季声望 ${communityStore.seasonPrestige(me)} · 还剩 ${communityStore.seasonRemainingDays} 天',
                              style: const TextStyle(
                                  color: Color(0xFFE86A1C),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            if (_query.isNotEmpty) ...[
              ...results.map((g) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ListTile(
                      title: Text(g.name),
                      subtitle: Text('${g.vendor} · ${g.caliber}'),
                      onTap: () {
                        tapHaptic();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => GunDetailScreen(gun: g)),
                        );
                      },
                    ),
                  )),
              if (results.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Center(
                    child: Text('没有找到相关枪械',
                        style: TextStyle(color: grey)),
                  ),
                ),
            ],
            if (_query.isEmpty) ...[
              Text(tr('gun_categories'),
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: ink)),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.95,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: categories.length,
                itemBuilder: (context, i) {
                  final c = categories[i];
                  final count = guns.where((g) => g.category == c).length;
                  return GestureDetector(
                    onTap: () {
                      tapHaptic();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => GunListScreen(category: c)),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 品类图：固定高度 + contain 全枪可见、居中摆放。
                          // cover 会裁掉枪身两端（之前显示不全就是它造成的），
                          // 透明底抠图用 contain 才能保证整枪可见且位置统一。
                          SizedBox(
                            height: 76,
                            width: double.infinity,
                            child: Image.asset(
                              categoryPhoto[c] ??
                                  'assets/images/category-rifle.png',
                              fit: BoxFit.contain,
                              alignment: Alignment.center,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(trCategory(c),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: ink)),
                          const SizedBox(height: 2),
                          Text(countText(count),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: grey, fontSize: 12)),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 6),
              Text('品类图片来源：Wikimedia Commons（免费授权）',
                  style: TextStyle(color: grey, fontSize: 11)),
              // 停售名枪鉴赏：首页下方的大类入口。
              const SizedBox(height: 24),
              Text(tr('legends'),
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: ink)),
              const SizedBox(height: 4),
              Text('已停产的经典名枪，与它们背后的历史和事件',
                  style: TextStyle(color: grey, fontSize: 13)),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  tapHaptic();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const LegendListScreen()),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('走进停售名枪的陈列室',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: ink)),
                            const SizedBox(height: 4),
                            Text(
                                'M1 加兰德、Kar98k、STG44、汤普森……共 ${legends.length} 支',
                                style:
                                    TextStyle(color: grey, fontSize: 13)),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: grey),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
