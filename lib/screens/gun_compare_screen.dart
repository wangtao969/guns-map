import 'package:flutter/material.dart';
import '../models.dart';
import '../widgets/app_top_bar.dart';
import 'gun_picker_dialog.dart';

/// 两枪参数对比：只对照图鉴已收录的纸面参数，不做弹道推算。
/// 初速与弹道系数未收录，所以不画弹道曲线——画了就是现编。
class GunCompareScreen extends StatefulWidget {
  const GunCompareScreen({super.key});

  @override
  State<GunCompareScreen> createState() => _GunCompareScreenState();
}

class _GunCompareScreenState extends State<GunCompareScreen> {
  Gun? _a;
  Gun? _b;

  Future<void> _pick(bool first) async {
    final gun = await showGunPickerDialog(context);
    if (gun == null) return;
    setState(() {
      if (first) {
        _a = gun;
      } else {
        _b = gun;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SubPageAppBar(title: '两枪参数对比'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          const Text('只对照纸面参数；初速与弹道系数未收录，不画弹道曲线。',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _pick(true),
                  child: Text(_a == null ? '选第一把枪' : _a!.name,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('VS',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _pick(false),
                  child: Text(_b == null ? '选第二把枪' : _b!.name,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_a != null && _b != null) ...[
            _Row('厂商', _a!.vendor, _b!.vendor),
            _Row('品类', _a!.category, _b!.category),
            _Row('口径', _a!.caliber, _b!.caliber),
            _Row('动作方式', _a!.action, _b!.action),
            _Row('枪管长', _a!.barrel, _b!.barrel),
            _Row('全长', _a!.length, _b!.length),
            _Row('重量', _a!.weight, _b!.weight),
            _Row('弹容量', _a!.capacity, _b!.capacity),
            _Row('产地', _a!.origin, _b!.origin),
            _Row('年代', _a!.year, _b!.year),
            _Row('参考价', _a!.price ?? '未确认', _b!.price ?? '未确认'),
            const SizedBox(height: 12),
            if (_a!.description.isNotEmpty) ...[
              Text(_a!.name,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(_a!.description),
              const SizedBox(height: 12),
            ],
            if (_b!.description.isNotEmpty) ...[
              Text(_b!.name,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(_b!.description),
            ],
          ] else
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 32),
                child: Text('两把枪都选好后，这里出现对照表'),
              ),
            ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String a;
  final String b;
  const _Row(this.label, this.a, this.b);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(label,
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ),
          Expanded(child: Text(a, style: const TextStyle(fontSize: 14))),
          const SizedBox(width: 8),
          Expanded(child: Text(b, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
