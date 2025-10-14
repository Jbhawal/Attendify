import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/schedule_entry.dart';
import '../../models/subject.dart';
import '../../providers.dart';
import '../../constants/app_colors.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  int selectedDay = (DateTime.now().weekday + 6) % DateTime.daysPerWeek;

  static const List<String> _days = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  @override
  Widget build(BuildContext context) {
  final subjects = ref.watch(subjectsProvider);
  // Ensure we rebuild when schedules change. Watch the provider (value unused)
  ref.watch(scheduleProvider);
  // Use the notifier helper to get sorted entries for the selected day
  final entriesForDay = ref.read(scheduleProvider.notifier).entriesForDay(selectedDay);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Schedule')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: subjects.isEmpty ? () => _showNeedSubjectsDialog(context) : () => _showScheduleSheet(context, null),
        label: const Text('Add Class'),
        icon: const Icon(Icons.add_rounded),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Row(
                children: List.generate(_days.length, (index) {
                  final isSelected = index == selectedDay;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => selectedDay = index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                        decoration: BoxDecoration(
                          color: isSelected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08) : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            _days[index],
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: entriesForDay.isEmpty
                  ? _emptyState(context)
                  : ListView.separated(
                      itemCount: entriesForDay.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final entry = entriesForDay[index];
                        Subject? subject;
                        for (final item in subjects) {
                          if (item.id == entry.subjectId) {
                            subject = item;
                            break;
                          }
                        }
                        if (subject == null) return const SizedBox.shrink();

                        final hex = subject.color.replaceAll('#', '');
                        final cardColor = Color(int.parse('0xff$hex'));

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 8)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Ribbon with subject code
                              Container(
                                height: 40,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [cardColor, cardColor.withValues(alpha: 0.92)]),
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Row(
                                  children: [
                                    // subject code — no background bubble
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      child: Text(subject.code.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                                    ),
                                    const Spacer(),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(subject.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                          const SizedBox(height: 6),
                                          Text('${entry.startTime} · ${entry.endTime} · ${entry.venue}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                        ],
                                      ),
                                    ),
                                    IconButton(onPressed: () => _showScheduleSheet(context, entry), icon: const Icon(Icons.edit_rounded)),
                                    IconButton(onPressed: () async => await ref.read(scheduleProvider.notifier).deleteEntry(entry.id), icon: const Icon(Icons.delete_outline_rounded)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.calendar_today_outlined, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text('No classes yet', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Build your weekly timetable to see it here.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Future<void> _showNeedSubjectsDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add subjects first'),
        content: const Text('Create subjects before assigning them to the timetable.'),
        actions: [FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Got it'))],
      ),
    );
  }

  Future<void> _showScheduleSheet(BuildContext context, ScheduleEntry? entry) async {
    final subjects = ref.read(subjectsProvider);
    String? selectedSubjectId = entry?.subjectId ?? (subjects.isNotEmpty ? subjects.first.id : null);
    int day = entry?.dayOfWeek ?? selectedDay;
    TimeOfDay startTime = _parseTimeOfDay(entry?.startTime) ?? const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = _parseTimeOfDay(entry?.endTime) ?? const TimeOfDay(hour: 10, minute: 0);
    final startController = TextEditingController(text: _formatTimeOfDay(startTime));
    final endController = TextEditingController(text: _formatTimeOfDay(endTime));
    final venueController = TextEditingController(text: entry?.venue ?? '');
  final classesController = TextEditingController(text: entry == null ? '' : '');

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        final bottomInset = MediaQuery.of(context).viewInsets.bottom;
        return StatefulBuilder(builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(20, 24, 20, bottomInset + 24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(entry == null ? 'Add Class' : 'Edit Class', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    initialValue: selectedSubjectId,
                    decoration: _inputDecoration('Subject'),
                    items: subjects.map((subject) => DropdownMenuItem(value: subject.id, child: Text(subject.name))).toList(),
                    onChanged: (value) => setState(() => selectedSubjectId = value),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: day,
                    decoration: _inputDecoration('Day'),
                    items: List.generate(_days.length, (index) => index).map((value) => DropdownMenuItem(value: value, child: Text(_days[value]))).toList(),
                    onChanged: (value) => setState(() => day = value ?? day),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: startController,
                    readOnly: true,
                    decoration: _inputDecoration('Start Time'),
                    onTap: () async {
                      final picked = await showTimePicker(context: context, initialTime: startTime, initialEntryMode: TimePickerEntryMode.dial);
                      if (picked != null) {
                        if (!context.mounted) return;
                        setState(() {
                          startTime = picked;
                          startController.text = _formatTimeOfDay(startTime);
                          if (!_isEndAfterStart(startTime, endTime)) {
                            endTime = _addMinutes(startTime, 60);
                            endController.text = _formatTimeOfDay(endTime);
                          }
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: endController,
                    readOnly: true,
                    decoration: _inputDecoration('End Time'),
                    onTap: () async {
                      final picked = await showTimePicker(context: context, initialTime: endTime, initialEntryMode: TimePickerEntryMode.dial);
                      if (picked != null) {
                        if (!context.mounted) return;
                        setState(() {
                          endTime = picked;
                          endController.text = _formatTimeOfDay(endTime);
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: venueController, decoration: _inputDecoration('Venue / Room')),
                  const SizedBox(height: 12),
                  TextField(
                    controller: classesController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration('Number of classes to mark'),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        if (selectedSubjectId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a subject.')));
                          return;
                        }
                        if (!_isEndAfterStart(startTime, endTime)) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('End time must be after start time.')));
                          return;
                        }
                        final formattedStart = _formatTimeOfDay(startTime);
                        final formattedEnd = _formatTimeOfDay(endTime);
                        // No auto-attendance creation. Save planned total classes for the subject.
                        if (entry == null) {
                          final num = int.tryParse(classesController.text) ?? 0;
                          if (num <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a positive number of classes.')));
                            return;
                          }
                          final scheduleId = await ref.read(scheduleProvider.notifier).addEntry(subjectId: selectedSubjectId!, dayOfWeek: day, startTime: formattedStart, endTime: formattedEnd, venue: venueController.text);
                          // store per-schedule class count in settings so attendance marking can use it
                          await ref.read(settingsProvider.notifier).setScheduleClassCount(scheduleId, num);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Class added — saved class count: $num'), duration: const Duration(seconds: 2)));
                          }
                        } else {
                          await ref.read(scheduleProvider.notifier).updateEntry(entry.copyWith(subjectId: selectedSubjectId!, dayOfWeek: day, startTime: formattedStart, endTime: formattedEnd, venue: venueController.text));
                          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Schedule updated'), duration: Duration(seconds: 2)));
                        }
                        if (context.mounted) Navigator.of(context).pop();
                      },
                      child: Text(entry == null ? 'Add Class' : 'Save Changes'),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final date = DateTime(0, 1, 1, time.hour, time.minute);
    return DateFormat('hh:mm a').format(date);
  }

  TimeOfDay? _parseTimeOfDay(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final trimmed = value.trim().toUpperCase();
    final patterns = <String>['hh:mm a', 'h:mm a', 'HH:mm', 'H:mm'];
    for (final pattern in patterns) {
      try {
        final date = DateFormat(pattern).parseStrict(trimmed);
        return TimeOfDay(hour: date.hour, minute: date.minute);
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  bool _isEndAfterStart(TimeOfDay start, TimeOfDay end) => _timeOfDayToMinutes(end) > _timeOfDayToMinutes(start);

  int _timeOfDayToMinutes(TimeOfDay time) => time.hour * 60 + time.minute;

  TimeOfDay _addMinutes(TimeOfDay time, int minutes) {
    final dateTime = DateTime(0, 1, 1, time.hour, time.minute).add(Duration(minutes: minutes));
    return TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
  }
}
