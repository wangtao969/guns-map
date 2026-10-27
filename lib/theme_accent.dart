import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 主题强调色：设置页主题页写入，各页主要强调处（导航选中药丸、
/// 开关开启色、主要操作按钮、colorScheme primary）读取。
/// 默认铜色不变；颜色值持久化，启动时读回。
const accentPrefsKey = 'theme_accent_v1';
const defaultAccent = Color(0xFF8C6A2F);

class AccentPreset {
  final String nameKey;
  final Color color;
  const AccentPreset(this.nameKey, this.color);
}

const accentPresets = <AccentPreset>[
  AccentPreset('accent_copper', Color(0xFF8C6A2F)),
  AccentPreset('accent_forest', Color(0xFF2F5D50)),
  AccentPreset('accent_navy', Color(0xFF2E4A6B)),
  AccentPreset('accent_oxblood', Color(0xFF7A2E2E)),
  AccentPreset('accent_slatepurple', Color(0xFF5A5470)),
];

final ValueNotifier<Color> accentNotifier = ValueNotifier(defaultAccent);

/// 夜晚模式用的提亮版强调色：亮度不足时提到 0.62，与原有
/// 深色铜色提亮（bronzeLight）的做法一致，保证黑底上可读。
Color lightenedAccent(Color c) {
  final hsl = HSLColor.fromColor(c);
  if (hsl.lightness >= 0.62) return c;
  return hsl.withLightness(0.62).toColor();
}

Future<void> loadAccent() async {
  try {
    const channel = MethodChannel('gunsmap/prefs');
    final raw = await channel
        .invokeMethod<String>('getString', {'key': accentPrefsKey}).timeout(
            const Duration(seconds: 2));
    if (raw == null) return;
    final v = int.tryParse(raw);
    if (v == null) return;
    if (accentPresets.any((p) => p.color.toARGB32() == v)) {
      accentNotifier.value = Color(v);
    }
  } catch (_) {}
}

Future<void> saveAccent(Color c) async {
  accentNotifier.value = c;
  try {
    const channel = MethodChannel('gunsmap/prefs');
    await channel.invokeMethod('setString',
        {'key': accentPrefsKey, 'value': c.toARGB32().toString()}).timeout(
            const Duration(seconds: 2));
  } catch (_) {}
}
