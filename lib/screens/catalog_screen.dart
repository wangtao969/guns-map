import 'package:flutter/material.dart';
import '../data.dart';
import '../models.dart';
import '../widgets/category_silhouette.dart';
import 'gun_list_screen.dart';
import 'gun_detail_screen.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
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
      body: SafeArea(
        top: true,
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          children: [
            // 药丸形搜索框
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
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
                decoration: const InputDecoration(
                  hintText: '搜索枪械、厂商、口径…',
                  hintStyle: TextStyle(color: Color(0xFF9A917F)),
                  prefixIcon: Icon(Icons.search, color: Color(0xFF6B5B3E)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
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
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => GunDetailScreen(gun: g)),
                      ),
                    ),
                  )),
              if (results.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Center(
                    child: Text('没有找到相关枪械',
                        style: TextStyle(color: Color(0xFF9A917F))),
                  ),
                ),
            ],
            if (_query.isEmpty) ...[
              const Text('枪械品类',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E2A24))),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.25,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: categories.length,
                itemBuilder: (context, i) {
                  final c = categories[i];
                  final count = guns.where((g) => g.category == c).length;
                  return InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => GunListScreen(category: c)),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
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
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFE7D8),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: CategorySilhouette(category: c),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(c,
                              style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E2A24))),
                          const SizedBox(height: 2),
                          Text('$count 支在售',
                              style: const TextStyle(
                                  color: Color(0xFF9A917F), fontSize: 12)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
