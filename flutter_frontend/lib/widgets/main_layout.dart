import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;

class MainLayout extends StatefulWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  void _onItemTapped(int index, BuildContext context) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/chat');
        break;
      case 2:
        context.go('/records');
        break;
      case 3:
        context.go('/settings');
        break;
    }
  }

  // Helper to determine selected index based on current route
  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/dashboard')) {
      return 0;
    }
    if (location.startsWith('/chat')) {
      return 1;
    }
    if (location.startsWith('/records')) {
      return 2;
    }
    if (location.startsWith('/settings')) {
      return 3;
    }
    return 0; // Default to dashboard
  }


  @override
  Widget build(BuildContext context) {
    _selectedIndex = _calculateSelectedIndex(context);
    
    // 获取屏幕尺寸和方向
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = screenSize.width > screenSize.height;
    final isSmallScreen = screenSize.width < 600; // 小于600px认为是手机屏幕
    
    // 定义导航项
    final navigationDestinations = [
      const NavigationDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
        label: '仪表盘',
      ),
      const NavigationDestination(
        icon: Icon(Icons.chat_bubble_outline),
        selectedIcon: Icon(Icons.chat_bubble),
        label: '健康咨询',
      ),
      const NavigationDestination(
        icon: Icon(Icons.folder_shared_outlined),
        selectedIcon: Icon(Icons.folder_shared),
        label: '健康记录',
      ),
      const NavigationDestination(
        icon: Icon(Icons.settings_outlined),
        selectedIcon: Icon(Icons.settings),
        label: '设置',
      ),
    ];
    
    // 转换为NavigationRailDestination
    final railDestinations = navigationDestinations.map((dest) => NavigationRailDestination(
      icon: dest.icon,
      selectedIcon: dest.selectedIcon,
      label: Text(dest.label),
    )).toList();
    
    return Scaffold(
      // 在小屏幕上显示AppBar
      appBar: isSmallScreen ? AppBar(
        title: const Text('健康顾问'),
        centerTitle: true,
      ) : null,
      
      // 根据屏幕尺寸和方向选择不同的导航布局
      body: isSmallScreen
          ? Column(
              children: [
                // 主内容区域
                Expanded(
                  child: widget.child,
                ),
              ],
            )
          : Row(
              children: [
                // 在大屏幕上使用NavigationRail
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (index) => _onItemTapped(index, context),
                  labelType: NavigationRailLabelType.all,
                  extended: screenSize.width > 800, // 宽屏时展开导航栏
                  leading: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20.0),
                    child: Text(
                      '健康顾问',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  destinations: railDestinations,
                ),
                const VerticalDivider(thickness: 1, width: 1),
                // 主内容区域
                Expanded(
            child: widget.child, // The screen content is passed here
          ),
              ],
            ),
      
      // 在小屏幕上使用底部导航栏
      bottomNavigationBar: isSmallScreen
          ? NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) => _onItemTapped(index, context),
              destinations: navigationDestinations,
              labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
            )
          : null,
    );
  }
}