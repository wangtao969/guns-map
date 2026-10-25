import 'package:flutter/services.dart';

/// 系统动作原生通道（gunsmap/system，零第三方包）：
/// openUrl 用系统浏览器打开链接；installApk 用系统安装器安装已下载的 APK。
const _systemChannel = MethodChannel('gunsmap/system');

Future<bool> openSystemUrl(String url) async {
  try {
    return await _systemChannel.invokeMethod<bool>('openUrl', {'url': url}) ??
        false;
  } catch (_) {
    return false;
  }
}

Future<bool> installDownloadedApk(String path) async {
  try {
    return await _systemChannel.invokeMethod<bool>('installApk', {'path': path}) ??
        false;
  } catch (_) {
    return false;
  }
}
