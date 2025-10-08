import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/dashboard/dashboard_screen.dart';
import 'features/schedule/schedule_screen.dart';
import 'features/subjects/subjects_screen.dart';
import 'features/profile/profile_screen.dart';
import 'theme/app_theme.dart';
import 'providers.dart';

class AttendifyApp extends ConsumerStatefulWidget {
  const AttendifyApp({super.key});

  @override
  ConsumerState<AttendifyApp> createState() => _AttendifyAppState();
}

class _OnboardingFlow extends ConsumerStatefulWidget {
  @override
  ConsumerState<_OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<_OnboardingFlow> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runFlow());
  }

  Future<void> _runFlow() async {
    final controller = TextEditingController();
    final name = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Welcome to Attendify'),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'Enter your full name')),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('Skip')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(controller.text.trim()), child: const Text('Save')),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      await ref.read(settingsProvider.notifier).setUserName(name);
    }
    if (!mounted) return;

    final selectedRule = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mass-bunk rule'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text('How does your college handle mass bunks when a class takes place?'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop('present'), child: const Text('Count as attended (1/1)')),
          TextButton(onPressed: () => Navigator.of(ctx).pop('cancelled'), child: const Text('Count as cancelled (0/0)')),
          TextButton(onPressed: () => Navigator.of(ctx).pop('absent'), child: const Text('Count as absent (0/1)')),
        ],
      ),
    );

    if (!mounted) return;
    if (selectedRule != null) {
      await ref.read(settingsProvider.notifier).setMassBunkRule(selectedRule);
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // Show a simple scaffold while onboarding runs
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: const SizedBox.shrink(),
    );
  }
}

class _AttendifyAppState extends ConsumerState<AttendifyApp> {
  int _currentIndex = 0;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  final _pages = [
    const DashboardScreen(key: ValueKey('dashboard')),
    const SubjectsScreen(key: ValueKey('subjects')),
    const ScheduleScreen(key: ValueKey('schedule')),
  // Analytics removed
    const ProfileScreen(key: ValueKey('profile')),
  ];

  @override
  Widget build(BuildContext context) {
    // Prompt for first-time setup (name + mass-bunk rule)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // If onboarding is required, push a separate route that runs the dialog flow
      final settings = ref.read(settingsProvider);
      final hasName = settings.when(
        data: (m) => (m['user_name'] as String?)?.isNotEmpty == true,
        loading: () => false,
        error: (_, __) => false,
      );
      if (!hasName) {
        final nav = _navigatorKey.currentState;
        nav?.push(MaterialPageRoute(builder: (_) => _OnboardingFlow()));
      }
    });
    return MaterialApp(
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Attendify',
      theme: AttendifyTheme.light(),
      home: Scaffold(
        extendBody: true,
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _pages[_currentIndex.clamp(0, _pages.length - 1)],
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
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
