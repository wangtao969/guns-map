import 'package:flutter/material.dart';
import '../data.dart';
import '../haptics.dart';
import '../i18n.dart';
import '../models.dart';
import '../widgets/category_silhouette.dart';
import '../widgets/app_top_bar.dart';
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

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final grey = dark ? const Color(0xFF8A8578) : const Color(0xFF9A917F);
    final bronze = dark ? const Color(0xFFC9A86A) : const Color(0xFF6B5B3E);
    final ink = dark ? const Color(0xFFEDE8DF) : const Color(0xFF2E2A24);
    final cardBg = dark ? const Color(0xFF1E1C19) : Colors.white;
    final silhouette = dark ? const Color(0xFFE8E0D0) : const Color(0xFF4A4238);
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
      appBar: const GunsMapAppBar(),
      body: SafeArea(
        top: true,
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          children: [
            // 药丸形搜索框
            Container(
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
                decoration: InputDecoration(
                  hintText: tr('search_gun_hint'),
                  hintStyle: TextStyle(color: grey),
                  prefixIcon: Icon(Icons.search, color: bronze),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
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
                  childAspectRatio: 1.05,
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
                          // 剪影直接落在卡片上，不再套米色底块。
                          Center(
                            child: CategorySilhouette(
                              category: c,
                              color: silhouette,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(trCategory(c),
                              style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: ink)),
                          if (localeNotifier.value != localeEn)
                          Text(categoryEn[c] ?? '',
                              style: TextStyle(color: grey, fontSize: 11)),
                          const SizedBox(height: 2),
                          Text(countText(count),
                              style: TextStyle(color: grey, fontSize: 12)),
                          Text('${tr('prototype_prefix')}${categoryPrototype[c] ?? ''}',
                              style: TextStyle(color: grey, fontSize: 10)),
                        ],
                      ),
                    ),
                  );
                },
              ),
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
