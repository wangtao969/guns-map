import 'dart:ui' as ui;
import '../widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../community_store.dart';
import '../data.dart';
import '../models.dart';
import '../i18n.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/community_theme.dart';
import '../widgets/scale_tap.dart';
import 'community_account_dialogs.dart';
import 'gun_picker_dialog.dart';

/// 我的收藏柜：登记拥有 / 上手过 / 想收集的枪，一键生成收藏柜卡面分享。
/// 卡面用 dart:ui 手绘成 PNG，走 gunsmap/share 的 shareImage 通道发出。
class CommunityCollectionScreen extends StatelessWidget {
  const CommunityCollectionScreen({super.key});

  static const _shareChannel = MethodChannel('gunsmap/share');

  Future<String?> _pickStatus(
      BuildContext context, String title, String subtitle) {
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(subtitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop('owned'),
            child: const Text('拥有'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop('handled'),
            child: const Text('上手过'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop('wanted'),
            child: const Text('想收集'),
          ),
        ],
      ),
    );
  }

  Future<void> _addGun(BuildContext context) async {
    final gun = await showGunPickerDialog(context);
    if (gun == null || !context.mounted) return;
    final status = await _pickStatus(
        context, gun.name, '${gun.vendor} · ${gun.caliber}');
    if (status == null || !context.mounted) return;
    communityStore.addCollectionItem(CollectionItem(
      gunName: gun.name,
      vendor: gun.vendor,
      caliber: gun.caliber,
      category: gun.category,
      status: status,
    ));
    showAppToast(context, '已登记到收藏柜 +3 经验');
  }

  /// 登记一件配件：先从配件目录里搜着选（瞄具、弹道计算器等 163 条），
  /// 目录里没有的（如测速仪）可手动登记名称、厂商、类型，不现编目录数据。
  Future<void> _addAccessory(BuildContext context) async {
    final picked = await showDialog<Object>(
      context: context,
      builder: (dialogContext) {
        var query = '';
        return StatefulBuilder(
          builder: (ctx, setState) {
            final q = query.trim().toLowerCase();
            final list = q.isEmpty
                ? accessories
                : accessories
                    .where((a) =>
                        a.name.toLowerCase().contains(q) ||
                        a.vendor.toLowerCase().contains(q) ||
                        a.type.toLowerCase().contains(q))
                    .toList();
            return AlertDialog(
              title: const Text('登记配件'),
              content: SizedBox(
                width: double.maxFinite,
                height: 420,
                child: Column(
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        hintText: '搜索配件、厂商或类型',
                        prefixIcon: Icon(Icons.search, size: 20),
                      ),
                      onChanged: (v) => setState(() => query = v),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: list.length,
                        itemBuilder: (_, i) {
                          final a = list[i];
                          return ListTile(
                            title: Text(a.name),
                            subtitle: Text('${a.vendor} · ${a.type}'),
                            onTap: () =>
                                Navigator.of(dialogContext).pop(a),
                          );
                        },
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () =>
                          Navigator.of(dialogContext).pop('manual'),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('目录里没有，手动登记一件'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (picked == null || !context.mounted) return;
    String name;
    String vendor;
    String type;
    if (picked == 'manual') {
      final manual = await _manualAccessoryDialog(context);
      if (manual == null || !context.mounted) return;
      name = manual.$1;
      vendor = manual.$2;
      type = manual.$3;
    } else {
      final a = picked as AccessoryItem;
      name = a.name;
      vendor = a.vendor;
      type = a.type;
    }
    final status = await _pickStatus(
        context, name, [vendor, type].where((s) => s.isNotEmpty).join(' · '));
    if (status == null || !context.mounted) return;
    communityStore.addCollectionItem(CollectionItem(
      gunName: name,
      vendor: vendor,
      caliber: '',
      category: type,
      kind: 'accessory',
      status: status,
    ));
    showAppToast(context, '已登记到收藏柜 +3 经验');
  }

  Future<(String, String, String)?> _manualAccessoryDialog(
      BuildContext context) {
    final nameCtrl = TextEditingController();
    final vendorCtrl = TextEditingController();
    final typeCtrl = TextEditingController();
    return showDialog<(String, String, String)>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('手动登记配件'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameCtrl,
                decoration:
                    const InputDecoration(labelText: '配件名称 *')),
            TextField(
                controller: vendorCtrl,
                decoration: const InputDecoration(labelText: '厂商（可选）')),
            TextField(
                controller: typeCtrl,
                decoration:
                    const InputDecoration(labelText: '类型（可选，如测速仪）')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) return;
              Navigator.of(dialogContext).pop((
                nameCtrl.text.trim(),
                vendorCtrl.text.trim(),
                typeCtrl.text.trim(),
              ));
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Future<Uint8List> _drawCard(CommunityAccount me) async {
    const width = 1080.0;
    const height = 1440.0;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final bg = ui.Paint()..color = const Color(0xFFF7F2E9);
    canvas.drawRect(
        ui.Rect.fromLTWH(0, 0, width, height), bg);
    final bronze = ui.Paint()..color = const Color(0xFF6B5B3E);
    canvas.drawRect(const ui.Rect.fromLTWH(0, 0, width, 16), bronze);

    ui.Paragraph _para(String text, double size, Color color,
        {bool bold = false}) {
      final builder = ui.ParagraphBuilder(ui.ParagraphStyle(
        fontSize: size,
        fontWeight: bold ? ui.FontWeight.bold : ui.FontWeight.normal,
      ))
        ..pushStyle(ui.TextStyle(color: color))
        ..addText(text);
      final p = builder.build();
      p.layout(const ui.ParagraphConstraints(width: width - 160));
      return p;
    }

    var y = 90.0;
    final title = _para('我的收藏柜', 72, const Color(0xFF2E2A24), bold: true);
    canvas.drawParagraph(title, ui.Offset(80, y));
    y += 110;
    final sub = _para(
        '${me.nickname} · LV${me.level} ${me.tierName} · Gun\'s Map',
        40,
        const Color(0xFF6E6557));
    canvas.drawParagraph(sub, ui.Offset(80, y));
    y += 100;
    final owned = me.collection.where((c) => c.status == 'owned').length;
    final handled =
        me.collection.where((c) => c.status == 'handled').length;
    final wanted = me.collection.where((c) => c.status == 'wanted').length;
    final gunCount =
        me.collection.where((c) => c.kind == 'gun').length;
    final accCount =
        me.collection.where((c) => c.kind == 'accessory').length;
    final stat = _para(
        '共 $gunCount 把 · $accCount 件配件 · 拥有 $owned · 上手过 $handled · 想收集 $wanted',
        44,
        const Color(0xFFE86A1C),
        bold: true);
    canvas.drawParagraph(stat, ui.Offset(80, y));
    y += 120;
    for (final item in me.collection.take(16)) {
      final lv = communityStore.masteryForGun(me, item.gunName);
      final line = _para(
          item.kind == 'accessory'
              ? '· ${item.gunName}（${[item.vendor, item.category].where((s) => s.isNotEmpty).join(' · ')}）[配件]'
              : '· ${item.gunName}（${item.vendor} · ${item.caliber}）${lv > 0 ? ' · 精通${masteryNames[lv]}' : ''}',
          40,
          const Color(0xFF2E2A24));
      canvas.drawParagraph(line, ui.Offset(80, y));
      y += 64;
      if (y > height - 160) break;
    }
    final foot = _para('Gun\'s Map · 收藏完成度 $gunCount/${guns.length}',
        36, const Color(0xFF6E6557));
    canvas.drawParagraph(foot, ui.Offset(80, height - 110));
    final picture = recorder.endRecording();
    final image = await picture.toImage(width.toInt(), height.toInt());
    final bytes =
        await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
  }

  Future<void> _shareCard(BuildContext context, CommunityAccount me) async {
    try {
      final bytes = await _drawCard(me);
      final ok = await _shareChannel.invokeMethod<bool>(
          'shareImage', {'bytes': bytes});
      if (ok != true && context.mounted) {
        final owned = me.collection.where((c) => c.status == 'owned').length;
        final gunCount =
            me.collection.where((c) => c.kind == 'gun').length;
        final accCount =
            me.collection.where((c) => c.kind == 'accessory').length;
        await _shareChannel.invokeMethod('shareText', {
          'text':
              '我的 Gun\'s Map 收藏柜：共 $gunCount 把枪、$accCount 件配件（拥有 $owned），LV${me.level} ${me.tierName}。'
        });
      }
    } catch (_) {
      if (context.mounted) {
        showAppToast(context, '分享失败，请重试');
      }
    }
  }

  String _statusName(String status) {
    switch (status) {
      case 'owned':
        return '拥有';
      case 'handled':
        return '上手过';
      default:
        return '想收集';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'owned':
        return communityAccent;
      case 'handled':
        return const Color(0xFF7FA8BC);
      default:
        return const Color(0xFF8A8D91);
    }
  }

  Widget _actionChip(Widget child, VoidCallback onTap, {bool filled = false}) {
    return ScaleTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: filled ? communityAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: filled ? communityAccent : communityAccent),
        ),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final grey = communitySecondary(dark);
    return AnimatedBuilder(
      animation: communityStore,
      builder: (_, __) {
        final me = communityStore.current;
        return Scaffold(
          appBar: SubPageAppBar(title: '我的收藏柜'),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (me == null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tr('not_logged'),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () => showLoginDialog(context),
                              child: Text(tr('login')),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: () => showRegisterDialog(context),
                              child: Text(tr('register')),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                // 柜顶总览：深铜渐变卡 + 完成度进度条 + 三态统计，不再是干巴巴的一行字。
                Builder(builder: (_) {
                  final owned = me.collection
                      .where((c) => c.status == 'owned')
                      .length;
                  final handled = me.collection
                      .where((c) => c.status == 'handled')
                      .length;
                  final wanted = me.collection
                      .where((c) => c.status == 'wanted')
                      .length;
                  final totalRounds = me.collection
                      .fold<int>(0, (s, c) => s + c.rounds);
                  // 完成度只算枪：配件不占枪械总数，否则会把进度撑大。
                  final gunCount = me.collection
                      .where((c) => c.kind == 'gun')
                      .length;
                  final accCount = me.collection
                      .where((c) => c.kind == 'accessory')
                      .length;
                  final progress = guns.isEmpty
                      ? 0.0
                      : gunCount / guns.length;
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF6B5B3E),
                          Color(0xFFE86A1C),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.inventory_2_outlined,
                                color: Colors.white),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '收藏完成度 $gunCount / ${guns.length}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.white),
                              ),
                            ),
                            Text('${(progress * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.3),
                            valueColor:
                                const AlwaysStoppedAnimation(Colors.white),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _statChip('拥有 $owned'),
                            _statChip('上手过 $handled'),
                            _statChip('想收集 $wanted'),
                            _statChip('配件 $accCount 件'),
                            _statChip('已打 $totalRounds 发'),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _actionChip(
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, size: 18, color: communityAccent),
                          SizedBox(width: 4),
                          Text('登记一把',
                              style: TextStyle(color: communityAccent)),
                        ],
                      ),
                      () => _addGun(context),
                    ),
                    _actionChip(
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, size: 18, color: communityAccent),
                          SizedBox(width: 4),
                          Text('登记配件',
                              style: TextStyle(color: communityAccent)),
                        ],
                      ),
                      () => _addAccessory(context),
                    ),
                    _actionChip(
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.share_outlined,
                              size: 18, color: Colors.white),
                          SizedBox(width: 4),
                          Text('分享卡面',
                              style: TextStyle(color: Colors.white)),
                        ],
                      ),
                      () => _shareCard(context, me),
                      filled: true,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                for (final status in ['owned', 'handled', 'wanted']) ...[
                  Builder(builder: (_) {
                    final items = me.collection
                        .where((c) => c.status == status)
                        .toList();
                    final sc = _statusColor(status);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                    color: sc, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Text(
                                '${_statusName(status)}（${items.length}）',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (items.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text('还没有登记这一类',
                                style: TextStyle(color: grey)),
                          )
                        else
                          ...items.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final item = entry.value;
                            final lv = communityStore
                                .masteryForGun(me, item.gunName);
                            return TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: Duration(
                                  milliseconds: 220 + idx * 60),
                              builder: (_, v, child) => Opacity(
                                opacity: v,
                                child: Transform.translate(
                                  offset: Offset(0, (1 - v) * 12),
                                  child: child,
                                ),
                              ),
                              child: Card(
                                margin:
                                    const EdgeInsets.only(bottom: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 4,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color: sc,
                                          borderRadius:
                                              BorderRadius.circular(2),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(item.gunName,
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold,
                                                    fontSize: 15)),
                                            const SizedBox(height: 2),
                                            Text(
                                                item.kind == 'accessory'
                                                    ? '配件 · ${[item.vendor, item.category].where((s) => s.isNotEmpty).join(' · ')}'
                                                    : '${item.vendor} · ${item.caliber} · ${item.category}',
                                                style: TextStyle(
                                                    color: grey,
                                                    fontSize: 12)),
                                            // 配件只挂一个“配件”小标签，不记弹数、不算精通。
                                            if (item.kind == 'accessory') ...[
                                              const SizedBox(height: 6),
                                              Wrap(
                                                spacing: 6,
                                                children: [
                                                  _miniChip('配件', grey),
                                                ],
                                              ),
                                            ] else if (lv > 0 ||
                                                item.rounds > 0) ...[
                                              const SizedBox(height: 6),
                                              Wrap(
                                                spacing: 6,
                                                children: [
                                                  if (lv > 0)
                                                    _miniChip(
                                                        '精通${masteryNames[lv]}',
                                                        communityAccent),
                                                  if (item.rounds > 0)
                                                    _miniChip(
                                                        '已打 ${item.rounds} 发',
                                                        grey),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        onSelected: (v) {
                                          if (v == 'delete') {
                                            communityStore
                                                .removeCollectionItem(
                                                    item.gunName);
                                          } else if (v == 'rounds10') {
                                            communityStore
                                                .addCollectionRounds(
                                                    item.gunName, 10);
                                          } else if (v == 'rounds50') {
                                            communityStore
                                                .addCollectionRounds(
                                                    item.gunName, 50);
                                          } else if (v ==
                                              'rounds_clear') {
                                            communityStore
                                                .clearCollectionRounds(
                                                    item.gunName);
                                          } else {
                                            communityStore
                                                .setCollectionStatus(
                                                    item.gunName, v);
                                          }
                                        },
                                        itemBuilder: (_) => [
                                          const PopupMenuItem(
                                              value: 'owned',
                                              child: Text('改成拥有')),
                                          const PopupMenuItem(
                                              value: 'handled',
                                              child: Text('改成上手过')),
                                          const PopupMenuItem(
                                              value: 'wanted',
                                              child: Text('改成想收集')),
                                          // 弹数菜单只给枪：配件没有弹数。
                                          if (item.kind == 'gun') ...[
                                            const PopupMenuItem(
                                                value: 'rounds10',
                                                child: Text('弹数 +10 发')),
                                            const PopupMenuItem(
                                                value: 'rounds50',
                                                child: Text('弹数 +50 发')),
                                            const PopupMenuItem(
                                                value: 'rounds_clear',
                                                child: Text('弹数清零')),
                                          ],
                                          const PopupMenuItem(
                                              value: 'delete',
                                              child: Text('删除')),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        const SizedBox(height: 8),
                      ],
                    );
                  }),
                ],
                Text(
                  '精通等级：想收集 = 了解，上手过 = 熟悉，拥有 = 上手，拥有且发过该枪动态或记过该枪成绩 = 精通；5 级权威需词条维护权限，接后端后开放。',
                  style: TextStyle(color: grey, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Text(
                  '配件登记：点“登记配件”可从配件目录选一件，或手动登记目录里没有的配件（如测速仪）；配件不记弹数与精通。',
                  style: TextStyle(color: grey, fontSize: 12),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _statChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(label,
          style: const TextStyle(color: Colors.white, fontSize: 12)),
    );
  }

  Widget _miniChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11)),
    );
  }
}
