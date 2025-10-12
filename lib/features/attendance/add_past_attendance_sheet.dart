import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/attendance_record.dart';
import '../../models/subject.dart';
import '../../providers.dart';

Future<void> showAddPastAttendanceSheet({
  required BuildContext context,
  required WidgetRef ref,
  required Subject subject,
}) async {
  DateTime startDate = ref.read(selectedDateProvider);
  DateTime endDate = startDate;
  bool useRange = false;
  AttendanceStatus? selectedStatus;
  final notesController = TextEditingController();

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) {
      final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
      return StatefulBuilder(builder: (context, setState) {
        Future<void> pickDate(bool isStart) async {
          final now = DateTime.now();
          final initial = isStart ? startDate : endDate;
          final chosen = await showDatePicker(
            context: context,
            initialDate: initial,
            firstDate: DateTime(now.year - 5),
            lastDate: DateTime(now.year + 1),
          );
          if (chosen != null) {
            setState(() {
                if (isStart) {
                  startDate = DateTime(chosen.year, chosen.month, chosen.day);
                } else {
                  endDate = DateTime(chosen.year, chosen.month, chosen.day);
                }
                if (endDate.isBefore(startDate)) {
                  endDate = startDate;
                }
            });
          }
        }

        return Padding(
          padding: EdgeInsets.fromLTRB(20, 24, 20, bottomInset + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Add past attendance', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(subject.name, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700])),
                  ]),
                  IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close_rounded)),
                ],
              ),
              const SizedBox(height: 12),

              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => pickDate(true),
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: Text(DateFormat('dd MMM yyyy').format(startDate)),
                  ),
                ),
                const SizedBox(width: 8),
                Checkbox(value: useRange, onChanged: (v) => setState(() => useRange = v ?? false)),
                const SizedBox(width: 4),
                const Text('Range'),
                const SizedBox(width: 8),
                if (useRange)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => pickDate(false),
                      icon: const Icon(Icons.calendar_view_month_outlined),
                      label: Text(DateFormat('dd MMM yyyy').format(endDate)),
                    ),
                  ),
              ]),

              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AttendanceStatus.values.map((status) {
                  final label = () {
                    switch (status) {
                      case AttendanceStatus.present:
                        return 'Present';
                      case AttendanceStatus.absent:
                        return 'Absent';
                      case AttendanceStatus.noClass:
                        return 'No Class';
                      case AttendanceStatus.extraClass:
                        return 'Extra';
                      case AttendanceStatus.massBunk:
                        return 'Mass bunk';
                    }
                  }();
                  final selected = selectedStatus == status;
                  return ChoiceChip(label: Text(label), selected: selected, onSelected: (v) => setState(() => selectedStatus = v ? status : null));
                }).toList(),
              ),

              const SizedBox(height: 12),
              TextField(controller: notesController, minLines: 2, maxLines: 4, decoration: InputDecoration(labelText: 'Notes (optional)', filled: true, fillColor: Colors.grey[100], border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedStatus == null
                      ? null
                      : () async {
                          final from = startDate;
                          final to = useRange ? endDate : startDate;
                          final List<DateTime> dates = [];
                          for (DateTime d = from; !d.isAfter(to); d = d.add(const Duration(days: 1))) {
                            dates.add(DateTime(d.year, d.month, d.day));
                          }
                          for (final d in dates) {
                            await ref.read(attendanceProvider.notifier).markAttendance(subjectId: subject.id, date: d, status: selectedStatus!, notes: notesController.text.isEmpty ? null : notesController.text);
                          }
                          if (context.mounted) Navigator.of(context).pop();
                        },
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        );
      });
    },
  );
}
