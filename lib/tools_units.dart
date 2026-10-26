import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 工具页单位制：英制 / 公制，同类射击 App 的常见设置。
/// 存本机（gunsmap/prefs，key tools_units_v1），重启不丢；
/// 靶场换算的距离与散布、装药工具的动能与后坐力输入单位跟随它；
/// 装药工具里的双向单位换算本身不受影响。
/// 默认英制（gr / fps / 码），与射击界常用单位一致。
const String toolsUnitsPrefsKey = 'tools_units_v1';
const _unitsChannel = MethodChannel('gunsmap/prefs');

final ValueNotifier<String> unitSystemNotifier =
    ValueNotifier<String>('imperial');

bool get isMetricUnits => unitSystemNotifier.value == 'metric';

Future<void> loadUnitSystem() async {
  try {
    final v = await _unitsChannel
        .invokeMethod<String>('getString', {'key': toolsUnitsPrefsKey})
        .timeout(const Duration(seconds: 2));
    if (v != null && (v == 'metric' || v == 'imperial')) {
      unitSystemNotifier.value = v;
    }
  } catch (_) {}
}

Future<void> saveUnitSystem(String system) async {
  unitSystemNotifier.value = system;
  try {
    await _unitsChannel.invokeMethod(
        'setString', {'key': toolsUnitsPrefsKey, 'value': system});
  } catch (_) {}
}
