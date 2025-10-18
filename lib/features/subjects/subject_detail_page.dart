import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import '../../models/attendance_record.dart';
import '../../models/subject.dart';
import '../../constants/app_colors.dart';
import '../../widgets/responsive_page.dart';

class SubjectDetailPage extends StatefulWidget {
  const SubjectDetailPage({super.key, required this.subject, required this.records});

  final Subject subject;
  final List<AttendanceRecord> records;

  @override
  State<SubjectDetailPage> createState() => _SubjectDetailPageState();
}

class _SubjectDetailPageState extends State<SubjectDetailPage> {
  late DateTime selectedDay;
  late DateTime focusedDay;

  @override
  void initState() {
    super.initState();
    final sorted = widget.records.map((r) => DateTime(r.date.year, r.date.month, r.date.day)).toSet().toList()..sort();
    selectedDay = sorted.isNotEmpty ? sorted.first : DateTime.now();
    focusedDay = selectedDay;
  }

  DateTime _normalizeDate(DateTime date) => DateTime(date.year, date.month, date.day);

  Color _statusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Colors.green;
      case AttendanceStatus.absent:
        return Colors.redAccent;
      case AttendanceStatus.noClass:
        return Colors.grey[600]!;
      case AttendanceStatus.extraClass:
        return Colors.deepPurple;
      case AttendanceStatus.massBunk:
        return Colors.orange;
    }
  }

  String _statusLabel(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.noClass:
        return 'No class';
      case AttendanceStatus.extraClass:
        return 'Extra class';
      case AttendanceStatus.massBunk:
        return 'Mass bunk';
    }
  }

  @override
  Widget build(BuildContext context) {
    final events = <DateTime, List<AttendanceRecord>>{};
    for (final record in widget.records) {
      final key = _normalizeDate(record.date);
      events.putIfAbsent(key, () => []).add(record);
    }

    final sortedDays = events.keys.toList()..sort();
    final earliestDay = sortedDays.isNotEmpty ? sortedDays.first : DateTime.now();
    final latestDay = sortedDays.isNotEmpty ? sortedDays.last : DateTime.now();

    return Scaffold(
      appBar: AppBar(title: Text(widget.subject.name)),
      body: ResponsivePage(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.subject.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            if (widget.subject.professor.trim().isNotEmpty)
              Text(widget.subject.professor, style: TextStyle(color: Colors.grey[700])),
            const SizedBox(height: 12),
            Expanded(
              child: Column(
                children: [
                  // custom header: month title + Today icon (replaces the built-in format button like "2 weeks")
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'Previous month',
                          icon: const Icon(Icons.chevron_left),
                          onPressed: () {
                            setState(() {
                              focusedDay = DateTime(focusedDay.year, focusedDay.month - 1, focusedDay.day);
                            });
                          },
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              DateFormat('MMMM yyyy').format(focusedDay),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Next month',
                          icon: const Icon(Icons.chevron_right),
                          onPressed: () {
                            setState(() {
                              focusedDay = DateTime(focusedDay.year, focusedDay.month + 1, focusedDay.day);
                            });
                          },
                        ),
                        IconButton(
                          tooltip: 'Today',
                          icon: const Icon(Icons.today_outlined),
                          onPressed: () {
                            final now = DateTime.now();
                            setState(() {
                              focusedDay = _normalizeDate(now);
                              selectedDay = _normalizeDate(now);
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  TableCalendar<AttendanceRecord>(
                    firstDay: earliestDay.subtract(const Duration(days: 120)),
                    lastDay: latestDay.add(const Duration(days: 120)),
                    focusedDay: focusedDay,
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    selectedDayPredicate: (day) => isSameDay(selectedDay, day),
                    onDaySelected: (selected, focused) {
                      setState(() {
                        selectedDay = _normalizeDate(selected);
                        focusedDay = focused;
                      });
                    },
                    onPageChanged: (focused) => setState(() => focusedDay = focused),
                    eventLoader: (day) {
                      final key = _normalizeDate(day);
                      return events[key] ?? const <AttendanceRecord>[];
                    },
                    headerVisible: false,
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: AppColors.gradientEnd.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: const BoxDecoration(
                        color: AppColors.gradientStart,
                        shape: BoxShape.circle,
                      ),
                      markersAlignment: Alignment.bottomCenter,
                      markerDecoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black54,
                      ),
                      markerSize: 6,
                      outsideDaysVisible: false,
                    ),
                    calendarBuilders: CalendarBuilders(
                      markerBuilder: (context, day, eventsForDay) {
                        if (eventsForDay.isEmpty) return const SizedBox.shrink();
                        final markers = eventsForDay.cast<AttendanceRecord>();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Wrap(
                            spacing: 4,
                            children: markers
                                .map((record) => Container(
                                      height: 6,
                                      width: 6,
                                      decoration: BoxDecoration(color: _statusColor(record.status), shape: BoxShape.circle),
                                    ))
                                .toList(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Builder(builder: (context) {
                      final dayRecords = events[_normalizeDate(selectedDay)] ?? const <AttendanceRecord>[];
                      if (dayRecords.isEmpty) return Center(child: Text('No classes recorded on this day.', style: TextStyle(color: Colors.grey[600])));
                      return ListView.separated(
                        itemCount: dayRecords.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final record = dayRecords[index];
                          final statusColor = _statusColor(record.status);
                          final timeLabel = DateFormat('h:mm a').format(record.date);
                          return ListTile(
                            title: Text(_statusLabel(record.status), style: TextStyle(fontWeight: FontWeight.w600, color: statusColor)),
                            subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(timeLabel), if (record.notes != null && record.notes!.isNotEmpty) Text(record.notes!, style: TextStyle(color: Colors.grey[600]))]),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                              child: Text(_statusLabel(record.status), style: TextStyle(color: statusColor, fontWeight: FontWeight.w600)),
                            ),
                          );
                        },
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
