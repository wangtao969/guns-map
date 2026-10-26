import 'package:flutter/material.dart';
import '../widgets/app_toast.dart';
import '../system_actions.dart';
import '../widgets/app_top_bar.dart';

/// 项目手册：Ordnance 是什么、能干什么、每块怎么用。
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Widget _section(String title, List<String> lines, Color grey,
      {IconData icon = Icons.info_outlined}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 22),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < lines.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  Text(lines[i], style: const TextStyle(fontSize: 14)),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final grey = dark ? const Color(0xFF8A8578) : const Color(0xFF9A917F);
    return Scaffold(
      appBar: SubPageAppBar(title: '项目手册'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section('项目介绍', [
            'Ordnance 是一款枪械图鉴 App，包含四块：枪械图鉴、配件目录、复装手册与社区。',
            '图鉴收录 738 支真实枪械（8 个品类），每支含厂商、口径、动作、枪管、全长、重量、弹容量、产地与美国零售参考价；品类图片与名枪照片来自 Wikimedia Commons 免费授权图，详情页脚已署名。',
            '配件目录收录 163 条国内外知名厂商配件，按品类筛选；复装手册收录口径图鉴、装药表、供应商与 SOP，只收录 Hornady 等公开手册原文，查不到出处的留空，绝不现编、不推算。',
            '社区目前为本机版：账号、帖子、收藏、等级、勋章、靶场成绩都只保存在本机，换设备或联网版上线后需重新注册；平台活动、排行榜为本机数据预留位。',
            '本项目开源：GitHub 仓库 wangtao969/ordnance，设置页“GitHub 开源代码”可直达。',
          ], grey, icon: Icons.info_outlined),
          _section('操作手册 · 图鉴', [
            '首页图鉴页顶部搜索框可按名称、厂商、口径搜索；品类卡点进去按厂商分组折叠浏览。',
            '枪械详情页有点赞式收藏：点收藏可把枪登记进“我的收藏柜”（想收集 / 上手过 / 拥有三态），收藏柜卡面可分享。',
            '图鉴首屏显示收藏完成度与本期挑战；停售名枪鉴赏在图鉴页内有独立入口。',
          ], grey, icon: Icons.grid_view_rounded),
          _section('操作手册 · 配件与复装', [
            '工具 Tab → 配件目录：按品类筛选，点卡片看适配枪械、售价与购买渠道。',
            '工具 Tab → 复装手册：口径图鉴查尺寸与适配枪械；装药表只看手册原文；复装记录页按 SOP 打勾，全部完成才能记一条。',
            '工具 Tab → 装药工具：只做单位换算、枪口动能与后坐力换算，不给装药建议；两枪参数对比只对照纸面参数，不画弹道曲线。',
            '工具 Tab → 靶场换算：散布换算 MOA/密位与瞄具调节格数；复装成本：按输入价格算每发成本，不提供报价。',
          ], grey, icon: Icons.handyman_outlined),
          _section('操作手册 · 社区', [
            '社区页顶部切换：动态是关注的人与全站用户的图文分享；社区是板块入口、平台活动、签到、全部板块与排行榜。',
            '发动态点右下角大圆钮；草稿会自动保存；发动态成功当天自动签到一次。',
            '每日签到、发帖、评论、获赞、收藏登记与靶场成绩都会涨经验（每日封顶 120），等级 1–60 共六档铭牌；勋章墙在个人主页，28 枚按签到、收藏、发帖、获赞、靶场、品类、挑战、彩蛋分组；本期挑战不过期、不清零。',
            '通知与私信入口在“我的”页，带未读红点；编辑资料与退出登录也在“我的”页。',
          ], grey, icon: Icons.forum_outlined),
          _section('操作手册 · 更新与反馈', [
            '设置页 → 检查更新：有新版时可直接下载安装包并拉起系统安装器安装（需在系统设置中允许本应用安装未知应用）。',
            '设置页 → 意见反馈：可写反馈并跳转邮箱发送；GitHub 开源代码入口可直达仓库。',
          ], grey, icon: Icons.system_update_alt),
          Card(
            child: ListTile(
              leading: const Icon(Icons.code, size: 22),
              title: const Text('GitHub 开源代码'),
              subtitle: const Text('wangtao969/ordnance'),
              onTap: () async {
                final ok = await openSystemUrl(
                    'https://github.com/wangtao969/ordnance');
                if (!ok && context.mounted) {
                  showAppToast(context, '未能打开浏览器');
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
