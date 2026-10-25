import 'package:flutter/material.dart';
import '../widgets/app_top_bar.dart';
import 'accessories_screen.dart';
import 'community_collection_screen.dart';
import 'gun_compare_screen.dart';
import 'load_tools_screen.dart';
import 'reloading_screen.dart';

/// 工具 Tab：底部 Tab = 工具，板块 = 讨论，分工定死。
/// 配件目录、复装手册、收藏柜是已有页面的入口；
/// 装药工具只做单位换算与用户输入的动能/后坐力计算，不查手册、不推算装药；
/// 两枪参数对比只对照纸面参数，不画弹道曲线（初速与弹道系数未收录）。
class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const GunsMapAppBar(),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
            16, MediaQuery.of(context).padding.top + kToolbarHeight + 16, 16, 16),
        children: [
          const Text('查数据、算单位、对照参数都在这里；讨论请去社区板块。',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 16),
          _ToolTile(
            icon: Icons.handyman_outlined,
            title: '配件目录',
            subtitle: '按品类筛选的知名厂商配件',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AccessoriesScreen()),
            ),
          ),
          _ToolTile(
            icon: Icons.science_outlined,
            title: '复装手册',
            subtitle: '口径图鉴、装药表、供应商与 SOP（只收录手册原文）',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReloadingScreen()),
            ),
          ),
          _ToolTile(
            icon: Icons.inventory_2_outlined,
            title: '我的收藏柜',
            subtitle: '登记拥有 / 上手过 / 想收集的枪，生成卡面分享',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const CommunityCollectionScreen()),
            ),
          ),
          _ToolTile(
            icon: Icons.calculate_outlined,
            title: '装药工具',
            subtitle: '单位换算、枪口动能、后坐力（只算你输入的数，不给装药建议）',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoadToolsScreen()),
            ),
          ),
          _ToolTile(
            icon: Icons.compare_arrows_outlined,
            title: '两枪参数对比',
            subtitle: '对照两把枪的纸面参数，不画弹道曲线',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GunCompareScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ToolTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF8C6A2F)),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
