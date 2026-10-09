import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/navigation/main_tabs.dart';
import '../../../shared/widgets/responsive_layout.dart';
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
    if (_currentIndex != index) {
      HapticFeedback.selectionClick();
      MainTabs.go(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = !ResponsiveBreakpoints.isMobile(context);

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _currentIndex,
              onDestinationSelected: _onNavigationItemTapped,
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.school_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: Text('Home'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.menu_book_outlined),
                  selectedIcon: Icon(Icons.menu_book),
                  label: Text('Courses'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.smart_toy_outlined),
                  selectedIcon: Icon(Icons.smart_toy),
                  label: Text('AI Tutor'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: Text('Profile'),
                ),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: _screens,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: _onNavigationItemTapped,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
              tooltip: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book),
              label: 'Courses',
              tooltip: 'Courses',
            ),
            NavigationDestination(
              icon: Icon(Icons.smart_toy_outlined),
              selectedIcon: Icon(Icons.smart_toy),
              label: 'AI Tutor',
              tooltip: 'AI Tutor',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
              tooltip: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}