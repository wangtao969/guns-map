import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 启动图标昼夜自动（零第三方包）：
/// 主 Activity 挂新图标白天款，另有两个 activity-alias：
/// MainActivityLight（白天款）、MainActivityDark（夜晚款），
/// 运行时经 gunsmap/system 的 setIcon 一次只启用一个。
/// 不再提供手动切换入口，图标只跟随 App 自身主题的实际亮度
/// （强制浅/深色直接取，跟随系统时取平台亮度）。
const _systemChannel = MethodChannel('gunsmap/system');

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

/// 按当前主题应用一次正确图标（冷启动与主题切换时调用）。
/// 已是目标图标时不再调原生，避免重复刷新启动器。
/// 此前存过老图标偏好的用户升级后也会直接回到昼夜自动，
/// 旧 prefs key 留在存储里无害，不再读取。
Future<void> syncAppIcon(ThemeMode mode) async {
  final target = effectiveDark(mode) ? 'dark' : 'light';
  if (target == _lastApplied) return;
  try {
    await _systemChannel.invokeMethod<bool>('setIcon', {'icon': target});
    _lastApplied = target;
  } catch (_) {
    // 原生通道不可用时静默失败，图标保持现状。
  }
}
