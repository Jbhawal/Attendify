import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../constants/app_colors.dart';
import '../../models/attendance_record.dart';
import '../../models/subject.dart';
import '../../providers.dart';

class SubjectsScreen extends ConsumerWidget {
  const SubjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjects = ref.watch(subjectsProvider);
    final attendance = ref.watch(attendanceProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        title: const Text('Subjects'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSubjectSheet(context, ref),
        label: const Text('Add Subject'),
        icon: const Icon(Icons.add_rounded),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: subjects.isEmpty
            ? _emptyState(context)
            : ListView.separated(
                itemCount: subjects.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final subject = subjects[index];
                  final records = attendance
                      .where((record) => record.subjectId == subject.id)
                      .toList()
                    ..sort((a, b) => b.date.compareTo(a.date));
                  return _SubjectCard(
                    subject: subject,
                    records: records,
                    onEdit: () => _showSubjectSheet(context, ref, subject: subject),
                    onDelete: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete subject?'),
                          content: Text(
                            'Are you sure you want to delete ${subject.name}? '
                            'All related schedules and attendance will remain until removed manually.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed ?? false) {
                        await ref.read(subjectsProvider.notifier).deleteSubject(subject.id);
                      }
                    },
                  );
                },
              ),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.menu_book_outlined, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Add your first subject',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Create subject cards to begin tracking attendance.',
            style:
                Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Future<void> _showSubjectSheet(
    BuildContext context,
    WidgetRef ref, {
    Subject? subject,
  }) async {
    final nameController = TextEditingController(text: subject?.name ?? '');
    final codeController = TextEditingController(text: subject?.code ?? '');
    final professorController = TextEditingController(text: subject?.professor ?? '');
    final creditsController = TextEditingController(
      text: subject != null ? subject.credits.toString() : '3',
    );
    String selectedColor = subject?.color ?? '#0D47A1';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final bottomInset = MediaQuery.of(context).viewInsets.bottom;
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, bottomInset + 24),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      subject == null ? 'Add Subject' : 'Edit Subject',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 20),
                    _AttendifyTextField(
                      controller: nameController,
                      label: 'Subject Name',
                    ),
                    const SizedBox(height: 12),
                    _AttendifyTextField(
                      controller: codeController,
                      label: 'Subject Code',
                      textCapitalization: TextCapitalization.characters,
                    ),
                    const SizedBox(height: 12),
                    _AttendifyTextField(
                      controller: professorController,
                      label: 'Professor',
                    ),
                    const SizedBox(height: 12),
                    _AttendifyTextField(
                      controller: creditsController,
                      label: 'Credits',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Theme color',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: AppColors.subjectPalette.map((color) {
                        final hex =
                            '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
                        final isSelected = selectedColor == hex;
                        return GestureDetector(
                          onTap: () => setState(() => selectedColor = hex),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 42,
                            width: 42,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(color: Colors.black, width: 2)
                                  : null,
                              boxShadow: [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () async {
                          if (nameController.text.isEmpty || codeController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Name and code are required.')),
                            );
                            return;
                          }
                          final credits = int.tryParse(creditsController.text) ?? 3;
                          if (subject == null) {
                            await ref.read(subjectsProvider.notifier).addSubject(
                                  name: nameController.text,
                                  code: codeController.text,
                                  professor: professorController.text,
                                  credits: credits,
                                  color: selectedColor,
                                );
                          } else {
                            await ref.read(subjectsProvider.notifier).updateSubject(
                                  subject.copyWith(
                                    name: nameController.text,
                                    code: codeController.text,
                                    professor: professorController.text,
                                    credits: credits,
                                    color: selectedColor,
                                  ),
                                );
                          }
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                        child: Text(subject == null ? 'Add Subject' : 'Save Changes'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({
    required this.subject,
    required this.records,
    required this.onEdit,
    required this.onDelete,
  });

  final Subject subject;
  final List<AttendanceRecord> records;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = Color(int.parse('0xff${subject.color.replaceAll('#', '')}'));
    final held = records.where((record) => record.status != AttendanceStatus.noClass).length;
    final attended = records
        .where((record) =>
            record.status == AttendanceStatus.present ||
            record.status == AttendanceStatus.extraClass)
        .length;
    final percentage = held == 0 ? 100 : (attended / held) * 100;
    final formatter = DateFormat('EEE, dd MMM');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          leading: Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                subject.code,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          title: Text(
            subject.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            '${subject.professor} · ${subject.credits} credits',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.expand_more_rounded, color: Colors.grey),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_rounded),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  _infoChip('Attended', attended, Colors.green),
                  const SizedBox(width: 12),
                  _infoChip('Held', held, Colors.indigo),
                  const SizedBox(width: 12),
                  _infoChip('Extra',
                      records.where((record) => record.status == AttendanceStatus.extraClass).length,
                      Colors.deepPurple),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (records.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Text('No attendance recorded yet.'),
              )
            else ...[
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: records.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final record = records[index];
                    final status = _statusLabel(record.status);
                    final statusColor = _statusColor(record.status);
                    return ListTile(
                      title: Text(formatter.format(record.date)),
                      subtitle: record.notes == null || record.notes!.isEmpty
                          ? null
                          : Text(record.notes!),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _showHistoryCalendar(context),
                  icon: const Icon(Icons.calendar_month_rounded),
                  label: const Text('See full class history'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoChip(String label, int value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$value',
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
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

  Color _statusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Colors.green;
      case AttendanceStatus.absent:
        return Colors.redAccent;
      case AttendanceStatus.noClass:
        return Colors.blueGrey;
      case AttendanceStatus.extraClass:
        return Colors.deepPurple;
      case AttendanceStatus.massBunk:
        return Colors.orange;
    }
  }

  void _showHistoryCalendar(BuildContext context) {
    if (records.isEmpty) return;

    final events = <DateTime, List<AttendanceRecord>>{};
    for (final record in records) {
      final key = _normalizeDate(record.date);
      events.putIfAbsent(key, () => []).add(record);
    }

    final sortedDays = events.keys.toList()..sort();
    var selectedDay = _normalizeDate(records.first.date);
    var focusedDay = selectedDay;

    final earliestDay = sortedDays.first;
    final latestDay = sortedDays.last;

    final totalAttended = records
        .where((record) =>
            record.status == AttendanceStatus.present ||
            record.status == AttendanceStatus.extraClass)
        .length;
    final totalAbsent =
        records.where((record) => record.status == AttendanceStatus.absent).length;
    final totalMassBunk =
        records.where((record) => record.status == AttendanceStatus.massBunk).length;
    final totalCancelled =
        records.where((record) => record.status == AttendanceStatus.noClass).length;
    final totalExtra =
        records.where((record) => record.status == AttendanceStatus.extraClass).length;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final bottomPadding = MediaQuery.of(context).padding.bottom;
        return FractionallySizedBox(
          heightFactor: 0.9,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 24,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPadding + 16),
            child: StatefulBuilder(
              builder: (context, setState) {
                final selectedKey = _normalizeDate(selectedDay);
                final dayRecords = events[selectedKey] ?? const <AttendanceRecord>[];
                final metadataParts = <String>[
                  if (subject.code.isNotEmpty) subject.code,
                  if (subject.professor.trim().isNotEmpty) subject.professor.trim(),
                ];
                final metadata = metadataParts.join(' • ');

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        height: 4,
                        width: 48,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                subject.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (metadata.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  metadata,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _historyChip('Attended', totalAttended, Colors.green),
                        _historyChip('Missed', totalAbsent, Colors.redAccent),
                        _historyChip('Mass bunk', totalMassBunk, Colors.orange),
                        _historyChip('Cancelled', totalCancelled, Colors.blueGrey),
                        if (totalExtra > 0)
                          _historyChip('Extra', totalExtra, Colors.deepPurple),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              IconButton(
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
                                    DateFormat.yMMMM().format(focusedDay),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.chevron_right),
                                onPressed: () {
                                  setState(() {
                                    focusedDay = DateTime(focusedDay.year, focusedDay.month + 1, focusedDay.day);
                                  });
                                },
                              ),
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    final today = DateTime.now();
                                    focusedDay = today;
                                    selectedDay = today;
                                  });
                                },
                                icon: const Icon(Icons.today_rounded),
                                tooltip: 'Jump to today',
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
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
                            onPageChanged: (focused) {
                              setState(() {
                                focusedDay = focused;
                              });
                            },
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
                                if (eventsForDay.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                final markers = eventsForDay.cast<AttendanceRecord>();
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Wrap(
                                    spacing: 4,
                                    children: markers
                                        .map(
                                          (record) => Container(
                                            height: 6,
                                            width: 6,
                                            decoration: BoxDecoration(
                                              color: _statusColor(record.status),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                );
                              },
                            ),
                          ),
                          Expanded(
                            child: dayRecords.isEmpty
                                ? Center(
                                    child: Text(
                                      'No classes recorded.',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  )
                                : ListView.separated(
                                    itemCount: dayRecords.length,
                                    separatorBuilder: (_, __) => const Divider(height: 1),
                                    itemBuilder: (context, index) {
                                      final record = dayRecords[index];
                                      final statusColor = _statusColor(record.status);
                                      final timeLabel = DateFormat('h:mm a').format(record.date);
                                      return ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        title: Text(
                                          _statusLabel(record.status),
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: statusColor,
                                          ),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(timeLabel),
                                            if (record.notes != null && record.notes!.isNotEmpty)
                                              Text(
                                                record.notes!,
                                                style: TextStyle(color: Colors.grey[600]),
                                              ),
                                          ],
                                        ),
                                        trailing: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: statusColor.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            _statusLabel(record.status),
                                            style: TextStyle(
                                              color: statusColor,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _historyChip(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}

class _AttendifyTextField extends StatelessWidget {
  const _AttendifyTextField({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.textCapitalization,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final TextCapitalization? textCapitalization;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization ?? TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
