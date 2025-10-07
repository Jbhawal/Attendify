import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/analytics/analytics_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/schedule/schedule_screen.dart';
import 'features/subjects/subjects_screen.dart';
import 'theme/app_theme.dart';

class AttendifyApp extends ConsumerStatefulWidget {
  const AttendifyApp({super.key});

  @override
  ConsumerState<AttendifyApp> createState() => _AttendifyAppState();
}

class _AttendifyAppState extends ConsumerState<AttendifyApp> {
  int _currentIndex = 0;

  final _pages = const [
    DashboardScreen(),
    SubjectsScreen(),
    ScheduleScreen(),
    AnalyticsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Attendify',
      theme: AttendifyTheme.light(),
      home: Scaffold(
        extendBody: true,
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _pages[_currentIndex],
          ),
        ),
        bottomNavigationBar: NavigationBar(
          height: 68,
          surfaceTintColor: Colors.white,
      indicatorColor:
        Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() => _currentIndex = index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book_rounded),
              label: 'Subjects',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month),
              label: 'Schedule',
            ),
            NavigationDestination(
              icon: Icon(Icons.insights_outlined),
              selectedIcon: Icon(Icons.insights),
              label: 'Analytics',
            ),
          ],
        ),
      ),
    );
  }
}
