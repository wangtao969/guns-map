import 'package:flutter/material.dart';
import '../data.dart';
import '../haptics.dart';
import '../i18n.dart';
import '../models.dart';
import '../widgets/parametric_silhouette.dart';
import '../widgets/family_diagram.dart';
import '../widgets/app_top_bar.dart';
import 'gun_compare_screen.dart';
import 'dope_screen.dart';

class GunDetailScreen extends StatefulWidget {
  final Gun gun;
  const GunDetailScreen({super.key, required this.gun});

  @override
  State<GunDetailScreen> createState() => _GunDetailScreenState();
}

class _GunDetailScreenState extends State<GunDetailScreen> {
  final Set<String> _assembled = {};

  static const _hotspots = [
    ('枪口', '枪口装置安装位置，可装消音器或制退器', 0.08, 0.42),
    ('瞄具', '导轨上的瞄准装置安装位置', 0.38, 0.18),
    ('弹匣', '供弹具位置', 0.45, 0.62),
    ('扳机', '击发机构', 0.55, 0.55),
    ('枪托', '抵肩部位', 0.88, 0.45),
  ];

  @override
  Widget build(BuildContext context) {
    final gun = widget.gun;
    // 图区三层：实物照片 > 族系识别图 > 参数化轮廓。
    final diagramKey = familyDiagramOf(gun);
    final diagramInfo =
        diagramKey == null ? null : familyDiagramInfo[diagramKey];
    return Scaffold(
      appBar: SubPageAppBar(title: gun.name),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // 图区：静态展示，热点可点看部位说明
          Container(
            height: 220,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black
                  : const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                Center(
                  child: gun.image != null
                        ? Image.asset(gun.image!, fit: BoxFit.contain)
                        : diagramKey != null
                            ? FamilyDiagram(
                                family: diagramKey,
                                width: MediaQuery.of(context).size.width -
                                    72,
                                height:
                                    (MediaQuery.of(context).size.width -
                                            72) *
                                        0.5,
                              )
                            : ParametricSilhouette(
                                gun: gun,
                                width: MediaQuery.of(context).size.width -
                                    72,
                                height:
                                    (MediaQuery.of(context).size.width -
                                            72) *
                                        0.44,
                              ),
                ),
                for (final h in _hotspots)
                  Positioned(
                    left: MediaQuery.of(context).size.width * h.$3 - 14,
                    top: 220 * h.$4 - 14,
                    child: GestureDetector(
                      onTap: () => showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text(h.$1),
                          content: Text(h.$2),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(tr('got_it')),
                            ),
                          ],
                        ),
                      ),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: Colors.amber,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add,
                            size: 18, color: Colors.black),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (gun.image == null)
            if (diagramInfo != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('族系识别图 · ${diagramInfo.$1}：图中为该族系的标志性特征，非本枪实物。',
                      style:
                          const TextStyle(color: Colors.grey, fontSize: 12)),
                  for (final p in diagramInfo.$2)
                    Text('· $p',
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 12)),
                ],
              )
            else
              const Text(
                  '注：本枪暂无实物照片，当前为按全长与枪管长比例生成的示意轮廓，非实物。',
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
          if (_assembled.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 6,
                children: _assembled
                    .map((a) => Chip(
                        label: Text('${tr('assembled_prefix')}$a'),
                        backgroundColor: Colors.amber.withOpacity(0.2)))
                    .toList(),
              ),
            ),
          const SizedBox(height: 12),
          Text(gun.name,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text('${gun.vendor} · ${gun.caliber}',
              style: const TextStyle(color: Colors.grey, fontSize: 16)),
          if (gun.nameEn != null)
            Text(gun.nameEn!,
                style: const TextStyle(color: Colors.grey, fontSize: 14)),
          if (gun.price != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('大约价格：${gun.price}（美国零售参考价）',
                  style: const TextStyle(color: Colors.grey, fontSize: 14)),
            ),
          const SizedBox(height: 12),
          Text(tr('params'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          _spec('口径', gun.caliber),
          _spec('枪机方式', gun.action),
          _spec('枪管长度', gun.barrel),
          _spec('全长', gun.length),
          _spec('空枪重', gun.weight),
          _spec('弹容', gun.capacity),
          _spec('产地', gun.origin),
          _spec('年份', gun.year),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GunCompareScreen(initialGun: gun),
              ),
            ),
            icon: const Icon(Icons.compare_arrows, size: 18),
            label: const Text('和另一把对比'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DopeScreen(gun: gun),
              ),
            ),
            icon: const Icon(Icons.book_outlined, size: 18),
            label: const Text('DOPE数据本'),
          ),
          const SizedBox(height: 12),
          Text(tr('intro'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(gun.description),
          const SizedBox(height: 12),
          Text(tr('ammo_fit'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Wrap(
            spacing: 6,
            children:
                gun.ammo.map((a) => Chip(label: Text(a))).toList(),
          ),
          const SizedBox(height: 12),
          Builder(
            builder: (context) {
              // 工厂弹售价：按本枪适配弹药口径，从口径图鉴取已核实的参考价。
              final priced = <({String caliber, String price})>[];
              for (final a in gun.ammo) {
                for (final c in caliberInfos) {
                  if (c.caliber == a && c.factoryPrice != null) {
                    priced.add((caliber: a, price: c.factoryPrice!));
                  }
                }
              }
              if (priced.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr('factory_price'),
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  ...priced.map((p) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                                width: 110,
                                child: Text(p.caliber,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold))),
                            Expanded(child: Text(p.price)),
                          ],
                        ),
                      )),
                  const Text('美国零售参考价，随商家与批次浮动，以下单时标价为准。',
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Text(tr('accessories_pick'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ...gun.accessories.map((a) => ListTile(
                title: Text(a),
                trailing: _assembled.contains(a)
                    ? Text(tr('assembled'), style: TextStyle(color: Colors.amber))
                    : TextButton(
                        onPressed: () =>
                            setState(() => _assembled.add(a)),
                        child: Text(tr('preview')),
                      ),
                onTap: () {
                  tapHaptic();
                  setState(() {
                    if (_assembled.contains(a)) {
                      _assembled.remove(a);
                    } else {
                      _assembled.add(a);
                    }
                  });
                },
              )),
        ],
      ),
    );
  }

  Widget _spec(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            SizedBox(
                width: 80,
                child: Text(k, style: const TextStyle(color: Colors.grey))),
            Expanded(child: Text(v)),
          ],
        ),
      );
}
