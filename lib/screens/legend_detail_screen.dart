import 'package:flutter/material.dart';
import '../english_terms.dart';
import '../models.dart';
import '../widgets/app_top_bar.dart';
import '../i18n.dart';

/// 名枪详情：规格 + 历史与关联事件故事。
class LegendDetailScreen extends StatelessWidget {
  final DiscontinuedLegend legend;
  const LegendDetailScreen({super.key, required this.legend});

  @override
  Widget build(BuildContext context) {
    final l = legend;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final grey = dark ? const Color(0xFF8A8578) : const Color(0xFF9A917F);
    return Scaffold(
      appBar: SubPageAppBar(title: l.nameEn),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l.nameEn,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold)),
          Text(l.name,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: grey)),
          if (l.image != null) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(l.image!, fit: BoxFit.contain),
            ),
            const SizedBox(height: 4),
            Text(tr('image_credit'),
                style: TextStyle(color: grey, fontSize: 11)),
          ],
          const SizedBox(height: 16),
          _row('Manufacturer', vendorDisplay(l.vendor)),
          _row('Caliber', l.caliber),
          _row('Year', l.years),
          const SizedBox(height: 20),
          Text(tr('legend_story'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(l.story, style: const TextStyle(fontSize: 15, height: 1.6)),
        ],
      ),
    );
  }

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 72,
                child: Text(k, style: const TextStyle(color: Colors.grey))),
            Expanded(child: Text(v)),
          ],
        ),
      );
}
