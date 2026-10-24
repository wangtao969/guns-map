import 'package:flutter/material.dart';
import '../data.dart';
import '../models.dart';
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
    final results = _query.isEmpty
        ? <Gun>[]
        : guns
            .where((g) =>
                g.name.contains(_query) ||
                g.vendor.toLowerCase().contains(_query.toLowerCase()) ||
                g.caliber.contains(_query))
            .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('枪械图鉴')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          TextField(
            decoration: const InputDecoration(
              hintText: '搜索枪械、厂商、口径…',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 12),
          if (_query.isNotEmpty)
            ...results.map((g) => ListTile(
                  title: Text(g.name),
                  subtitle: Text('${g.vendor} · ${g.caliber}'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => GunDetailScreen(gun: g)),
                  ),
                )),
          if (_query.isEmpty) ...[
            const Text('品类',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: categories.length,
              itemBuilder: (context, i) {
                final c = categories[i];
                final count = guns.where((g) => g.category == c).length;
                return InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => GunListScreen(category: c)),
                  ),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(c,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('$count 支在售',
                              style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            const Text('全部枪械',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...guns.map((g) => ListTile(
                  title: Text(g.name),
                  subtitle: Text('${g.vendor} · ${g.caliber}'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => GunDetailScreen(gun: g)),
                  ),
                )),
          ],
        ],
      ),
    );
  }
}
