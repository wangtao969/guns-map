import 'package:flutter/services.dart';

/// 启动图标固定黑底色（零第三方包）：
/// 主 Activity 挂新图标黑底款，另有两个 activity-alias：
/// MainActivityLight（白天款）、MainActivityDark（夜晚款），
/// 运行时经 gunsmap/system 的 setIcon 一次只启用一个。
/// 图标不再跟随主题变化：冷启动时调一次 syncAppIcon 固定为 dark；
/// 2.1.15 老用户升级后首次启动即从 light 切回 dark，之后不再变化。
/// 两个 alias 保留不动（升级迁移需要它们）。
const _systemChannel = MethodChannel('gunsmap/system');

String _lastApplied = '';

/// 冷启动时调用一次，把图标固定为黑底款。
/// 已是 dark 时不再调原生，避免重复刷新启动器。
Future<void> syncAppIcon() async {
  const target = 'dark';
  if (target == _lastApplied) return;
  try {
    await _systemChannel.invokeMethod<bool>('setIcon', {'icon': target});
    _lastApplied = target;
  } catch (_) {
    // 原生通道不可用时静默失败，图标保持现状。
  }
}
