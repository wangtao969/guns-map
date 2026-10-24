import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 震动反馈开关：设置页写入，各卡片点击与底部导航切换时读取。
/// 与主题一样，仅本次打开期间生效，不做持久化。
final ValueNotifier<bool> hapticsEnabledNotifier = ValueNotifier(true);

/// 卡片/导航点击的轻震：开关关闭时不震。
void tapHaptic() {
  if (hapticsEnabledNotifier.value) HapticFeedback.selectionClick();
}
