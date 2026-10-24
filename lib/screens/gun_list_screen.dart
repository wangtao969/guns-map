import 'package:flutter/material.dart';
import '../data.dart';
import 'gun_detail_screen.dart';

class GunListScreen extends StatelessWidget {
  final String category;
  const GunListScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final list = guns.where((g) => g.category == category).toList();
    return Scaffold(
      appBar: AppBar(title: Text(category)),
      body: ListView.builder(
        itemCount: list.length,
        itemBuilder: (context, i) {
          final g = list[i];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: g.image != null
                  ? Image.asset(g.image!, width: 90, fit: BoxFit.contain)
                  : const Icon(Icons.image_not_supported, size: 40),
              title: Text(g.name),
              subtitle: Text('${g.vendor} · ${g.caliber}'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => GunDetailScreen(gun: g)),
              ),
            ),
          );
        },
      ),
    );
  }
}
