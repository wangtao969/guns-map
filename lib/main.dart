import 'package:flutter/material.dart';
import 'screens/catalog_screen.dart';
import 'screens/accessories_screen.dart';
import 'screens/reloading_screen.dart';

void main() => runApp(const FirearmsApp());

class FirearmsApp extends StatelessWidget {
  const FirearmsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Gun's Map",
      theme: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(primary: Colors.amber),
        scaffoldBackgroundColor: const Color(0xFF121212),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: '图鉴'),
          BottomNavigationBarItem(icon: Icon(Icons.build), label: '配件'),
          BottomNavigationBarItem(icon: Icon(Icons.science), label: '复装'),
        ],
      ),
    );
  }
}
