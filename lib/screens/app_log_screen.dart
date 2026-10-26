import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_log.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/app_toast.dart';

/// 设备日志查看页：只显示本机记下的关键事件摘要，
/// 可一键复制全部（发给开发者定位问题）、可清空。
class AppLogScreen extends StatefulWidget {
  const AppLogScreen({super.key});

  @override
  State<AppLogScreen> createState() => _AppLogScreenState();
}

class _AppLogScreenState extends State<AppLogScreen> {
  var _entries = <String>[];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final list = await readAppLog();
    if (mounted) setState(() => _entries = list);
  }

  Future<void> _copyAll() async {
    if (_entries.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _entries.join('\n')));
    if (mounted) showAppToast(context, '设备日志已复制');
  }

  Future<void> _confirmClear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清空设备日志？'),
        content: const Text('清空后旧的事件记录就找不回来了。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('清空')),
        ],
      ),
    );
    if (ok != true) return;
    await clearAppLog();
    await _reload();
    if (mounted) showAppToast(context, '设备日志已清空');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SubPageAppBar(title: '设备日志'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                      '只记语音识别、保存失败等关键事件摘要，不记账号与帖子内容。',
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                ),
                TextButton.icon(
                  onPressed: _entries.isEmpty ? null : _copyAll,
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('复制全部'),
                ),
                TextButton.icon(
                  onPressed: _entries.isEmpty ? null : _confirmClear,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('清空'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _entries.isEmpty
                ? const Center(
                    child: Text('暂无日志。',
                        style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _entries.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SelectableText(_entries[i],
                          style: const TextStyle(fontSize: 12)),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
