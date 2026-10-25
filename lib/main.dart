import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'community_store.dart';
import 'haptics.dart';
import 'i18n.dart';
import 'screens/catalog_screen.dart';
import 'screens/community_screen.dart';
import 'screens/my_screen.dart';
import 'screens/tools_screen.dart';
import 'widgets/page_transitions.dart';

/// 主题选择状态：设置页写入，MaterialApp 监听切换。
/// 仅本次打开期间生效，不做持久化。
final ValueNotifier<ThemeMode> themeModeNotifier =
    ValueNotifier(ThemeMode.system);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 先从本机读回社区数据（带超时兜底，不阻塞启动太久），再进首页。
  await communityStore.init();
  runApp(const FirearmsApp());
}

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
      builder: (_, mode, __) => ValueListenableBuilder<String>(
        valueListenable: localeNotifier,
        builder: (_, ___, ____) => MaterialApp(
        title: "Gun's Map",
        themeMode: mode,
      theme: ThemeData.light().copyWith(
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: <TargetPlatform, PageTransitionsBuilder>{
            TargetPlatform.android:
                SlideFadePageTransitionsBuilder(),
            TargetPlatform.iOS: SlideFadePageTransitionsBuilder(),
            TargetPlatform.macOS: SlideFadePageTransitionsBuilder(),
            TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.fuchsia: FadeUpwardsPageTransitionsBuilder(),
          },
        ),
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
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: <TargetPlatform, PageTransitionsBuilder>{
            TargetPlatform.android:
                SlideFadePageTransitionsBuilder(),
            TargetPlatform.iOS: SlideFadePageTransitionsBuilder(),
            TargetPlatform.macOS: SlideFadePageTransitionsBuilder(),
            TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.fuchsia: FadeUpwardsPageTransitionsBuilder(),
          },
        ),
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
        home: HomePage(),
        ),
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

  static const _tabs = [
    (Icons.grid_view_rounded, Icons.grid_view_rounded, 'tab_catalog'),
    (Icons.forum_outlined, Icons.forum_rounded, 'tab_community'),
    (Icons.handyman_outlined, Icons.handyman_rounded, 'tab_tools'),
    (Icons.person_outlined, Icons.person_rounded, 'tab_mine'),
  ];

  @override
  Widget build(BuildContext context) {
    // 状态栏底色跟随主题背景不透明，内容滑到顶部时不再透出变色。
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    // 页面每次构建时新建实例（不用 const），语言切换时当前页才能重译；
    // 元素复用保证 State 不丢，社区当次数据不会因切语言清空。
    final pages = [
      CatalogScreen(),
      CommunityScreen(),
      ToolsScreen(),
      MyScreen(),
    ];
    // 语言切换时重建导航（含底部 Tab 文案）；各页内部另有自己的语言监听。
    return ValueListenableBuilder<String>(
      valueListenable: localeNotifier,
      builder: (_, __, ___) => AnnotatedRegion<SystemUiOverlayStyle>(
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
          // 底部 Tab 切换只淡入：上下滑动会让页面一震一震像 bug，已去掉。
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, anim) =>
                FadeTransition(opacity: anim, child: child),
            child: KeyedSubtree(
              key: ValueKey(_index),
              child: pages[_index],
            ),
          ),
        ),
        bottomNavigationBar: _FloatingNavBar(
          index: _index,
          onTap: (i) {
            tapHaptic();
            setState(() => _index = i);
          },
        ),
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
            filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
            child: Stack(
              children: [
                Container(
                  height: 68,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: dark
                          ? [
                              const Color(0xFF2E2A26).withValues(alpha: 0.62),
                              const Color(0xFF1E1C19).withValues(alpha: 0.42),
                            ]
                          : [
                              Colors.white.withValues(alpha: 0.58),
                              Colors.white.withValues(alpha: 0.32),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(34),
                    border: Border.all(
                      color: dark
                          ? Colors.white.withValues(alpha: 0.20)
                          : Colors.white.withValues(alpha: 0.65),
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
                          selected: index == i,
                          onTap: () => onTap(i),
                        )),
                    ],
                  ),
                ),
                // 顶部高光线：液态玻璃的反光边缘。
                Positioned(
                  top: 0,
                  left: 28,
                  right: 28,
                  child: Container(
                    height: 1.5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.0),
                          Colors.white.withValues(alpha: 0.55),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 底部导航项：只显示图标，不显示文字；选中态为铜色药丸。
class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final bool selected;
  final VoidCallback onTap;
  const _NavItem({
    required this.icon,
    required this.activeIcon,
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
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? bronze : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            selected ? activeIcon : icon,
            size: 26,
            color: selected
                ? (dark ? const Color(0xFF121110) : Colors.white)
                : grey,
          ),
        ),
      ),
    );
  }
}
