import 'package:flutter/material.dart';
import '../services/track_service.dart';
import 'home_page.dart';
import 'encyclopedia_page.dart';
import 'guides_page.dart';
import 'tools_page.dart';
import 'profile_page.dart';

/// 主框架：首页 ｜ 图鉴 ｜ 攻略 ｜ 工具 ｜ 我的
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _index = 0;
  static const _triggers = [
    'page_enter:home',
    'page_enter:encyclopedia',
    'page_enter:guide',
    'page_enter:tools',
    'page_enter:profile',
  ];

  final _pages = const [
    HomePage(),
    EncyclopediaPage(),
    GuidesPage(),
    ToolsPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    TrackService().fire(_triggers[0]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          setState(() => _index = i);
          TrackService().fire(_triggers[i]);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: '首页'),
          NavigationDestination(icon: Icon(Icons.shield_outlined), selectedIcon: Icon(Icons.shield), label: '图鉴'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: '攻略'),
          NavigationDestination(icon: Icon(Icons.calculate_outlined), selectedIcon: Icon(Icons.calculate), label: '工具'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: '我的'),
        ],
      ),
    );
  }
}
