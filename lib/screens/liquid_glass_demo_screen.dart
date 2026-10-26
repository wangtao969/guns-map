import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/liquid_glass.dart';
import '../widgets/liquid_glass_nav.dart';

/// 液态玻璃试验页：先看效果再定是否全 App 推。
/// 背景故意做得花（渐变 + 色块 + 文字），这样玻璃里的
/// 放大与高光才看得出来；背景越素，液态感越不明显。
/// 页底悬浮条是 v2 真折射版（片元着色器采样实时背景做边缘折射 +
/// 色散 + 高光）；页内几块卡片是 v1 矩阵放大版，两版放一起对比。
class LiquidGlassDemoScreen extends StatefulWidget {
  const LiquidGlassDemoScreen({super.key});

  @override
  State<LiquidGlassDemoScreen> createState() => _LiquidGlassDemoScreenState();
}

class _LiquidGlassDemoScreenState extends State<LiquidGlassDemoScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const SubPageAppBar(title: '液态玻璃预览'),
      body: Stack(
        children: [
          // 花背景：渐变 + 色块 + 细文字，供玻璃放大与折射。
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1D3A6E),
                    Color(0xFF6E3AA1),
                    Color(0xFFC96A2B),
                    Color(0xFF2B7A6E),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 120,
            left: -30,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.yellow.withValues(alpha: 0.5),
              ),
            ),
          ),
          Positioned(
            top: 300,
            right: -20,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.pink.withValues(alpha: 0.45),
              ),
            ),
          ),
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 16 + kToolbarHeight, 16, 110),
            children: [
              const Text(
                '试验版：页底悬浮条是 v2 真折射版，上下滑列表时看条子边缘——背景会在边缘被弯折、红蓝微微错开，像酷安底栏那样；点图标可切换选中态。页内几块卡片是 v1 矩阵放大版，放一起对比。',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
              const SizedBox(height: 16),
              // 大卡：跟随手指的高光 + 按压回弹。
              LiquidGlass(
                followFinger: true,
                onTap: () {},
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('液态玻璃大卡',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    SizedBox(height: 6),
                    Text(
                      '注意看卡片里的背景：比卡片外面放大了一圈，边缘有一道亮边。手指划过时，镜面光斑跟着手指走；点按时整块卡会缩一下再弹回来。',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // 药丸导航：iOS 风格的液态底栏样子。
              LiquidGlass(
                borderRadius: 34,
                magnification: 1.15,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const [
                    Icon(Icons.grid_view_rounded, color: Colors.white),
                    Icon(Icons.forum_outlined, color: Colors.white),
                    Icon(Icons.handyman_outlined, color: Colors.white),
                    Icon(Icons.person_outlined, color: Colors.white),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: LiquidGlass(
                      borderRadius: 20,
                      onTap: () {},
                      child: const Center(
                        child: Text('液态按钮',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LiquidGlass(
                      borderRadius: 20,
                      magnification: 1.2,
                      onTap: () {},
                      child: const Center(
                        child: Text('放大更强',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text('对比：左边是现在用的毛玻璃，右边是液态玻璃',
                  style: TextStyle(color: Colors.white, fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              color: Colors.white.withValues(alpha: 0.25),
                              child: const Text(
                                '毛玻璃：只有模糊 + 半透明，看过去是雾面。',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text('毛玻璃',
                            style: TextStyle(
                                color: Colors.white, fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      children: [
                        LiquidGlass(
                          borderRadius: 20,
                          child: const Text(
                            '液态玻璃：背景被放大，边缘带高光，像一块真的玻璃。',
                            style: TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text('液态玻璃',
                            style: TextStyle(
                                color: Colors.white, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                '说明：v1 卡片是矩阵放大 + 轻模糊 + 镜面高光逼近的，边缘没有真折射，所以看起来还是像毛玻璃。v2 底栏改走片元着色器：直接采样底栏后方的实时画面，按圆角轮廓的法线做边缘折射 + 红蓝错位 + 边缘高光，做法和酷安底栏同路（原生是 AGSL，Flutter 这边是 Impeller 着色器）。如果 v2 底栏的感觉对了，下一步再把它推到 App 的悬浮底栏与卡片上；如果还不够像，就不推。',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          // v2 真折射悬浮底栏：滑列表时它后方的背景实时参与折射。
          Positioned(
            left: 24,
            right: 24,
            bottom: 18 + MediaQuery.of(context).padding.bottom,
            child: LiquidGlassNavBar(
              items: const [
                Icons.grid_view_rounded,
                Icons.forum_outlined,
                Icons.handyman_outlined,
                Icons.person_outlined,
              ],
              selectedIndex: _tab,
              onTap: (i) => setState(() => _tab = i),
            ),
          ),
        ],
      ),
    );
  }
}
