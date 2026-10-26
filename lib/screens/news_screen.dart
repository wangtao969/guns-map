import 'package:flutter/material.dart';
import '../widgets/app_toast.dart';
import '../news_data.dart';
import '../system_actions.dart';
import '../widgets/app_top_bar.dart';

/// 枪械资讯页：枪械商与弹药商的公开报道快照，点开跳转原文。
/// 本地静态快照，不做实时更新；页脚已明示整理时间与来源性质。
class NewsScreen extends StatelessWidget {
  const NewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bronze = dark ? const Color(0xFFC9A86A) : const Color(0xFF6B5B3E);
    final grey = dark ? const Color(0xFF8A8578) : const Color(0xFF9A917F);
    final firearms = newsItems.where((n) => n.category == 'firearm').toList();
    final ammo = newsItems.where((n) => n.category == 'ammo').toList();
    return Scaffold(
      appBar: const SubPageAppBar(title: '枪械资讯'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        children: [
          _section('枪械厂商', firearms, bronze, grey, context),
          const SizedBox(height: 20),
          _section('弹药商', ammo, bronze, grey, context),
          const SizedBox(height: 20),
          Text(
            '本页为 2026-10-25 整理的公开报道快照，标题与摘要只转述报道要点；点开跳转原文查看完整内容与最新进展，不做实时更新。',
            style: TextStyle(color: grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, List<NewsItem> items, Color bronze,
      Color grey, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...items.map((n) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () async {
                  final ok = await openSystemUrl(n.url);
                  if (!ok && context.mounted) {
                    showAppToast(context, '未能打开浏览器');
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: bronze,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              n.publisher,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? const Color(0xFF000000)
                                    : Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(n.date,
                              style: TextStyle(color: grey, fontSize: 12)),
                          const Spacer(),
                          Icon(Icons.open_in_new, size: 16, color: grey),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(n.title,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(n.summary,
                          style: TextStyle(color: grey, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            )),
      ],
    );
  }
}
