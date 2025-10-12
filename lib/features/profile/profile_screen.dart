import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _initialized = false;
  String _name = '';
  String? _photoUrl;

  Future<void> _editTextDialog({required String title, String? initial, required Future<void> Function(String?) onSave}) async {
    final controller = TextEditingController(text: initial ?? '');
    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: '')),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(controller.text.trim()), child: const Text('Save')),
        ],
      ),
    );

    if (result != null) {
      await onSave(result.isEmpty ? null : result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);

    settingsAsync.whenData((map) {
      if (!_initialized) {
        _initialized = true;
        _name = map['user_name'] as String? ?? '';
        _photoUrl = map['profile_photo'] as String?;
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Profile')),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
        data: (map) {
          final displayName = _name.isEmpty ? 'Your Name' : _name;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header card with colored background
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          // Use builder-provided context inside the bottom sheet to avoid
                          // using outer BuildContext after await (use_build_context_synchronously).
                          final picked = await showModalBottomSheet<String?>(
                            context: context,
                            isScrollControlled: true,
                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
                            builder: (sheetCtx) {
                              return FutureBuilder<List<String>>(
                                future: () async {
                                  try {
                                    final manifestContent = await rootBundle.loadString('AssetManifest.json');
                                    final Map<String, dynamic> manifestMap = json.decode(manifestContent) as Map<String, dynamic>;
                                    final avatars = manifestMap.keys
                                        .where((k) => k.startsWith('assets/avatars/'))
                                        .where((k) => k.endsWith('.png') || k.endsWith('.jpg') || k.endsWith('.jpeg') || k.endsWith('.svg'))
                                        .toList()
                                      ..sort();
                                    return avatars;
                                  } catch (_) {
                                    return <String>[];
                                  }
                                }(),
                                builder: (gridCtx, snap) {
                                  if (snap.connectionState == ConnectionState.waiting) return const SizedBox(height: 220, child: Center(child: CircularProgressIndicator()));
                                  final avatars = snap.data ?? <String>[];
                                  if (avatars.isEmpty) {
                                    return SizedBox(
                                      height: 240,
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Text('No avatars available', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                            const SizedBox(height: 8),
                                            const Text('Place avatar images in assets/avatars/ and run flutter pub get', textAlign: TextAlign.center),
                                            const SizedBox(height: 12),
                                            FilledButton(onPressed: () => Navigator.of(sheetCtx).pop(), child: const Text('Close')),
                                          ],
                                        ),
                                      ),
                                    );
                                  }

                                  // Single scrollable grid: Random + all avatars
                                  final items = <Widget>[];
                                  items.add(GestureDetector(
                                    onTap: () {
                                      final rnd = avatars[Random().nextInt(avatars.length)];
                                      Navigator.of(sheetCtx).pop(rnd);
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: CircleAvatar(
                                        radius: 36,
                                        backgroundColor: Theme.of(sheetCtx).colorScheme.surface,
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.shuffle, size: 28, color: Theme.of(sheetCtx).colorScheme.secondary),
                                            const SizedBox(height: 6),
                                            const Text('Random', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ));
                                  items.addAll(avatars.map((path) => GestureDetector(
                                        onTap: () => Navigator.of(sheetCtx).pop(path),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: CircleAvatar(
                                            radius: 36,
                                            backgroundColor: Theme.of(sheetCtx).colorScheme.surface,
                                            child: ClipOval(
                                              child: path.endsWith('.svg')
                                                  ? SvgPicture.asset(path, width: 72, height: 72, fit: BoxFit.cover)
                                                  : Image.asset(path, width: 72, height: 72, fit: BoxFit.cover),
                                            ),
                                          ),
                                        ),
                                      )));

                                  final rows = (items.length / 3).ceil();
                                  final height = (rows * 110).clamp(220, 520).toDouble();
                                  return SizedBox(
                                    height: height,
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: GridView.count(
                                        crossAxisCount: 3,
                                        childAspectRatio: 1,
                                        children: items,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          );

                          if (picked != null) {
                            // We already used sheetCtx for Navigator; here we still need to
                            // update state and call provider. Use mounted check before
                            // calling setState to be safe.
                            await ref.read(settingsProvider.notifier).setProfilePhoto(picked);
                            if (!mounted) return;
                            setState(() => _photoUrl = picked);
                          }
                        },
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircleAvatar(
                              radius: 56,
                              backgroundColor: Theme.of(context).colorScheme.surface,
                              child: ClipOval(
                                child: (_photoUrl != null && _photoUrl!.isNotEmpty)
                                    ? (_photoUrl!.startsWith('assets/')
                                        ? (_photoUrl!.endsWith('.svg')
                                            ? SvgPicture.asset(_photoUrl!, width: 112, height: 112, fit: BoxFit.cover)
                                            : Image.asset(_photoUrl!, width: 112, height: 112, fit: BoxFit.cover))
                                        : Image.network(_photoUrl!, width: 112, height: 112, fit: BoxFit.cover))
                                    : Icon(Icons.person, size: 56, color: Theme.of(context).colorScheme.primary),
                              ),
                            ),
                            // pencil overlay at bottom-right
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                height: 36,
                                width: 36,
                                decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, shape: BoxShape.circle),
                                child: Icon(Icons.edit, size: 18, color: Theme.of(context).colorScheme.primary),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Display the stored user name with an edit (pencil) icon
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(displayName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () async {
                              await _editTextDialog(
                                title: 'Edit name',
                                initial: _name,
                                onSave: (value) async {
                                  await ref.read(settingsProvider.notifier).setUserName(value ?? '');
                                  setState(() => _name = value ?? '');
                                },
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.edit, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Reminder toggle
                SwitchListTile(
                  value: ref.watch(settingsProvider).when(data: (m) => (m['reminders_enabled'] as bool?) ?? false, loading: () => false, error: (_, __) => false),
                  onChanged: (v) async {
                    await ref.read(settingsProvider.notifier).setDailyReminderEnabled(v);
                    setState(() {});
                  },
                  title: const Text('Smart daily reminder'),
                  subtitle: const Text('Get a daily notification to mark today\'s attendance'),
                ),

                const SizedBox(height: 8),

                // Clear local data
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.delete_forever),
                  title: const Text('Clear local data'),
                  subtitle: const Text('Remove all subjects, schedules and attendance data stored locally'),
                  onTap: () async {
                    // Capture messenger before any awaits so we don't use the
                    // widget BuildContext after an async gap.
                    final messenger = ScaffoldMessenger.maybeOf(context);
                    final confirmed = await showDialog<bool?>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Clear local data?'),
                        content: const Text('This action cannot be undone.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Clear')),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      await ref.read(subjectsProvider.notifier).clearAll();
                      await ref.read(scheduleProvider.notifier).clearAll();
                      await ref.read(attendanceProvider.notifier).clearAll();
                      messenger?.showSnackBar(const SnackBar(content: Text('Local data cleared')));
                    }
                  },
                ),

                const SizedBox(height: 18),

                // Mass bunk rule setting
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.rule_folder),
                  title: const Text('Mass bunk rule'),
                  subtitle: Text(
                    ref.watch(settingsProvider).when(
                          data: (m) => (m['mass_bunk_rule'] as String?) == 'cancelled'
                              ? 'Count as cancelled (0/0)'
                              : (m['mass_bunk_rule'] as String?) == 'absent'
                                  ? 'Count as absent (0/1)'
                                  : 'Count as attended (1/1)',
                          loading: () => 'Count as attended (1/1)',
                          error: (_, __) => 'Count as attended (1/1)',
                        ),
                  ),
                  onTap: () async {
                    final selected = await showDialog<String?>(
                      context: context,
                      builder: (ctx) => SimpleDialog(
                        title: const Text('Choose mass-bunk rule'),
                        children: [
                          SimpleDialogOption(
                            onPressed: () => Navigator.of(ctx).pop('present'),
                            child: const Text('Count as attended (1/1)'),
                          ),
                          SimpleDialogOption(
                            onPressed: () => Navigator.of(ctx).pop('cancelled'),
                            child: const Text('Count as cancelled (0/0)'),
                          ),
                          SimpleDialogOption(
                            onPressed: () => Navigator.of(ctx).pop('absent'),
                            child: const Text('Count as absent (0/1)'),
                          ),
                        ],
                      ),
                    );
                    if (selected != null) {
                      await ref.read(settingsProvider.notifier).setMassBunkRule(selected);
                      setState(() {});
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // helper(s) intentionally removed
}
