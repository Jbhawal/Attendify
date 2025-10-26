import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/attendance_record.dart';
import '../../models/subject.dart';
import '../../models/schedule_entry.dart';
import '../../providers.dart';
import '../../widgets/responsive_page.dart';

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
  int extraClassCount = 1;
  bool extraClassAttended = true;
  bool extraClassMassBunk = false;
  int unscheduledClassCount = 1; // For marking on unscheduled single days

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
          final today = DateTime(now.year, now.month, now.day);
          final initial = isStart ? startDate : endDate;
          // Ensure initial date is not in the future
          final safeInitial = initial.isAfter(today) ? today : initial;
          final chosen = await showDatePicker(
            context: context,
            initialDate: safeInitial,
            firstDate: DateTime(now.year - 5),
            lastDate: today,
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

        return ResponsivePage(
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

              // Show extra class options when Extra is selected
              if (selectedStatus == AttendanceStatus.extraClass) ...[
                const SizedBox(height: 16),
                const Text('Extra Class Details', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 12),
                
                // Number of classes
                Row(
                  children: [
                    const Text('Number of classes:', style: TextStyle(fontSize: 14)),
                    const Spacer(),
                    IconButton(
                      onPressed: extraClassCount > 1 ? () => setState(() => extraClassCount--) : null,
                      icon: const Icon(Icons.remove_circle_outline),
                      iconSize: 22,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('$extraClassCount', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                    IconButton(
                      onPressed: () => setState(() => extraClassCount++),
                      icon: const Icon(Icons.add_circle_outline),
                      iconSize: 22,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Attendance status for extra class
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() {
                          extraClassAttended = true;
                          extraClassMassBunk = false;
                        }),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: extraClassAttended && !extraClassMassBunk ? Colors.green.withValues(alpha: 0.15) : Colors.grey[100],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: extraClassAttended && !extraClassMassBunk ? Colors.green : Colors.grey[300]!,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle, color: extraClassAttended && !extraClassMassBunk ? Colors.green : Colors.grey[600], size: 18),
                              const SizedBox(width: 6),
                              Text('Attended', style: TextStyle(fontWeight: FontWeight.w600, color: extraClassAttended && !extraClassMassBunk ? Colors.green : Colors.grey[600], fontSize: 14)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() {
                          extraClassAttended = false;
                          extraClassMassBunk = false;
                        }),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !extraClassAttended && !extraClassMassBunk ? Colors.red.withValues(alpha: 0.15) : Colors.grey[100],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: !extraClassAttended && !extraClassMassBunk ? Colors.red : Colors.grey[300]!,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cancel, color: !extraClassAttended && !extraClassMassBunk ? Colors.red : Colors.grey[600], size: 18),
                              const SizedBox(width: 6),
                              Text('Missed', style: TextStyle(fontWeight: FontWeight.w600, color: !extraClassAttended && !extraClassMassBunk ? Colors.red : Colors.grey[600], fontSize: 14)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                
                // Mass bunk option for extra class
                InkWell(
                  onTap: () => setState(() => extraClassMassBunk = !extraClassMassBunk),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: extraClassMassBunk ? Colors.orange.withValues(alpha: 0.15) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: extraClassMassBunk ? Colors.orange : Colors.grey[300]!,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.group_off, color: extraClassMassBunk ? Colors.orange : Colors.grey[600], size: 18),
                        const SizedBox(width: 6),
                        Text('Mass Bunk', style: TextStyle(fontWeight: FontWeight.w600, color: extraClassMassBunk ? Colors.orange : Colors.grey[600], fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ],

              // Show class count selector for single day (not range) when not extra class
              if (!useRange && selectedStatus != null && selectedStatus != AttendanceStatus.extraClass) ...[
                const SizedBox(height: 16),
                const Text('Number of classes:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: unscheduledClassCount > 1 ? () => setState(() => unscheduledClassCount--) : null,
                      icon: const Icon(Icons.remove_circle_outline),
                      iconSize: 28,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('$unscheduledClassCount', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    ),
                    IconButton(
                      onPressed: () => setState(() => unscheduledClassCount++),
                      icon: const Icon(Icons.add_circle_outline),
                      iconSize: 28,
                    ),
                  ],
                ),
              ],

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

                          // Determine scheduled weekdays for this subject. ScheduleEntry.dayOfWeek
                          // may be stored as 0..6 (Mon=0) or 1..7 (Mon=1) depending on code paths,
                          // so normalize to DateTime.weekday values (1..7, Mon=1).
                          final schedules = ref.read(scheduleProvider).where((e) => e.subjectId == subject.id).toList();
                          final Set<int> scheduledWeekdays = <int>{};
                          final Map<int, String> weekdayToScheduleId = {}; // Map weekday to schedule ID
                          
                          for (final ScheduleEntry se in schedules) {
                            final int raw = se.dayOfWeek;
                            int normalizedWeekday;
                            if (raw >= 0 && raw <= 6) {
                              // stored as 0..6 => map Monday(0)->1
                              normalizedWeekday = raw + 1;
                            } else if (raw >= 1 && raw <= 7) {
                              // stored as 1..7 already
                              normalizedWeekday = raw;
                            } else {
                              // best-effort fallback
                              normalizedWeekday = ((raw % 7) + 7) % 7 + 1;
                            }
                            scheduledWeekdays.add(normalizedWeekday);
                            weekdayToScheduleId[normalizedWeekday] = se.id;
                          }

                          // Get settings to retrieve schedule counts
                          final settings = ref.read(settingsProvider).value ?? <String, dynamic>{};

                          // Build list of dates and only mark those matching scheduled weekdays.
                          for (DateTime d = from; !d.isAfter(to); d = d.add(const Duration(days: 1))) {
                            final normalized = DateTime(d.year, d.month, d.day);
                            
                            // For extra classes, mark on any day (not restricted by schedule)
                            // For regular attendance:
                            //   - If single day (not range): allow marking on any day with custom count
                            //   - If range: only mark on scheduled days with schedule counts
                            final isRange = useRange && !from.isAtSameMomentAs(to);
                            final isScheduledDay = schedules.isEmpty || scheduledWeekdays.contains(normalized.weekday);
                            final shouldMark = selectedStatus == AttendanceStatus.extraClass || 
                                               !isRange || 
                                               isScheduledDay;
                            
                            if (shouldMark) {
                              // Determine count and status based on whether it's extra class
                              int markingCount;
                              AttendanceStatus markingStatus;
                              
                              if (selectedStatus == AttendanceStatus.extraClass) {
                                // For extra class, use the custom count and attendance status
                                markingCount = extraClassCount;
                                String extraNote;
                                if (extraClassMassBunk) {
                                  markingStatus = AttendanceStatus.massBunk;
                                  extraNote = 'EXTRA_MB';
                                } else if (extraClassAttended) {
                                  markingStatus = AttendanceStatus.extraClass;
                                  extraNote = 'EXTRA_ATTENDED';
                                } else {
                                  markingStatus = AttendanceStatus.absent;
                                  extraNote = 'EXTRA_MISSED';
                                }
                                
                                // Append to user notes if any
                                final userNotes = notesController.text.isEmpty ? null : notesController.text;
                                final combinedNotes = userNotes != null ? '$extraNote|$userNotes' : extraNote;
                                
                                await ref.read(attendanceProvider.notifier).markAttendance(
                                  subjectId: subject.id,
                                  date: normalized,
                                  status: markingStatus,
                                  count: markingCount,
                                  notes: combinedNotes,
                                );
                                continue; // Skip the regular markAttendance call below
                              } else {
                                // For regular attendance
                                markingStatus = selectedStatus!;
                                
                                if (isRange && isScheduledDay) {
                                  // Range marking: use schedule count for this specific weekday
                                  markingCount = 1; // Default to 1
                                  if (weekdayToScheduleId.containsKey(normalized.weekday)) {
                                    final scheduleId = weekdayToScheduleId[normalized.weekday]!;
                                    var count = settings['schedule_count_$scheduleId'] as int?;
                                    count ??= settings[r'schedule_count_$scheduleId'] as int?;
                                    markingCount = count ?? 1;
                                  }
                                } else {
                                  // Single day marking: use custom count
                                  markingCount = unscheduledClassCount;
                                }
                              }
                              
                              await ref.read(attendanceProvider.notifier).markAttendance(
                                subjectId: subject.id,
                                date: normalized,
                                status: markingStatus,
                                count: markingCount,
                                notes: notesController.text.isEmpty ? null : notesController.text,
                              );
                            }
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
