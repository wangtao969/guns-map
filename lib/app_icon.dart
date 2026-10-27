import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 启动图标切换（零第三方包）：
/// 三态由 Android activity-alias 实现：主 Activity 保留老图标，
/// MainActivityLight 挂新图标白色款、MainActivityDark 挂黑色款，
/// 运行时经 gunsmap/system 的 setIcon 一次只启用一个。
///
/// 偏好经 gunsmap/prefs 存本机（key app_icon_v1）：
/// 'auto' 新图标昼夜自动（默认）；'legacy' 老图标。
/// 昼夜跟随 App 自身主题的实际亮度（强制浅/深色直接取，
/// 跟随系统时取平台亮度），不直接读系统主题设置。
const appIconPrefKey = 'app_icon_v1';
const appIconAuto = 'auto';
const appIconLegacy = 'legacy';

const _prefsChannel = MethodChannel('gunsmap/prefs');
const _systemChannel = MethodChannel('gunsmap/system');

final ValueNotifier<String> appIconPrefNotifier =
    ValueNotifier<String>(appIconAuto);

/// 当前主题的实际亮度。
bool effectiveDark(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.dark:
      return true;
    case ThemeMode.light:
      return false;
    case ThemeMode.system:
      return ui.PlatformDispatcher.instance.platformBrightness ==
          Brightness.dark;
  }
}

String _lastApplied = '';

/// 按当前主题与存储偏好应用一次正确图标（冷启动与主题切换时调用）。
/// 已是目标图标时不再调原生，避免重复刷新启动器。
Future<void> syncAppIcon(ThemeMode mode) async {
  final target = appIconPrefNotifier.value == appIconLegacy
      ? 'legacy'
      : (effectiveDark(mode) ? 'dark' : 'light');
  if (target == _lastApplied) return;
  try {
    await _systemChannel.invokeMethod<bool>('setIcon', {'icon': target});
    _lastApplied = target;
  } catch (_) {
    // 原生通道不可用时静默失败，图标保持现状。
  }
}

/// 设置页切换偏好：写 prefs，立即按当前亮度切图标。
Future<void> setAppIconPreference(String pref, bool dark) async {
  appIconPrefNotifier.value = pref;
  try {
    await _prefsChannel.invokeMethod(
        'setString', {'key': appIconPrefKey, 'value': pref});
  } catch (_) {
    // 偏好写失败也不阻塞图标切换。
  }
  _lastApplied = '';
  final target = pref == appIconLegacy ? 'legacy' : (dark ? 'dark' : 'light');
  try {
    await _systemChannel.invokeMethod<bool>('setIcon', {'icon': target});
    _lastApplied = target;
  } catch (_) {
    // 原生通道不可用时静默失败，图标保持现状。
  }
}

/// 冷启动读回偏好（默认 auto）。
Future<void> loadAppIconPreference() async {
  try {
    final raw = await _prefsChannel.invokeMethod<String>('getString', {
      'key': appIconPrefKey,
    });
    if (raw == appIconLegacy || raw == appIconAuto) {
      appIconPrefNotifier.value = raw!;
    }
  } catch (_) {
    // 读不到时保持默认 auto。
  }
}
