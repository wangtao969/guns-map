import 'package:flutter/material.dart';
import '../community_store.dart';
import '../widgets/app_top_bar.dart';

/// 操作日志：每次管理操作留痕（操作人、动作、对象、时间），最新在前。
class AdminLogScreen extends StatelessWidget {
  const AdminLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final grey = dark ? const Color(0xFF8A8578) : const Color(0xFF9A917F);
    return Scaffold(
      appBar: const SubPageAppBar(title: '操作日志'),
      body: AnimatedBuilder(
        animation: communityStore,
        builder: (_, __) {
          final log = communityStore.adminLog;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('管理操作留痕：删帖、置顶、加精、禁言、封禁、任命、板块开关、公告、敏感词都在这里。',
                  style: TextStyle(color: grey, fontSize: 12)),
              const SizedBox(height: 12),
              if (log.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Center(
                    child: Text('暂无操作记录', style: TextStyle(color: grey)),
                  ),
                ),
              for (final e in log)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text('${e.action}：${e.target}',
                        style: const TextStyle(fontSize: 14)),
                    subtitle: Text('${e.actor} · ${e.time.length >= 16 ? e.time.substring(0, 16).replaceAll('T', ' ') : e.time}',
                        style: TextStyle(color: grey, fontSize: 12)),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
