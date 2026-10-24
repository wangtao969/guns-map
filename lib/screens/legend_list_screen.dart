import 'package:flutter/material.dart';
import '../data.dart';
import '../haptics.dart';
import '../widgets/app_top_bar.dart';
import 'legend_detail_screen.dart';

/// 停售名枪鉴赏列表：已停产的经典名枪。
class LegendListScreen extends StatelessWidget {
  const LegendListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final grey = dark ? const Color(0xFF8A8578) : const Color(0xFF9A917F);
    return Scaffold(
      appBar: const GunsMapAppBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('停售名枪鉴赏',
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                Text('共 ${legends.length} 支',
                    style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
              itemCount: legends.length,
        itemBuilder: (context, i) {
          final l = legends[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: l.image != null
                  ? Image.asset(l.image!,
                      width: 90, fit: BoxFit.contain)
                  : const Icon(Icons.image_not_supported,
                      size: 36, color: Color(0xFF9A917F)),
              title: Text(l.name,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                  '${l.nameEn} · ${l.vendor} · ${l.years}\n${l.caliber}',
                  style: TextStyle(color: grey)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                tapHaptic();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => LegendDetailScreen(legend: l)),
                );
              },
            ),
          );
        },
            ),
            ),
          ],
        ),
      );
  }
}
