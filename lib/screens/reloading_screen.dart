import 'package:flutter/material.dart';
import '../data.dart';
import '../models.dart';
import '../widgets/app_top_bar.dart';

class ReloadingScreen extends StatefulWidget {
  const ReloadingScreen({super.key});

  @override
  State<ReloadingScreen> createState() => _ReloadingScreenState();
}

class _ReloadingScreenState extends State<ReloadingScreen> {
  String? _kind;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final grey = dark ? const Color(0xFF8A8578) : const Color(0xFF9A917F);
    final bronze = dark ? const Color(0xFFC9A86A) : const Color(0xFF6B5B3E);
    final kinds = ['弹头', '弹壳', '火药', '底火'];
    final components = _kind == null
        ? reloadComponents
        : reloadComponents.where((c) => c.kind == _kind).toList();
    return Scaffold(
      appBar: const GunsMapAppBar(),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const Card(
            color: Color(0xFF4A1500),
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('⚠ 安全警告',
                      style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  SizedBox(height: 6),
                  Text(
                    '· 务必从起始装药开始，逐步试射并观察压力迹象，绝不超过手册最大装药。\n'
                    '· 不同批次火药需重新验证，不可直接沿用旧数据。\n'
                    '· 务必以纸质手册原文为准，本 App 数据仅供学习参考。\n'
                    '· 装药数据按弹膛标识选用：.223 Remington 与 5.56×45mm NATO 的手册数据不可混用。\n'
                    '· 本页未收录的口径与组合，均为未找到可靠公开手册出处而刻意省略，切勿自行推算补写。',
                    style: TextStyle(color: Colors.amber),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('口径参考',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...caliberInfos.map((c) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ExpansionTile(
                  title: Text(c.caliber,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  children: [
                    _infoRow('弹头直径', c.bulletDiameter),
                    _infoRow('常用弹头重', c.bulletWeightRange),
                    _infoRow('用途', c.use),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('适配枪械',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, color: bronze)),
                          const SizedBox(height: 4),
                          if (c.fitGuns.isEmpty)
                            Text('本 App 图鉴中暂无该口径枪械',
                                style: TextStyle(color: grey)),
                          if (c.fitGuns.isNotEmpty)
                            Wrap(
                              spacing: 6,
                              children: c.fitGuns
                                  .map((g) => Chip(label: Text(g)))
                                  .toList(),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 16),
          const Text('复装组件与装药表',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...reloadCalibers.map((c) {
            final loads =
                reloadLoads.where((l) => l.caliber == c.caliber).toList();
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ExpansionTile(
                title: Text(c.caliber,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                children: [
                  _section('弹头', c.bullets, bronze),
                  _section('弹壳', c.cases, bronze),
                  _section('火药', c.powders, bronze),
                  _section('底火', c.primers, bronze),
                  if (c.caliber == '.223 Remington')
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Text(
                        '注意：本节为 .223 Remington 手册数据，不可直接套用于 5.56×45mm NATO 弹膛。',
                        style: TextStyle(color: Colors.amber),
                      ),
                    ),
                  if (loads.isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Text(
                        '本口径暂无经核实的公开手册装药数据，装药表已刻意省略，请以纸质手册原文为准。',
                        style: TextStyle(color: grey),
                      ),
                    ),
                  if (loads.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                      child: Text('装药表（公开手册数据）',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: bronze)),
                    ),
                    ...loads.map((l) => _loadCard(l)),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
          // 组件供应商：弹头 / 弹壳 / 火药 / 底火四个分类。
          const Text('组件供应商',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('价格为 2026 年 10 月查到的美国零售参考价，仅供参考；价格与手册装药数据分开展示，不要混淆。',
              style: TextStyle(color: grey, fontSize: 12)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('全部'),
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
          ...components.map((c) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text('${c.vendor} ${c.name}'),
                  subtitle:
                      Text('${c.spec}\n${c.feature}\n参考价：${c.price}'),
                  trailing: Chip(label: Text(c.kind)),
                  isThreeLine: true,
                ),
              )),
          const SizedBox(height: 16),
          // 复装流程 SOP：单独的分类。
          const Text('复装流程 SOP',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...reloadSopSteps.asMap().entries.map((e) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: bronze,
                    foregroundColor: dark
                        ? const Color(0xFF121110)
                        : Colors.white,
                    child: Text('${e.key + 1}'),
                  ),
                  title: Text(e.value),
                ),
              )),
          const SizedBox(height: 16),
          const Text('安全红线',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            color: const Color(0xFF4A1500),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: reloadSafetyRules
                    .map((r) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text('· $r',
                              style:
                                  const TextStyle(color: Colors.amber)),
                        ))
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                '数据来源说明：本页装药数据均引自 Hornady、Speer、Nosler、Hodgdon、Vihtavuori、Lyman 等公开出版手册与官方数据页，各条标注出处；未引述的字段以“手册未载”标示；未经核实的组合一律未收录。组件价格为 2026 年 10 月美国零售参考价，随时变动，以下单时商家标价为准。',
                style: TextStyle(color: grey, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String k, String v) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Row(
          children: [
            SizedBox(
                width: 80,
                child: Text(k, style: const TextStyle(color: Colors.grey))),
            Expanded(child: Text(v)),
          ],
        ),
      );

  Widget _section(String title, List<String> items, Color bronze) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(fontWeight: FontWeight.bold, color: bronze)),
            ...items.map((e) => Padding(
                  padding: const EdgeInsets.only(top: 2, left: 8),
                  child: Text('· $e'),
                )),
          ],
        ),
      );

  Widget _loadCard(ReloadLoad l) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${l.bullet} · ${l.powder}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              _loadRow('起始装药', l.startCharge),
              _loadRow('最大装药', l.maxCharge),
              _loadRow('弹长 COL', l.col),
              _loadRow('底火', l.primer),
              _loadRow('弹壳', l.brass),
              if (l.velocity != null) _loadRow('初速', l.velocity!),
              if (l.pressure != null) _loadRow('膛压', l.pressure!),
              const SizedBox(height: 4),
              Text('来源：${l.source}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
      );

  Widget _loadRow(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Row(
          children: [
            SizedBox(
                width: 72,
                child: Text(k, style: const TextStyle(color: Colors.grey))),
            Expanded(child: Text(v)),
          ],
        ),
      );
}
