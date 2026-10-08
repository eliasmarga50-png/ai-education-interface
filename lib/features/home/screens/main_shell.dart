import 'package:flutter/material.dart';
import '../../../core/navigation/main_tabs.dart';
import '../../courses/screens/courses_screen.dart';
import '../../ai_tutor/screens/ai_tutor_screen.dart';
import '../../profile/screens/profile_screen.dart';
import 'home_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
  HomeScreen(),
  CoursesScreen(),
  AITutorScreen(),
  ProfileScreen(),
];

  @override
  void initState() {
    super.initState();

    // A fresh shell (for example after logging in again) starts on Home.
    MainTabs.index.value = MainTabs.home;
    MainTabs.index.addListener(_onTabRequested);
  }

  @override
  void dispose() {
    MainTabs.index.removeListener(_onTabRequested);
    super.dispose();
  }

  void _onTabRequested() {
    if (!mounted || _currentIndex == MainTabs.index.value) {
      return;
    }

    setState(() {
      _currentIndex = MainTabs.index.value;
    });
  }

  void _onNavigationItemTapped(int index) {
    MainTabs.go(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onNavigationItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Courses',
          ),
          NavigationDestination(
            icon: Icon(Icons.smart_toy_outlined),
            selectedIcon: Icon(Icons.smart_toy),
            label: 'AI Tutor',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}