import 'package:flutter/material.dart';
import '../data.dart';
import '../models.dart';

class ReloadingScreen extends StatelessWidget {
  const ReloadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('复装手册')),
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
                    '· 本页未收录的口径与组合，均为未找到可靠 Hornady 原文出处而刻意省略，切勿自行推算补写。',
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
                          const Text('适配枪械',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber)),
                          const SizedBox(height: 4),
                          if (c.fitGuns.isEmpty)
                            const Text('本 App 图鉴中暂无该口径枪械',
                                style: TextStyle(color: Colors.grey)),
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
                  _section('弹头', c.bullets),
                  _section('弹壳', c.cases),
                  _section('火药', c.powders),
                  _section('底火', c.primers),
                  if (c.caliber == '.223 Remington')
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Text(
                        '注意：本节为 .223 Remington 手册数据，不可直接套用于 5.56×45mm NATO 弹膛。',
                        style: TextStyle(color: Colors.amber),
                      ),
                    ),
                  if (loads.isEmpty)
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Text(
                        '本口径暂无经核实的 Hornady 手册装药数据，装药表已刻意省略，请以纸质手册原文为准。',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  if (loads.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 4),
                      child: Text('装药表（Hornady 手册数据）',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber)),
                    ),
                    ...loads.map((l) => _loadCard(l)),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                '数据来源说明：本页装药数据均引自 Hornady Handbook 公开出版数据，各条标注版本与章节；未引述的字段以“详见手册原文”标示；未经核实的组合一律未收录。Hodgdon、Vihtavuori 等其他厂商数据未列入本页。',
                style: TextStyle(color: Colors.grey, fontSize: 12),
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

  Widget _section(String title, List<String> items) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.amber)),
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
