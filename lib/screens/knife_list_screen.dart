import 'package:flutter/material.dart';
import '../haptics.dart';
import '../knife_data.dart';
import '../models.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/knife_silhouette.dart';
import 'knife_detail_screen.dart';

class KnifeListScreen extends StatefulWidget {
  const KnifeListScreen({super.key});

  @override
  State<KnifeListScreen> createState() => _KnifeListScreenState();
}

class _KnifeListScreenState extends State<KnifeListScreen> {
  String _type = '全部';
  String _country = '全部';
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final grey = dark ? const Color(0xFF8A8578) : const Color(0xFF9A917F);
    final ink = dark ? const Color(0xFFEDE8DF) : const Color(0xFF2E2A24);
    final bronze = dark ? const Color(0xFFC9A86A) : const Color(0xFF6B5B3E);
    final cardBg = dark ? const Color(0xFF1E1C19) : Colors.white;
    final q = _query.trim().toLowerCase();
    final filtered = knives.where((k) {
      if (_type != '全部' && k.type != _type) return false;
      if (_country != '全部' && k.country != _country) return false;
      if (q.isEmpty) return true;
      return k.name.toLowerCase().contains(q) ||
          k.nameEn.toLowerCase().contains(q) ||
          k.country.toLowerCase().contains(q) ||
          k.type.toLowerCase().contains(q);
    }).toList();
    return Scaffold(
      appBar: const SubPageAppBar(title: '刀具图鉴'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
        children: [
          TextField(
            decoration: const InputDecoration(
              hintText: '搜索刀具、国家或分类',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['全部', ...knifeTypes].map((t) {
              final selected = _type == t;
              return ChoiceChip(
                label: Text(t),
                selected: selected,
                selectedColor: bronze,
                labelStyle: TextStyle(
                    color: selected
                        ? Colors.white
                        : (dark ? ink : const Color(0xFF2E2A24))),
                onSelected: (_) => setState(() => _type = t),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['全部', ...knifeCountries].map((c) {
              final selected = _country == c;
              return ChoiceChip(
                label: Text(c),
                selected: selected,
                selectedColor: bronze,
                labelStyle: TextStyle(
                    color: selected
                        ? Colors.white
                        : (dark ? ink : const Color(0xFF2E2A24))),
                onSelected: (_) => setState(() => _country = c),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Text('共 ${filtered.length} 把 · 示意图为刀形剪影，非实物照片',
              style: TextStyle(color: grey, fontSize: 12)),
          const SizedBox(height: 12),
          ...filtered.map((k) => _knifeRow(context, k, cardBg, grey, ink)),
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Center(child: Text('没有找到相关刀具', style: TextStyle(color: grey))),
            ),
        ],
      ),
    );
  }

  Widget _knifeRow(
      BuildContext context, Knife k, Color cardBg, Color grey, Color ink) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: SizedBox(
          width: 64,
          height: 32,
          child: KnifeSilhouette(
              type: k.type,
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFFC9A86A)
                  : const Color(0xFF6B5B3E)),
        ),
        title: Text(k.name),
        subtitle: Text('${k.country} · ${k.type} · 刃长 ${k.bladeLength}',
            maxLines: 1, overflow: TextOverflow.ellipsis),
        onTap: () {
          tapHaptic();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => KnifeDetailScreen(knife: k)),
          );
        },
      ),
    );
  }
}
