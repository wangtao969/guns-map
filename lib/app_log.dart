import 'dart:convert';
import 'package:flutter/services.dart';

/// 设备日志：记 App 关键事件（语音识别结果、本地保存失败等），
/// 只存本机，供设置页“设备日志”查看、复制、清空，定位问题用。
/// 只传事件摘要，不记账号、密码、帖子内容等隐私信息。
const _logChannel = MethodChannel('gunsmap/prefs');
const _logKey = 'app_log_v1';
const _maxEntries = 200;
List<String>? _cache;

void appLog(String tag, String message) {
  _append(tag, message);
}

Future<void> _append(String tag, String message) async {
  try {
    _cache ??= await _read();
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    final ts =
        '${now.year}-${two(now.month)}-${two(now.day)} ${two(now.hour)}:${two(now.minute)}:${two(now.second)}';
    _cache!.insert(0, '[$ts] [$tag] $message');
    if (_cache!.length > _maxEntries) {
      _cache!.removeRange(_maxEntries, _cache!.length);
    }
    await _logChannel.invokeMethod(
        'setString', {'key': _logKey, 'value': jsonEncode(_cache)});
  } catch (_) {}
}

Future<List<String>> _read() async {
  try {
    final raw = await _logChannel
        .invokeMethod<String>('getString', {'key': _logKey})
        .timeout(const Duration(seconds: 2));
    if (raw == null || raw.isEmpty) return [];
    return (jsonDecode(raw) as List).map((e) => e.toString()).toList();
  } catch (_) {
    return [];
  }
}

Future<List<String>> readAppLog() async {
  _cache ??= await _read();
  return List.of(_cache!);
}

Future<void> clearAppLog() async {
  _cache = [];
  try {
    await _logChannel.invokeMethod(
        'setString', {'key': _logKey, 'value': '[]'});
  } catch (_) {}
}
