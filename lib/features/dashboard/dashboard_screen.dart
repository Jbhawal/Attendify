import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../constants/app_colors.dart';
import '../../models/attendance_record.dart';
import '../../models/dashboard_item.dart';
import '../../providers.dart';
import '../../services/notification_service.dart';
import '../../utils/date_utils.dart';
import '../attendance/attendance_bottom_sheet.dart';
import '../../widgets/subject_progress_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final greeting = ref.watch(greetingProvider);
  final selectedDate = ref.watch(selectedDateProvider);
    final overallAttendance = ref.watch(overallAttendanceProvider);
    final atRiskSubjects = ref.watch(atRiskSubjectsProvider);
    final todaysClasses = ref.watch(todaysClassesProvider);
    final subjects = ref.watch(subjectsProvider);
    final attendance = ref.watch(attendanceProvider);
  final settingsAsync = ref.watch(settingsProvider);
  ref.watch(notificationServiceProvider);

    final todaysAttendanceSummary = _summaryForDate(attendance, selectedDate);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: _HeaderCard(
                greeting: greeting,
                date: DateUtilsX.fullDate.format(selectedDate),
                overallAttendance: overallAttendance,
                todaysSummary: todaysAttendanceSummary,
                atRiskCount: atRiskSubjects.length,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 24),
                settingsAsync.when(
                  data: (settings) {
                    final name = settings['user_name'] as String?;
                    final remindersEnabled =
                        (settings['reminders_enabled'] as bool?) ?? false;
                    final reminderTime = (settings['reminder_time'] as String?) ?? '20:00';
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (name == null || name.isEmpty) ...[
                          _sectionTitle('Complete your profile'),
                          const SizedBox(height: 12),
                          _ProfilePromptCard(onSubmit: (value) async {
                            await ref.read(settingsProvider.notifier).setUserName(value);
                          }),
                          const SizedBox(height: 24),
                        ],
                        _sectionTitle('Smart Reminders'),
                        const SizedBox(height: 12),
                        _ReminderCard(
                          enabled: remindersEnabled,
                          time: reminderTime,
                          onToggle: (value) async {
                            await ref
                                .read(settingsProvider.notifier)
                                .setDailyReminderEnabled(value);
                            if (value) {
                              final parts = reminderTime.split(':');
                              if (parts.length == 2) {
                                final hour = int.tryParse(parts[0]) ?? 20;
                                final minute = int.tryParse(parts[1]) ?? 0;
                                await ref.read(notificationServiceProvider).scheduleDailyReminder(
                                      time: TimeOfDay(hour: hour, minute: minute),
                                    );
                              }
                            } else {
                              await ref.read(notificationServiceProvider).cancelReminders();
                            }
                          },
                          onTimeChange: (value) async {
                            await ref
                                .read(settingsProvider.notifier)
                .setReminderTime(_formatTimeOfDay(value));
                            await ref
                                .read(notificationServiceProvider)
                                .scheduleDailyReminder(time: value);
                          },
                        ),
                        const SizedBox(height: 24),
                      ],
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Text('Could not load settings: $error'),
                  ),
                ),
                _sectionTitle('Today’s Classes'),
                const SizedBox(height: 12),
                if (todaysClasses.isEmpty)
                  _emptyState(
                    context,
                    message:
                        'No classes scheduled today. Enjoy your day or build your timetable!',
                  )
                else
                  ...todaysClasses.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ClassTile(
                        item: item,
                        onTap: () => showAttendanceBottomSheet(
                          context: context,
                          ref: ref,
                          item: item,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                _sectionTitle('Weekly Overview'),
                const SizedBox(height: 12),
                _WeeklyCalendar(
                  selectedDay: selectedDate,
                  onDaySelected: (day) => ref
                      .read(selectedDateProvider.notifier)
                      .state = day,
                  eventsBuilder: (day) => _statusForDay(attendance, day),
                ),
                const SizedBox(height: 24),
                _sectionTitle('Subjects at a Glance'),
                const SizedBox(height: 12),
                if (subjects.isEmpty)
                  _emptyState(
                    context,
                    message: 'Add your first subject to start tracking attendance.',
                  )
                else
                  ...subjects.map((subject) {
                    final summary = ref
                        .read(attendanceProvider.notifier)
                        .summaryForSubject(subject.id);
                    final percentage = ref
                        .read(attendanceProvider.notifier)
                        .percentageForSubject(subject.id);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: SubjectProgressCard(
                        subject: subject,
                        percentage: percentage,
                        held: summary['held'] ?? 0,
                        attended: summary['attended'] ?? 0,
                        missed: summary['missed'] ?? 0,
                      ),
                    );
                  }),
                const SizedBox(height: 120),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Map<AttendanceStatus, int> _summaryForDate(
    List<AttendanceRecord> records,
    DateTime date,
  ) {
    final Map<AttendanceStatus, int> summary = {
      for (final status in AttendanceStatus.values) status: 0,
    };
    for (final record in records) {
      if (_isSameDay(record.date, date)) {
        summary[record.status] = (summary[record.status] ?? 0) + 1;
      }
    }
    return summary;
  }

  List<AttendanceStatus> _statusForDay(
    List<AttendanceRecord> records,
    DateTime day,
  ) {
    return records
        .where((record) => _isSameDay(record.date, day))
        .map((record) => record.status)
        .toList();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

Widget _sectionTitle(String title) {
  return Text(
    title,
    style: const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ),
  );
}

String _formatTimeOfDay(TimeOfDay time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

Widget _emptyState(BuildContext context, {required String message}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nothing here yet',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    ),
  );
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.greeting,
    required this.date,
    required this.overallAttendance,
    required this.todaysSummary,
    required this.atRiskCount,
  });

  final String greeting;
  final String date;
  final double overallAttendance;
  final Map<AttendanceStatus, int> todaysSummary;
  final int atRiskCount;

  Color _colorForPercentage(double value) {
    if (value >= 85) {
      return AppColors.safeGreen;
    }
    if (value >= 75) {
      return AppColors.warningYellow;
    }
    return AppColors.dangerRed;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 36, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.gradientStart, AppColors.gradientEnd],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              spreadRadius: 1,
              offset: const Offset(0, 10),
              color: AppColors.gradientEnd.withValues(alpha: 0.2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              greeting,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              date,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _statBlock(
                    title: 'Overall',
                    value: '${overallAttendance.toStringAsFixed(1)}%',
                    color: _colorForPercentage(overallAttendance),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statBlock(
                    title: 'At Risk',
                    value: '$atRiskCount',
                    color: atRiskCount > 0
                        ? Colors.orangeAccent
                        : Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _summaryBadge(
                    'Present',
                    todaysSummary[AttendanceStatus.present] ?? 0,
                    Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _summaryBadge(
                    'Missed',
                    todaysSummary[AttendanceStatus.absent] ?? 0,
                    Colors.redAccent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _summaryBadge(
                    'Extra',
                    todaysSummary[AttendanceStatus.extraClass] ?? 0,
                    Colors.amber,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statBlock({required String title, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryBadge(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
  color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfilePromptCard extends StatefulWidget {
  const _ProfilePromptCard({required this.onSubmit});

  final Future<void> Function(String value) onSubmit;

  @override
  State<_ProfilePromptCard> createState() => _ProfilePromptCardState();
}

class _ProfilePromptCardState extends State<_ProfilePromptCard> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What should we call you?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Enter your name',
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: () async {
                if (_controller.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a name.')),
                  );
                  return;
                }
                await widget.onSubmit(_controller.text.trim());
              },
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderCard extends StatefulWidget {
  const _ReminderCard({
    required this.enabled,
    required this.time,
    required this.onToggle,
    required this.onTimeChange,
  });

  final bool enabled;
  final String time;
  final Future<void> Function(bool value) onToggle;
  final Future<void> Function(TimeOfDay value) onTimeChange;

  @override
  State<_ReminderCard> createState() => _ReminderCardState();
}

class _ReminderCardState extends State<_ReminderCard> {
  late bool _enabled;
  late TimeOfDay _time;

  @override
  void initState() {
    super.initState();
    _enabled = widget.enabled;
    _time = _parseTime(widget.time);
  }

  @override
  void didUpdateWidget(covariant _ReminderCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) {
      _enabled = widget.enabled;
    }
    if (oldWidget.time != widget.time) {
      _time = _parseTime(widget.time);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications_active_outlined),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Daily attendance reminder',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Switch(
                value: _enabled,
                onChanged: (value) async {
                  setState(() => _enabled = value);
                  await widget.onToggle(value);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'We’ll remind you at ${_time.format(context)} to log today’s classes.',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final result = await showTimePicker(
                  context: context,
                  initialTime: _time,
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: Theme.of(context).colorScheme.copyWith(
                              primary: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (result != null) {
                  setState(() => _time = result);
                  await widget.onTimeChange(result);
                }
              },
              icon: const Icon(Icons.schedule_rounded),
              label: const Text('Change reminder time'),
            ),
          ),
        ],
      ),
    );
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    if (parts.length == 2) {
      final hour = int.tryParse(parts[0]) ?? 20;
      final minute = int.tryParse(parts[1]) ?? 0;
      return TimeOfDay(hour: hour, minute: minute);
    }
    return const TimeOfDay(hour: 20, minute: 0);
  }
}

class _ClassTile extends ConsumerWidget {
  const _ClassTile({required this.item, required this.onTap});

  final TimetableItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: Color(int.parse('0xff${item.subject.color.replaceAll('#', '')}')),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  item.subject.code.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.subject.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${item.schedule.startTime} - ${item.schedule.endTime} · ${item.schedule.venue}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: item.statusColor().withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    item.statusLabel(),
                    style: TextStyle(
                      color: item.statusColor(),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: onTap,
                  child: const Text('Mark'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyCalendar extends StatelessWidget {
  const _WeeklyCalendar({
    required this.selectedDay,
    required this.onDaySelected,
    required this.eventsBuilder,
  });

  final DateTime selectedDay;
  final void Function(DateTime day) onDaySelected;
  final List<AttendanceStatus> Function(DateTime day) eventsBuilder;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TableCalendar<AttendanceStatus>(
        focusedDay: selectedDay,
        firstDay: DateTime.now().subtract(const Duration(days: 365)),
        lastDay: DateTime.now().add(const Duration(days: 365)),
        calendarFormat: CalendarFormat.week,
        startingDayOfWeek: StartingDayOfWeek.monday,
        selectedDayPredicate: (day) => _isSameDay(day, selectedDay),
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, day, events) {
            if (events.isEmpty) {
              return const SizedBox.shrink();
            }
            final color = events.any((status) => status == AttendanceStatus.absent)
                ? AppColors.dangerRed
                : events.any((status) => status == AttendanceStatus.present)
                    ? AppColors.safeGreen
                    : AppColors.warningYellow;
            return Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: 28,
                height: 4,
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          },
        ),
        eventLoader: eventsBuilder,
        onDaySelected: (selected, focused) => onDaySelected(selected),
        headerVisible: false,
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
