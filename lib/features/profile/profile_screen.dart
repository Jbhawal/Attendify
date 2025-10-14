import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle, Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../providers.dart';
import 'exports_page.dart';

// Feature flag: archive exports UI in profile. Set to false to hide the export
const bool kProfileExportsArchived = true;

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

                // Reminder time selector (visible when reminders are enabled)
                Builder(builder: (ctx) {
                  final enabled = ref.watch(settingsProvider).when(data: (m) => (m['reminders_enabled'] as bool?) ?? false, loading: () => false, error: (_, __) => false);
                  final timeStr = ref.watch(settingsProvider).when(data: (m) => (m['reminder_time'] as String?) ?? '20:00', loading: () => '20:00', error: (_, __) => '20:00');
                  // Parse stored HH:mm to TimeOfDay
                  TimeOfDay parseTime(String ts) {
                    try {
                      final parts = ts.split(':');
                      final h = int.parse(parts[0]);
                      final m = int.parse(parts[1]);
                      return TimeOfDay(hour: h, minute: m);
                    } catch (_) {
                      return const TimeOfDay(hour: 20, minute: 0);
                    }
                  }

                  if (!enabled) return const SizedBox.shrink();

                  final current = parseTime(timeStr);
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.access_time),
                    title: const Text('Reminder time'),
                    subtitle: Text(current.format(ctx)),
                    onTap: () async {
                      final picked = await showTimePicker(context: ctx, initialTime: current);
                      if (picked != null) {
                        final hh = picked.hour.toString().padLeft(2, '0');
                        final mm = picked.minute.toString().padLeft(2, '0');
                        await ref.read(settingsProvider.notifier).setReminderTime('$hh:$mm');
                        setState(() {});
                      }
                    },
                  );
                }),

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

                // Mass bunk rule setting
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.rule_folder),
                  title: const Text('Mass bunk rule'),
                  subtitle: Text(
                    ref.watch(settingsProvider).when(
                          data: (m) => (m['mass_bunk_rule'] as String?) == 'cancelled'
                              ? 'Ignore Class (0/0): Class cancelled, not counted in attendance.'
                              : (m['mass_bunk_rule'] as String?) == 'absent'
                                  ? 'Mark as Absent (0/1): Everyone marked absent.'
                                  : 'Mark as Present. (1/1): Everyone marked present',
                          loading: () => 'Mark as Present. (1/1): Everyone marked present',
                          error: (_, __) => 'Mark as Present. (1/1): Everyone marked present',
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
                            child: const Text('Mark as Present. (1/1): Everyone marked present'),
                          ),
                          SimpleDialogOption(
                            onPressed: () => Navigator.of(ctx).pop('cancelled'),
                            child: const Text('Ignore Class (0/0): Class cancelled, not counted in attendance.'),
                          ),
                          SimpleDialogOption(
                            onPressed: () => Navigator.of(ctx).pop('absent'),
                            child: const Text('Mark as Absent (0/1): Everyone marked absent.'),
                          ),
                        ],
                      ),
                    );
                    if (!mounted) return;
                    if (selected != null) {
                      await ref.read(settingsProvider.notifier).setMassBunkRule(selected);
                      if (!mounted) return;
                      setState(() {});
                    }
                  },
                ),

                const SizedBox(height: 8),

                if (!kProfileExportsArchived)
                  // Export data (choose CSV or Excel)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.file_upload_outlined),
                    title: const Text('Export data'),
                    subtitle: const Text('Choose CSV or Excel export'),
                    onTap: () async {
                      // Capture messenger/context-sensitive objects before any awaits
                      final messenger = ScaffoldMessenger.maybeOf(context);
                      final exportContext = context;

                      final choice = await showDialog<String?>(context: exportContext, builder: (ctx) => SimpleDialog(
                            title: const Text('Export format'),
                            children: [
                              SimpleDialogOption(onPressed: () => Navigator.of(ctx).pop('csv'), child: const Text('CSV')),
                              SimpleDialogOption(onPressed: () => Navigator.of(ctx).pop('excel'), child: const Text('Excel (.xlsx)')),
                              SimpleDialogOption(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('Cancel')),
                            ],
                          ));
                      if (choice == null) return;

                      if (choice == 'csv') {
                        // Build CSV content from providers
                        final subjects = ref.read(subjectsProvider);
                        final attendance = ref.read(attendanceProvider);

                        final sb = StringBuffer();
                        sb.writeln('subjects:id,name,code,professor,credits,color,created_date');
                        for (final s in subjects) {
                          final m = s.toMap();
                          sb.writeln('${m['id']},"${m['name']}","${m['code']}","${m['professor']}",${m['credits']},${m['color']},${m['created_date']}');
                        }
                        sb.writeln();
                        sb.writeln('attendance:id,subjectId,date,status,notes');
                        for (final a in attendance) {
                          sb.writeln('${a.id},${a.subjectId},${a.date.toIso8601String()},${a.status.toString().split('.').last},""');
                        }

                        final csv = sb.toString();

                        // Ask user for filename (suggest a default) and save CSV to the user-visible export directory
                        final suggested = 'attendify_export_${DateTime.now().toIso8601String()}.csv';
                        if (!mounted) return;
                        final dialogContext = context;
                        // ignore: use_build_context_synchronously
                        final filename = await showDialog<String?>(context: dialogContext, builder: (ctx) {
                          final controller = TextEditingController(text: suggested);
                          return AlertDialog(
                            title: const Text('Save CSV as'),
                            content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'Filename')),
                            actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.of(ctx).pop(controller.text.trim()), child: const Text('Save'))],
                          );
                        });

                        if (!mounted) return;

                        if (filename != null && filename.isNotEmpty) {
                          try {
                            final dir = await _getExportDirectory();
                            final file = File('${dir.path}/$filename');
                            await file.create(recursive: true);
                            await file.writeAsString(csv, flush: true);
                            await Clipboard.setData(ClipboardData(text: file.path));
                            messenger?.showSnackBar(const SnackBar(content: Text('CSV exported: path copied to clipboard')));
                            await ref.read(settingsProvider.notifier).addExportFile(file.path);
                            setState(() {});
                          } catch (_) {
                            // Fallback: copy CSV to clipboard and notify via the previously captured messenger
                            await Clipboard.setData(ClipboardData(text: csv));
                            messenger?.showSnackBar(const SnackBar(content: Text('CSV copied to clipboard')));
                          }
                        }
                      } else if (choice == 'excel') {
                        final subjects = ref.read(subjectsProvider);
                        final attendance = ref.read(attendanceProvider);

                        final excel = Excel.createExcel();
                        // Subjects sheet
                        final sSheet = excel['Subjects'];
                        sSheet.appendRow(['id', 'name', 'code', 'professor', 'credits', 'color', 'created_date']);
                        for (final s in subjects) {
                          final m = s.toMap();
                          sSheet.appendRow([m['id'], m['name'], m['code'], m['professor'], m['credits'], m['color'], m['created_date']]);
                        }

                        // Attendance sheet
                        final aSheet = excel['Attendance'];
                        aSheet.appendRow(['id', 'subjectId', 'date', 'status']);
                        for (final a in attendance) {
                          aSheet.appendRow([a.id, a.subjectId, a.date.toIso8601String(), a.status.toString().split('.').last]);
                        }

                        final bytes = excel.encode();
                        if (bytes == null) return;

                        // Ask user for filename and save the excel file
                        final suggestedX = 'attendify_export_${DateTime.now().toIso8601String()}.xlsx';
                        if (!mounted) return;
                        final dialogContextX = context;
                        // ignore: use_build_context_synchronously
                        final filenameX = await showDialog<String?>(context: dialogContextX, builder: (ctx) {
                          final controller = TextEditingController(text: suggestedX);
                          return AlertDialog(
                            title: const Text('Save Excel as'),
                            content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'Filename')),
                            actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.of(ctx).pop(controller.text.trim()), child: const Text('Save'))],
                          );
                        });

                        if (!mounted) return;

                        if (filenameX != null && filenameX.isNotEmpty) {
                          final dir = await _getExportDirectory();
                          final file = File('${dir.path}/$filenameX');
                          await file.create(recursive: true);
                          await file.writeAsBytes(bytes, flush: true);
                          await Clipboard.setData(ClipboardData(text: file.path));
                          messenger?.showSnackBar(const SnackBar(content: Text('Excel exported: path copied to clipboard')));
                          await ref.read(settingsProvider.notifier).addExportFile(file.path);
                          setState(() {});
                        }
                      }
                    },
                  ),

                if (!kProfileExportsArchived)
                  // Recent exports preview
                  Builder(builder: (ctx) {
                    final recent = ref.watch(settingsProvider).when(
                          data: (m) => (m['last_exports'] as List?)?.cast<String>() ?? <String>[],
                          loading: () => <String>[],
                          error: (_, __) => <String>[],
                        );
                    if (recent.isEmpty) return const SizedBox.shrink();
                    final top = recent.take(5).toList();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        const Text('Recent exports', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        ...top.map((path) {
                          final name = p.basename(path);
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.insert_drive_file_outlined),
                            title: Text(name),
                            subtitle: Text(path, overflow: TextOverflow.ellipsis),
                            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                              IconButton(onPressed: () async {
                                final messenger = ScaffoldMessenger.maybeOf(context);
                                await Clipboard.setData(ClipboardData(text: path));
                                messenger?.showSnackBar(const SnackBar(content: Text('Path copied to clipboard')));
                              }, icon: const Icon(Icons.copy)),
                              IconButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ExportsPage())), icon: const Icon(Icons.folder_open)),
                            ]),
                          );
                        }),
                      ],
                    );
                  }),

                // FAQ / Walkthrough
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.help_outline),
                  title: const Text('FAQ / How it works'),
                  subtitle: const Text('Short walkthrough and tips'),
                  onTap: () => showDialog<void>(context: context, builder: (ctx) => AlertDialog(
                        title: const Text('How Attendify works'),
                        content: const SingleChildScrollView(child: Text('• Add subjects and schedules\n• Mark attendance daily\n• Use reminders to get notified\n• Mass-bunk rules control bulk marking\n• Export your data as CSV')),
                        actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close'))],
                      )),
                ),

                const SizedBox(height: 8),

                // Report a bug / Send feedback
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.bug_report_outlined),
                  title: const Text('Report a bug / Send feedback'),
                  subtitle: const Text('Tell us what went wrong or suggest improvements'),
                  onTap: () async {
                    final messenger = ScaffoldMessenger.maybeOf(context);
                    final controller = TextEditingController();
                    final submitted = await showDialog<bool?>(context: context, builder: (ctx) => AlertDialog(
                          title: const Text('Send feedback'),
                          content: TextField(controller: controller, maxLines: 6, decoration: const InputDecoration(hintText: 'Describe the issue...')),
                          actions: [
                            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                            FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Send')),
                          ],
                        ));
                    if (submitted == true && controller.text.trim().isNotEmpty) {
                      // For now: copy feedback to clipboard as a placeholder for sending
                      await Clipboard.setData(ClipboardData(text: controller.text.trim()));
                      messenger?.showSnackBar(const SnackBar(content: Text('Feedback copied to clipboard (placeholder)')));
                    }
                  },
                ),

                const SizedBox(height: 8),

                // App version and changelog
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.info_outline),
                  title: const Text('App version & changelog'),
                  subtitle: const Text('View current version and recent changes'),
                  onTap: () => showDialog<void>(context: context, builder: (ctx) => AlertDialog(
                        title: const Text('Version & Changelog'),
                        content: const SingleChildScrollView(child: Text('Version: 1.0.0\n\nChangelog:\n- Initial release with subjects, schedules, reminders, and export')),
                        actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close'))],
                      )),
                ),
                const SizedBox(height: 18),
              ],
            ),
          );
        },
      ),
    );
  }

  // Return a directory suitable for user-visible exports. On Android try the
  // Downloads external directory; otherwise fall back to the app documents dir.
  Future<Directory> _getExportDirectory() async {
    try {
      if (Platform.isAndroid) {
        final dirs = await getExternalStorageDirectories(type: StorageDirectory.downloads);
        if (dirs != null && dirs.isNotEmpty) {
          final d = dirs.first;
          // Ensure it exists
          await d.create(recursive: true);
          return d;
        }
      }
    } catch (_) {
      // ignore and fallback
    }
    final docs = await getApplicationDocumentsDirectory();
    await docs.create(recursive: true);
    return docs;
  }

  // helper(s) intentionally removed
}
