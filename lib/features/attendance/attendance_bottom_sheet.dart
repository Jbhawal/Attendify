import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/attendance_record.dart';
import '../../models/dashboard_item.dart';
import '../../providers.dart';

Future<void> showAttendanceBottomSheet({
  required BuildContext context,
  required WidgetRef ref,
  required TimetableItem item,
}) async {
  final notesController = TextEditingController(text: item.record?.notes ?? '');
  AttendanceStatus? selectedStatus = item.record?.status;
  DateTime pickedDate = ref.read(selectedDateProvider);

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
      builder: (context) {
      final bottomInset = MediaQuery.of(context).viewInsets.bottom;
      return StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 24,
              bottom: bottomInset + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.subject.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              DateFormat('EEE, dd MMM yyyy').format(pickedDate),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(color: Colors.grey[700]),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              tooltip: 'Pick date',
                              icon: const Icon(Icons.calendar_today_outlined, size: 18),
                              onPressed: () async {
                                final now = DateTime.now();
                                final initial = pickedDate;
                                final chosen = await showDatePicker(
                                  context: context,
                                  initialDate: initial,
                                  firstDate: DateTime(now.year - 5),
                                  lastDate: DateTime(now.year + 1),
                                );
                                if (chosen != null) {
                                  setModalState(() => pickedDate = DateTime(chosen.year, chosen.month, chosen.day));
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${item.schedule.startTime} · ${item.schedule.venue}',
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: AttendanceStatus.values.map((status) {
                    final isSelected = selectedStatus == status;
                    return ChoiceChip(
                      selected: isSelected,
                      label: Text(_labelForStatus(status)),
                      onSelected: (value) {
                        if (value) {
                          setModalState(() => selectedStatus = status);
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: notesController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Notes (optional)',
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (selectedStatus == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Select a status to proceed.'),
                          ),
                        );
                        return;
                      }
                      await ref
                          .read(attendanceProvider.notifier)
                          .markAttendance(
                            subjectId: item.subject.id,
                            date: pickedDate,
                            status: selectedStatus!,
                            notes: notesController.text.isEmpty
                                ? null
                                : notesController.text,
                          );
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    icon: const Icon(Icons.check_circle_rounded),
                    label: const Text('Save Attendance'),
                  ),
                ),
                if (item.record != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () async {
                        await ref
                            .read(attendanceProvider.notifier)
                            .deleteRecord(item.record!.id);
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                      icon: const Icon(Icons.undo_rounded),
                      label: const Text('Undo mark'),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      );
    },
  );
}

String _labelForStatus(AttendanceStatus status) {
  switch (status) {
    case AttendanceStatus.present:
      return 'Present';
    case AttendanceStatus.absent:
      return 'Absent';
    case AttendanceStatus.noClass:
      return 'No Class';
    case AttendanceStatus.extraClass:
      return 'Extra Class';
    case AttendanceStatus.massBunk:
      return 'Mass Bunk';
  }
}
