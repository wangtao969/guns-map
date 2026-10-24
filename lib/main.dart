import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/catalog_screen.dart';
import 'screens/accessories_screen.dart';
import 'screens/reloading_screen.dart';
import 'screens/community_screen.dart';

/// 主题选择状态：设置页写入，MaterialApp 监听切换。
/// 仅本次打开期间生效，不做持久化。
final ValueNotifier<ThemeMode> themeModeNotifier =
    ValueNotifier(ThemeMode.system);

void main() => runApp(const FirearmsApp());

/// 白天米白、夜晚黑底白字，跟随系统自动切换。
class FirearmsApp extends StatelessWidget {
  const FirearmsApp({super.key});

  static const _bronze = Color(0xFF6B5B3E);
  static const _bronzeLight = Color(0xFFC9A86A);
  static const _paper = Color(0xFFF7F2E9);
  static const _ink = Color(0xFF2E2A24);
  static const _night = Color(0xFF121110);
  static const _nightCard = Color(0xFF1E1C19);
  static const _nightInk = Color(0xFFEDE8DF);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (_, mode, __) => MaterialApp(
        title: "Gun's Map",
        themeMode: mode,
      theme: ThemeData.light().copyWith(
        colorScheme: const ColorScheme.light(
          primary: _bronze,
          secondary: Color(0xFF8C7A5A),
        ),
        scaffoldBackgroundColor: _paper,
        cardColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: _paper,
          foregroundColor: _ink,
          elevation: 0,
          scrolledUnderElevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
        ),
        textTheme: ThemeData.light().textTheme.apply(
              bodyColor: _ink,
              displayColor: _ink,
            ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
          primary: _bronzeLight,
          secondary: Color(0xFF8C7A5A),
        ),
        scaffoldBackgroundColor: _night,
        cardColor: _nightCard,
        appBarTheme: const AppBarTheme(
          backgroundColor: _night,
          foregroundColor: _nightInk,
          elevation: 0,
          scrolledUnderElevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
        textTheme: ThemeData.dark().textTheme.apply(
              bodyColor: _nightInk,
              displayColor: _nightInk,
            ),
        ),
        home: const HomePage(),
      ),
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
    CommunityScreen(),
  ];

  static const _tabs = [
    (Icons.grid_view_rounded, Icons.grid_view_rounded, '图鉴'),
    (Icons.handyman_outlined, Icons.handyman_rounded, '配件'),
    (Icons.science_outlined, Icons.science_rounded, '复装'),
    (Icons.forum_outlined, Icons.forum_rounded, '社区'),
  ];

  @override
  Widget build(BuildContext context) {
    // 状态栏底色跟随主题背景不透明，内容滑到顶部时不再透出变色。
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: theme.scaffoldBackgroundColor,
        statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: theme.scaffoldBackgroundColor,
        systemNavigationBarIconBrightness:
            dark ? Brightness.light : Brightness.dark,
      ),
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
/// 颜色跟随主题：白天白底半透明，夜晚深底半透明。
class _FloatingNavBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const _FloatingNavBar({required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
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
                color: dark
                    ? const Color(0xFF1E1C19).withValues(alpha: 0.72)
                    : Colors.white.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(34),
                border: Border.all(
                  color: dark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.white.withValues(alpha: 0.6),
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bronze = dark ? const Color(0xFFC9A86A) : const Color(0xFF6B5B3E);
    final grey = dark ? const Color(0xFF8A8578) : const Color(0xFF9A917F);
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
              color: selected
                  ? (dark ? const Color(0xFF121110) : Colors.white)
                  : grey,
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
