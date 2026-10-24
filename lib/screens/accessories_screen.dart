import 'package:flutter/material.dart';
import '../data.dart';
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
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Text('厂商',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('全部'),
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
                  label: const Text('全部类型'),
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
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 4, 12, 4),
            child: Text('按品类',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('全部品类'),
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
            child: ListView.builder(
              itemCount: list.length,
              itemBuilder: (context, i) {
                final a = list[i];
                return ListTile(
                  title: Text(a.name),
                  subtitle: Text(
                      '${a.vendor} · ${a.description}\n适配：${a.fitGuns.join('、')}'),
                  trailing: Chip(label: Text(a.type)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
