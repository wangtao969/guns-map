import 'package:flutter/material.dart';
import '../data.dart';
import '../haptics.dart';
import '../i18n.dart';
import '../models.dart';
import '../widgets/app_top_bar.dart';

class AccessoriesScreen extends StatefulWidget {
  const AccessoriesScreen({super.key});

  @override
  State<AccessoriesScreen> createState() => _AccessoriesScreenState();
}

class _AccessoriesScreenState extends State<AccessoriesScreen> {
  String? _vendor;
  String? _type;
  String? _category;

  /// 配件按品类分：从适配枪型反查其品类，不再按具体型号筛。
  Set<String> _accessoryCategories(AccessoryItem a) {
    final cats = <String>{};
    for (final name in a.fitGuns) {
      for (final g in guns) {
        if (g.name == name) cats.add(g.category);
      }
    }
    return cats;
  }

  /// 卡片上只显示适配口径：从适配枪型反查口径并去重。
  List<String> _accessoryCalibers(AccessoryItem a) {
    final cals = <String>[];
    for (final name in a.fitGuns) {
      for (final g in guns) {
        if (g.name == name && !cals.contains(g.caliber)) {
          cals.add(g.caliber);
        }
      }
    }
    return cals;
  }

  @override
  Widget build(BuildContext context) {
    final types = accessories.map((a) => a.type).toSet().toList();
    final list = accessories.where((a) {
      if (_vendor != null && a.vendor != _vendor) return false;
      if (_type != null && a.type != _type) return false;
      if (_category != null &&
          !_accessoryCategories(a).contains(_category)) {
        return false;
      }
      return true;
    }).toList();
    return Scaffold(
      appBar: const GunsMapAppBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Text(tr('vendor'),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                ChoiceChip(
                  label: Text(tr('all')),
                  selected: _vendor == null,
                  onSelected: (_) => setState(() => _vendor = null),
                ),
                ...vendors.map((v) => Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: ChoiceChip(
                        label: Text(v),
                        selected: _vendor == v,
                        onSelected: (_) =>
                            setState(() => _vendor = _vendor == v ? null : v),
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                ChoiceChip(
                  label: Text(tr('all_types')),
                  selected: _type == null,
                  onSelected: (_) => setState(() => _type = null),
                ),
                ...types.map((t) => Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: ChoiceChip(
                        label: Text(t),
                        selected: _type == t,
                        onSelected: (_) =>
                            setState(() => _type = _type == t ? null : t),
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.fromLTRB(12, 4, 12, 4),
            child: Text(tr('by_category'),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                ChoiceChip(
                  label: Text(tr('all_categories')),
                  selected: _category == null,
                  onSelected: (_) => setState(() => _category = null),
                ),
                ...categories.map((c) => Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: ChoiceChip(
                        label: Text(c),
                        selected: _category == c,
                        onSelected: (_) => setState(
                            () => _category = _category == c ? null : c),
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.35,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: list.length,
              itemBuilder: (context, i) {
                final a = list[i];
                final cals = _accessoryCalibers(a);
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      tapHaptic();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                AccessoryDetailScreen(item: a)),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                          const Spacer(),
                          Text(
                            cals.isEmpty ? '通用' : cals.join(' · '),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
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

/// 配件详情：点卡片进来才能看到适配枪械、售价与购买渠道。
class AccessoryDetailScreen extends StatelessWidget {
  final AccessoryItem item;
  const AccessoryDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final grey = dark ? const Color(0xFF8A8578) : const Color(0xFF9A917F);
    final bronze = dark ? const Color(0xFFC9A86A) : const Color(0xFF6B5B3E);
    return Scaffold(
      appBar: const GunsMapAppBar(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(item.name,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('${item.vendor} · ${item.type}',
              style: TextStyle(color: grey)),
          const SizedBox(height: 12),
          Text(item.description),
          const SizedBox(height: 20),
          Text(tr('price'), style: TextStyle(fontWeight: FontWeight.bold, color: bronze)),
          const SizedBox(height: 4),
          Text(item.price ?? tr('not_listed'),
              style: TextStyle(color: item.price == null ? grey : null)),
          const SizedBox(height: 20),
          Text(tr('channel'),
              style: TextStyle(fontWeight: FontWeight.bold, color: bronze)),
          const SizedBox(height: 4),
          Text('${item.vendor}${tr('channel_vendor_suffix')}'),
          const SizedBox(height: 20),
          Text(fitGunsText(item.fitGuns.length),
              style: TextStyle(fontWeight: FontWeight.bold, color: bronze)),
          const SizedBox(height: 4),
          if (item.fitGuns.isEmpty)
            Text(tr('generic_unbound'), style: TextStyle(color: grey)),
          if (item.fitGuns.isNotEmpty)
            Text(item.fitGuns.join('、'),
                style: TextStyle(color: grey, fontSize: 13)),
        ],
      ),
    );
  }
}
