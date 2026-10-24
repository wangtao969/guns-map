import 'package:flutter/material.dart';
import '../data.dart';
import '../models.dart';
import 'gun_detail_screen.dart';

/// 品类内页：按厂商分组，每个厂商一个可折叠分区，分区内是该厂商的型号。
class GunListScreen extends StatelessWidget {
  final String category;
  const GunListScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final list = guns.where((g) => g.category == category).toList();
    final Map<String, List<Gun>> byVendor = {};
    for (final g in list) {
      byVendor.putIfAbsent(g.vendor, () => []).add(g);
    }
    final vendors = byVendor.keys.toList()..sort();
    return Scaffold(
      appBar: AppBar(title: Text(category)),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
        itemCount: vendors.length,
        itemBuilder: (context, i) {
          final vendor = vendors[i];
          final models = byVendor[vendor]!;
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Theme(
              data: Theme.of(context)
                  .copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                initiallyExpanded: vendors.length <= 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Text(vendor,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${models.length} 款在售',
                    style: const TextStyle(color: Color(0xFF9A917F))),
                children: models
                    .map((g) => ListTile(
                          leading: g.image != null
                              ? Image.asset(g.image!,
                                  width: 90, fit: BoxFit.contain)
                              : const Icon(Icons.image_not_supported,
                                  size: 36, color: Color(0xFF9A917F)),
                          title: Text(g.name),
                          subtitle: Text(g.caliber),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => GunDetailScreen(gun: g)),
                          ),
                        ))
                    .toList(),
              ),
            ),
          );
        },
      ),
    );
  }
}
