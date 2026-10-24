import 'package:flutter/material.dart';
import '../data.dart';
import '../haptics.dart';
import '../i18n.dart';
import '../models.dart';
import '../widgets/app_top_bar.dart';
import 'suppliers_screen.dart';
import 'reload_log_screen.dart';

/// 复装页三个板块：
/// 一、子弹口径图鉴（可搜索、可按弹种分组，卡片标题直接显示关键尺寸）；
/// 二、子弹复装（只做狙击步枪常用口径，实际复装以贵价狙击弹为主）；
/// 三、入口区：组件供应商与复装记录 SOP 各进一个子页，不再用长列表挡内容。
class ReloadingScreen extends StatefulWidget {
  const ReloadingScreen({super.key});

  @override
  State<ReloadingScreen> createState() => _ReloadingScreenState();
}

class _ReloadingScreenState extends State<ReloadingScreen> {
  String _query = '';
  String _group = '全部';

  /// 狙击步枪常用复装口径。
  static const _sniperCalibers = {
    '.308 Winchester',
    '6.5 Creedmoor',
    '.300 Winchester Magnum',
    '.338 Lapua Magnum',
    '.338 Norma Magnum',
    '.300 PRC',
    '.50 BMG',
  };

  static const _pistolCalibers = {
    '9×19mm',
    '.45 ACP',
    '.380 ACP',
    '.38 Special',
    '.357 Magnum',
    '.44 Magnum',
    '.22 LR',
  };

  static String _atlasGroup(CaliberInfo c) {
    final n = c.caliber;
    if (n.contains('霰弹')) return '霰弹';
    if (_pistolCalibers.contains(n)) return '手枪弹';
    if (n.contains('Magnum') ||
        n.contains('PRC') ||
        n.contains('CheyTac') ||
        n.contains('.50 BMG') ||
        n.contains('7mm Remington')) {
      return '马格南';
    }
    return '步枪弹';
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final grey = dark ? const Color(0xFF8A8578) : const Color(0xFF9A917F);
    final bronze = dark ? const Color(0xFFC9A86A) : const Color(0xFF6B5B3E);
    final sniper = reloadCalibers
        .where((c) => _sniperCalibers.contains(c.caliber))
        .toList();
    final q = _query.trim().toLowerCase();
    final atlas = caliberInfos.where((c) {
      if (_group != '全部' && _atlasGroup(c) != _group) return false;
      if (q.isEmpty) return true;
      if (c.caliber.toLowerCase().contains(q)) return true;
      return c.bullets.any((b) => b.toLowerCase().contains(q));
    }).toList();
    return Scaffold(
      appBar: const GunsMapAppBar(),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            color: Color(0xFF4A1500),
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('⚠ ${tr('safety_warn')}',
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
          // 板块一：子弹口径图鉴。
          Text(tr('caliber_atlas'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(tr('atlas_note'),
              style: TextStyle(color: grey, fontSize: 12)),
          const SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(
              hintText: tr('search_caliber_hint'),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _query = ''),
                    ),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: ['全部', '手枪弹', '步枪弹', '马格南', '霰弹']
                .map((g) => FilterChip(
                      label: Text(g),
                      selected: _group == g,
                      onSelected: (_) => setState(() => _group = g),
                    ))
                .toList(),
          ),
          const SizedBox(height: 4),
          Text(atlasCountText(atlas.length),
              style: TextStyle(color: grey, fontSize: 12)),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.92,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: atlas.length,
            itemBuilder: (context, i) {
              final c = atlas[i];
              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    tapHaptic();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => CaliberDetailScreen(info: c)),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.caliber,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13)),
                        const Spacer(),
                        Text('弹头 ${c.bulletDiameter}',
                            style: TextStyle(color: grey, fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          // 板块二：子弹复装（狙击口径）。
          Text(tr('sniper_title'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(tr('sniper_note'),
              style: TextStyle(color: grey, fontSize: 12)),
          const SizedBox(height: 8),
          ...sniper.map((c) {
            final loads =
                reloadLoads.where((l) => l.caliber == c.caliber).toList();
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ExpansionTile(
                title: Text(c.caliber,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                onExpansionChanged: (_) => tapHaptic(),
                children: [
                  _section('弹头', c.bullets, bronze),
                  _section('弹壳', c.cases, bronze),
                  _section('火药', c.powders, bronze),
                  _section('底火', c.primers, bronze),
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
                      child: Text(tr('loads_title'),
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
          // 板块三：入口区，不再平铺长列表。
          Text(tr('more'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.storefront_outlined),
              title: Text(tr('suppliers')),
              subtitle: Text(suppliersCountText(reloadComponents.length),
                  style: TextStyle(color: grey, fontSize: 12)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SuppliersScreen()),
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.assignment_outlined),
              title: Text(tr('sop_title')),
              subtitle: Text(tr('sop_sub'),
                  style: TextStyle(color: grey, fontSize: 12)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReloadLogScreen()),
              ),
            ),
          ),
          const SizedBox(height: 16),
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
              Text('${tr('source_prefix')}${l.source}',
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

/// 口径详情：点三列小卡片进来，尺寸、弹头、售价、适配枪械都在这里。
class CaliberDetailScreen extends StatelessWidget {
  final CaliberInfo info;
  const CaliberDetailScreen({super.key, required this.info});

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
          Text(info.caliber,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _detailRow('弹头直径', info.bulletDiameter),
          _detailRow('弹壳长度', info.caseLength),
          _detailRow('最大全弹长', info.maxOal),
          _detailRow('常用弹头重', info.bulletWeightRange),
          _detailRow('用途', info.use),
          const SizedBox(height: 16),
          Text(tr('factory_price'),
              style: TextStyle(fontWeight: FontWeight.bold, color: bronze)),
          const SizedBox(height: 4),
          Text(info.factoryPrice ?? '暂未收录',
              style: TextStyle(color: info.factoryPrice == null ? grey : null)),
          Text(tr('factory_price_note'),
              style: TextStyle(color: grey, fontSize: 12)),
          if (info.bullets.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(bulletsText(info.bullets.length),
                style: TextStyle(fontWeight: FontWeight.bold, color: bronze)),
            const SizedBox(height: 4),
            ...info.bullets.map((b) => Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text('· $b',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                )),
          ],
          const SizedBox(height: 16),
          Text(fitGunsText(info.fitGuns.length),
              style: TextStyle(fontWeight: FontWeight.bold, color: bronze)),
          const SizedBox(height: 4),
          if (info.fitGuns.isEmpty)
            Text(tr('no_guns_for_caliber'),
                style: TextStyle(color: grey)),
          if (info.fitGuns.isNotEmpty)
            Text(info.fitGuns.join('、'),
                style: TextStyle(color: grey, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _detailRow(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 80,
                child: Text(k, style: const TextStyle(color: Colors.grey))),
            Expanded(child: Text(v)),
          ],
        ),
      );
}
