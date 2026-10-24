import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/catalog_screen.dart';
import 'screens/accessories_screen.dart';
import 'screens/reloading_screen.dart';

void main() => runApp(const FirearmsApp());

/// 米白色主题：底色 0xFFF7F2E9，卡片纯白，强调色为暖棕铜色。
class FirearmsApp extends StatelessWidget {
  const FirearmsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Gun's Map",
      theme: ThemeData.light().copyWith(
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF6B5B3E),
          secondary: Color(0xFF8C7A5A),
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F2E9),
        cardColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF7F2E9),
          foregroundColor: Color(0xFF2E2A24),
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
        ),
        textTheme: ThemeData.light().textTheme.apply(
              bodyColor: const Color(0xFF2E2A24),
              displayColor: const Color(0xFF2E2A24),
            ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;
  static const _pages = [
    CatalogScreen(),
    AccessoriesScreen(),
    ReloadingScreen(),
  ];

  static const _tabs = [
    (Icons.grid_view_rounded, Icons.grid_view_rounded, '图鉴'),
    (Icons.handyman_outlined, Icons.handyman_rounded, '配件'),
    (Icons.science_outlined, Icons.science_rounded, '复装'),
  ];

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        extendBody: true,
        body: Padding(
          // 给悬浮导航留出空间，避免遮住各页底部内容。
          padding: const EdgeInsets.only(bottom: 96),
          child: _pages[_index],
        ),
        bottomNavigationBar: _FloatingNavBar(
          index: _index,
          onTap: (i) => setState(() => _index = i),
        ),
      ),
    );
  }
}

/// iOS 风格半透明悬浮药丸导航：不贴底、不撑满宽度，毛玻璃 + 柔和阴影。
class _FloatingNavBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const _FloatingNavBar({required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(34),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: 68,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(34),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.6),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  for (var i = 0; i < _HomePageState._tabs.length; i++)
                    Expanded(child: _NavItem(
                      icon: _HomePageState._tabs[i].$1,
                      activeIcon: _HomePageState._tabs[i].$2,
                      label: _HomePageState._tabs[i].$3,
                      selected: index == i,
                      onTap: () => onTap(i),
                    )),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const bronze = Color(0xFF6B5B3E);
    const grey = Color(0xFF9A917F);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            decoration: BoxDecoration(
              color: selected ? bronze : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              selected ? activeIcon : icon,
              size: 24,
              color: selected ? Colors.white : grey,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              color: selected ? bronze : grey,
            ),
          ),
        ],
      ),
    );
  }
}
