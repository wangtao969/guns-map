import 'package:flutter/material.dart';
import '../data.dart';
import '../widgets/app_top_bar.dart';
import '../i18n.dart';

/// 组件供应商子页：从复装页独立出来，避免长列表挡住下面内容。
class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  String? _kind;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final grey = dark ? const Color(0xFF8A8578) : const Color(0xFF9A917F);
    const kinds = ['弹头', '弹壳', '火药', '底火'];
    final components = _kind == null
        ? reloadComponents
        : reloadComponents.where((c) => c.kind == _kind).toList();
    return Scaffold(
      appBar: SubPageAppBar(title: '组件供应商'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text('组件供应商 · 共 ${reloadComponents.length} 条',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
                '价格为 2026 年 10 月查到的美国零售参考价，仅供参考；价格与手册装药数据分开展示，不要混淆。',
                style: TextStyle(color: grey, fontSize: 12)),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                ChoiceChip(
                  label: Text(tr('all')),
                  selected: _kind == null,
                  onSelected: (_) => setState(() => _kind = null),
                ),
                ...kinds.map((k) => Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: ChoiceChip(
                        label: Text(k),
                        selected: _kind == k,
                        onSelected: (_) =>
                            setState(() => _kind = _kind == k ? null : k),
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: components.length,
              itemBuilder: (context, i) {
                final c = components[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text('${c.vendor} ${c.name}'),
                    subtitle: Text(
                        '${c.spec}\n${c.feature}\n参考价：${c.price}'),
                    trailing: Chip(label: Text(c.kind)),
                    isThreeLine: true,
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
