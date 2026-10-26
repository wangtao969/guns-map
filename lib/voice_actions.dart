import 'package:flutter/services.dart';

/// 语音识别（gunsmap/voice）：调系统自带识别界面，不用 App 申请录音权限。
/// 返回识别到的第一句文本；无识别服务、用户取消或失败时返回 null。
/// 调用方只把结果当草稿展示，关键字段（装药量、COL、底火、弹头）
/// 绝不由语音直接填充，须用户逐项确认。
const _voiceChannel = MethodChannel('gunsmap/voice');

Future<String?> recognizeSpeech() async {
  try {
    return await _voiceChannel.invokeMethod<String>('recognize');
  } catch (_) {
    return null;
  }
}
