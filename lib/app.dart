import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';

import 'features/dashboard/dashboard_screen.dart';
import 'features/schedule/schedule_screen.dart';
import 'features/subjects/subjects_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/analytics/analytics_screen.dart';
import 'theme/app_theme.dart';
import 'providers.dart';

class AttendifyApp extends ConsumerStatefulWidget {
  const AttendifyApp({super.key});

  @override
  ConsumerState<AttendifyApp> createState() => _AttendifyAppState();
}

class _OnboardingPage extends ConsumerStatefulWidget {
  const _OnboardingPage();

  @override
  ConsumerState<_OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<_OnboardingPage> {
  final TextEditingController _controller = TextEditingController();

  Future<void> _saveAndContinue(String? name) async {
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
          TextButton(onPressed: () => Navigator.of(ctx).pop('present'), child: const Text('Mark as Present. (1/1): Everyone marked present')),
          TextButton(onPressed: () => Navigator.of(ctx).pop('cancelled'), child: const Text('Ignore Class (0/0): Class cancelled, not counted in attendance.')),
          TextButton(onPressed: () => Navigator.of(ctx).pop('absent'), child: const Text('Mark as Absent (0/1): Everyone marked absent.')),
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
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo placeholder — reuse app title styling
              const FlutterLogo(size: 96),
              const SizedBox(height: 12),
              Text('Attendify', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 28),
              Text('Welcome! What should we call you?', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              TextField(controller: _controller, decoration: const InputDecoration(hintText: 'Enter your full name'), textCapitalization: TextCapitalization.words),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // generate a random fallback username like User12345
                        final rnd = Random();
                        final suffix = rnd.nextInt(90000) + 10000; // 10000..99999
                        _saveAndContinue('User$suffix');
                      },
                      child: const Text('Skip'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => _saveAndContinue(_controller.text.trim()),
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
    const AnalyticsScreen(key: ValueKey('analytics')),
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
        nav?.push(MaterialPageRoute(builder: (_) => const _OnboardingPage()));
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
              icon: Icon(Icons.insights_outlined),
              selectedIcon: Icon(Icons.insights),
              label: 'Analytics',
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
