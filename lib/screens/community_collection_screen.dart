import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../community_store.dart';
import '../data.dart';
import '../i18n.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/community_theme.dart';
import 'community_account_dialogs.dart';
import 'gun_picker_dialog.dart';

/// 我的收藏柜：登记拥有 / 上手过 / 想收集的枪，一键生成收藏柜卡面分享。
/// 卡面用 dart:ui 手绘成 PNG，走 gunsmap/share 的 shareImage 通道发出。
class CommunityCollectionScreen extends StatelessWidget {
  const CommunityCollectionScreen({super.key});

  static const _shareChannel = MethodChannel('gunsmap/share');

  Future<void> _addGun(BuildContext context) async {
    final gun = await showGunPickerDialog(context);
    if (gun == null || !context.mounted) return;
    final status = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(gun.name),
        content: Text('${gun.vendor} · ${gun.caliber}'),
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
    if (status == null || !context.mounted) return;
    communityStore.addCollectionItem(CollectionItem(
      gunName: gun.name,
      vendor: gun.vendor,
      caliber: gun.caliber,
      category: gun.category,
      status: status,
    ));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已登记到收藏柜 +3 经验')),
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
    final stat = _para(
        '共 ${me.collection.length} 把 · 拥有 $owned · 上手过 $handled · 想收集 $wanted',
        44,
        const Color(0xFFE86A1C),
        bold: true);
    canvas.drawParagraph(stat, ui.Offset(80, y));
    y += 120;
    for (final item in me.collection.take(16)) {
      final lv = communityStore.masteryForGun(me, item.gunName);
      final line = _para(
          '· ${item.gunName}（${item.vendor} · ${item.caliber}）${lv > 0 ? ' · 精通${masteryNames[lv]}' : ''}',
          40,
          const Color(0xFF2E2A24));
      canvas.drawParagraph(line, ui.Offset(80, y));
      y += 64;
      if (y > height - 160) break;
    }
    final foot = _para('Gun\'s Map · 收藏完成度 ${me.collection.length}/${guns.length}',
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
        await _shareChannel.invokeMethod('shareText', {
          'text':
              '我的 Gun\'s Map 收藏柜：共 ${me.collection.length} 把（拥有 $owned），LV${me.level} ${me.tierName}。'
        });
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('分享失败，请重试')),
        );
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
              Row(
                children: [
                  const Spacer(),
                  if (me != null)
                    OutlinedButton.icon(
                      onPressed: () => _shareCard(context, me),
                      icon: const Icon(Icons.share_outlined, size: 18),
                      label: const Text('分享卡面'),
                    ),
                ],
              ),
              const SizedBox(height: 12),
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
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        const Icon(Icons.inventory_2_outlined,
                            color: communityAccent),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '收藏完成度 ${me.collection.length} / ${guns.length}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () => _addGun(context),
                          child: const Text('登记一把'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                for (final status in ['owned', 'handled', 'wanted']) ...[
                  Builder(builder: (_) {
                    final items = me.collection
                        .where((c) => c.status == status)
                        .toList();
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ExpansionTile(
                        initiallyExpanded: true,
                        title: Text(
                            '${_statusName(status)}（${items.length}）',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                        children: items.isEmpty
                            ? [
                                const ListTile(
                                    title: Text('还没有登记这一类的枪'))
                              ]
                            : items.map((item) {
                                final lv = communityStore
                                    .masteryForGun(me, item.gunName);
                                return ListTile(
                                  title: Text(item.gunName),
                                  subtitle: Text(
                                      '${item.vendor} · ${item.caliber} · ${item.category}${lv > 0 ? ' · 精通${masteryNames[lv]}' : ''}'),
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (v) {
                                      if (v == 'delete') {
                                        communityStore.removeCollectionItem(
                                            item.gunName);
                                      } else {
                                        communityStore.setCollectionStatus(
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
                                      const PopupMenuItem(
                                          value: 'delete',
                                          child: Text('删除')),
                                    ],
                                  ),
                                );
                              }).toList(),
                      ),
                    );
                  }),
                ],
                const SizedBox(height: 8),
                Text(
                  '精通等级：想收集 = 了解，上手过 = 熟悉，拥有 = 上手，拥有且发过该枪动态或记过该枪成绩 = 精通；5 级权威需词条维护权限，接后端后开放。',
                  style: TextStyle(color: grey, fontSize: 12),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
