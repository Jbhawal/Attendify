import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
// table_calendar is used in subject_detail_page.dart

import '../../models/attendance_record.dart';
import '../../models/subject.dart';
import '../../providers.dart';
import 'subject_detail_page.dart';

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
      ? _emptyState(context, ref)
            : ListView.separated(
                itemCount: subjects.length,
                padding: EdgeInsets.only(bottom: 120),
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

  Widget _emptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.menu_book_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 20),
          const Text(
            'No subjects added yet',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Text(
            'Start by adding your first subject to track attendance',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 220,
            height: 48,
            child: ElevatedButton(
              onPressed: () => _showSubjectSheet(context, ref),
              style: ButtonStyle(
                shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                padding: MaterialStateProperty.all(const EdgeInsets.symmetric(horizontal: 20)),
                backgroundColor: MaterialStateProperty.resolveWith((states) => null),
                elevation: MaterialStateProperty.all(6),
              ),
              child: Ink(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF4F8EF7), Color(0xFF2B6CE4)]),
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                child: Container(
                  alignment: Alignment.center,
                  child: const Text('Add Your First Subject', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          subject == null ? 'Add New Subject' : 'Edit Subject',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close)),
                      ],
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
                    const Text('Theme color', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        // 8 selectable color squares
                        ...[
                          const Color(0xFF4F8EF7), // blue
                          const Color(0xFF34C759), // green
                          const Color(0xFF8E44FF), // purple
                          const Color(0xFFFF8C42), // orange
                          const Color(0xFFFF3B30), // red
                          const Color(0xFFFF2D55), // pink
                          const Color(0xFF5E35B1), // indigo
                          const Color(0xFF00BFA5), // teal
                        ].map((color) {
                          final hex = '#${color.value.toRadixString(16).substring(2)}';
                          final isSelected = selectedColor == hex;
                          return GestureDetector(
                            onTap: () => setState(() => selectedColor = hex),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: isSelected ? 46 : 40,
                              height: isSelected ? 46 : 40,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(8),
                                border: isSelected ? Border.all(color: Colors.black87, width: 2) : null,
                                boxShadow: [
                                  BoxShadow(color: color.withValues(alpha: 0.18), blurRadius: 8, offset: const Offset(0, 4)),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: const Text('Cancel', style: TextStyle(color: Colors.black87)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (nameController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Name is required.')),
                            );
                            return;
                          }
                          var credits = int.tryParse(creditsController.text) ?? 3;
                          credits = credits.clamp(1, 10);
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
                          if (context.mounted) Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F8EF7),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(subject == null ? 'Add Subject' : 'Update Subject', style: const TextStyle(fontWeight: FontWeight.w600)),
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

class _SubjectCard extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Color(int.parse('0xff${subject.color.replaceAll('#', '')}'));
    // read settings for mass bunk rule at render time
    final settingsAsync = ref.watch(settingsProvider);
    String massRule = 'present';
    settingsAsync.maybeWhen(
      data: (m) {
        massRule = m['mass_bunk_rule'] as String? ?? 'present';
      },
      orElse: () {},
    );

    int held = 0;
    int attended = 0;
    for (final r in records) {
      if (r.status == AttendanceStatus.noClass) continue;
      // Each non-noClass counts towards held unless rule dictates cancellation
      if (r.status == AttendanceStatus.massBunk) {
        // apply rule
        if (massRule == 'cancelled') {
          // do not count this class at all
          continue;
        } else if (massRule == 'present') {
          held += 1;
          attended += 1;
        } else if (massRule == 'absent') {
          held += 1;
          // counted as absent -> do not increment attended
        }
      } else {
        // normal statuses
        held += 1;
        if (r.status == AttendanceStatus.present || r.status == AttendanceStatus.extraClass) {
          attended += 1;
        }
      }
    }
    final percentage = held == 0 ? 100 : (attended / held) * 100;
    final percentageLabel = held == 0 ? 'No record' : '${percentage.toStringAsFixed(1)}%';
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
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (subject.professor.trim().isNotEmpty)
                Text(subject.professor, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
              const SizedBox(height: 4),
              Text('${subject.credits} credits', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
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
                  percentageLabel,
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
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => SubjectDetailPage(subject: subject, records: records),
                    ));
                  },
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



  // helper widgets moved to the detail page
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
