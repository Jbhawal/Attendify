import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/app_colors.dart';
import '../../models/dashboard_item.dart';
import '../../models/attendance_record.dart';
import '../../providers.dart';
import '../subjects/subject_detail_page.dart';
import '../../utils/date_utils.dart';
import '../attendance/attendance_bottom_sheet.dart';
import '../attendance/add_past_attendance_sheet.dart';
import '../../widgets/attendance_ring_card.dart';
import '../../widgets/responsive_page.dart';
 

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final greeting = ref.watch(greetingProvider);
    final selectedDate = ref.watch(selectedDateProvider);
  final overallAttendance = ref.watch(overallAttendanceProvider);
  final overallHeld = ref.watch(overallHeldProvider);
  final atRiskSubjects = ref.watch(atRiskSubjectsProvider);
  final attendanceRepo = ref.read(attendanceProvider.notifier);
    final todaysClasses = ref.watch(todaysClassesProvider);

  final settingsMap = ref.watch(settingsProvider).value ?? <String, dynamic>{};
  final threshold = (settingsMap['attendance_threshold'] as int?) ?? 75;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
          child: ResponsivePage(
            padding: EdgeInsets.zero,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
            _HeaderCard(
              greeting: greeting,
              date: DateUtilsX.fullDate.format(selectedDate),
              overallAttendance: overallAttendance,
              overallHeld: overallHeld,
              atRiskCount: atRiskSubjects.length,
              threshold: threshold,
            ),
            const SizedBox(height: 20),

            // Quick stats tiles
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(child: _statTile('Overall %', overallHeld == 0 ? 'No data' : '${overallAttendance.toStringAsFixed(1)}%', color: AppColors.gradientStart)),
                  const SizedBox(width: 12),
                  Expanded(child: _statTile('At-risk', '${atRiskSubjects.length}', color: Colors.orangeAccent)),
                  const SizedBox(width: 12),
                  Expanded(child: _statTile('Today', '${todaysClasses.length}', color: AppColors.primary)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // At-risk subjects horizontal scroller
            if (atRiskSubjects.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _sectionTitle('Needs Attention'),
              ),
              const SizedBox(height: 12),
              // Show Needs Attention subjects as a responsive grid of ring cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: LayoutBuilder(builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 720 ? 3 : (constraints.maxWidth > 420 ? 2 : 1);
                final spacing = 12.0;
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: atRiskSubjects.map((s) {
                    final pct = attendanceRepo.percentageForSubject(s.id);
                    final summary = attendanceRepo.summaryForSubject(s.id);
                    final held = summary['held'] ?? 0;
                    final attended = summary['attended'] ?? 0;
                    final settingsMap = ref.watch(settingsProvider).value ?? <String, dynamic>{};
                    final planned = settingsMap['subject_total_${s.id}'] as int?;
                    debugPrint('AtRisk check: ${s.name} (id=${s.id}) -> pct=${pct == null ? 'null' : pct.toStringAsFixed(2)}, held=$held, attended=$attended, planned=$planned');
                    // compute width for item using crossAxisCount
                    final itemWidth = (constraints.maxWidth - (crossAxisCount - 1) * spacing) / crossAxisCount;
                    final subjectColor = Color(int.parse('0xff${s.color.replaceAll('#', '')}'));
                    return SizedBox(
                      width: itemWidth,
                      child: AttendanceRingCard(
                        subjectId: s.id,
                        subjectName: s.name,
                        subjectCode: s.code,
                        classesHeld: held,
                        classesAttended: attended,
                        plannedTotal: planned,
                        subjectColor: subjectColor,
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SubjectDetailPage(subject: s, records: ref.read(attendanceProvider).where((r) => r.subjectId == s.id).toList()))),
                        onLongPress: () => showAddPastAttendanceSheet(context: context, ref: ref, subject: s),
                      ),
                    );
                  }).toList(),
                );
              }),
              ),
              const SizedBox(height: 20),
            ],

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _sectionTitle('Today\'s Classes'),
            ),
            const SizedBox(height: 12),
            // Extra class button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: InkWell(
                onTap: () => _showExtraClassSheet(context, ref),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[300]!, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.add_circle_outline, color: AppColors.primary, size: 22),
                      const SizedBox(width: 12),
                      Text(
                        'Extra class?',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (todaysClasses.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _emptyState(
                  context,
                  message: 'No classes scheduled today. Enjoy your day or build your timetable!',
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: todaysClasses.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _CompactClassTile(item: item, onTap: () => showAttendanceBottomSheet(context: context, ref: ref, item: item)),
                  )).toList(),
                ),
              ),

            const SizedBox(height: 80),
          ],
          ),
        ),
      ),
    );
  }
}

// _needToAttend removed; logic centralized in analytics/screen or AttendanceRingCard where needed.

Widget _sectionTitle(String title) {
  return Text(
    title,
    style: const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ),
  );
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
    required this.overallHeld,
    required this.atRiskCount,
    required this.threshold,
  });

  final String greeting;
  final String date;
  final double overallAttendance;
  final int overallHeld;
  final int atRiskCount;
  final int threshold;

  @override
  Widget build(BuildContext context) {
  final overallColor = overallAttendance >= 85
    ? AppColors.safeGreen
    : overallAttendance >= threshold
      ? AppColors.warningYellow
      : AppColors.dangerRed;
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
            const SizedBox(height: 24),
            RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.white, fontSize: 16),
                children: [
                  const TextSpan(text: 'Overall attendance: '),
                  TextSpan(
                    text: overallHeld == 0 ? 'No data' : '${overallAttendance.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: overallColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (atRiskCount > 0) ...[
              const SizedBox(height: 12),
              Text(
                '$atRiskCount subject${atRiskCount == 1 ? '' : 's'} need attention.',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

void _showExtraClassSheet(BuildContext context, WidgetRef ref) {
  final subjects = ref.read(subjectsProvider);
  if (subjects.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add subjects first to mark extra classes')),
    );
    return;
  }

  String? selectedSubjectId;
  int classCount = 1;
  bool wasAttended = true;
  bool isMassBunk = false;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          final bottomInset = MediaQuery.of(context).viewInsets.bottom;
          return Padding(
            padding: EdgeInsets.fromLTRB(20, 24, 20, bottomInset + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Add Extra Class',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Subject selection
                Text('Select Subject', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: const Text('Choose a subject'),
                      value: selectedSubjectId,
                      items: subjects.map((subject) {
                        return DropdownMenuItem(
                          value: subject.id,
                          child: Text(subject.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => selectedSubjectId = value);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Number of classes
                Text('Number of Classes', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      onPressed: classCount > 1 ? () => setState(() => classCount--) : null,
                      icon: const Icon(Icons.remove_circle_outline),
                      color: AppColors.primary,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$classCount',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => classCount++),
                      icon: const Icon(Icons.add_circle_outline),
                      color: AppColors.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Attendance status
                Text('Mark as', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() {
                          wasAttended = true;
                          isMassBunk = false;
                        }),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: wasAttended && !isMassBunk ? Colors.green.withValues(alpha: 0.15) : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: wasAttended && !isMassBunk ? Colors.green : Colors.grey[300]!,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_circle,
                                color: wasAttended && !isMassBunk ? Colors.green : Colors.grey[600],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Attended',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: wasAttended && !isMassBunk ? Colors.green : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() {
                          wasAttended = false;
                          isMassBunk = false;
                        }),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: !wasAttended && !isMassBunk ? Colors.red.withValues(alpha: 0.15) : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: !wasAttended && !isMassBunk ? Colors.red : Colors.grey[300]!,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.remove_circle,
                                color: !wasAttended && !isMassBunk ? Colors.red : Colors.grey[600],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Missed',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: !wasAttended && !isMassBunk ? Colors.red : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Mass bunk option
                InkWell(
                  onTap: () => setState(() {
                    isMassBunk = !isMassBunk;
                  }),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: isMassBunk ? Colors.orange.withValues(alpha: 0.15) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isMassBunk ? Colors.orange : Colors.grey[300]!,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.group_off,
                          color: isMassBunk ? Colors.orange : Colors.grey[600],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Mass Bunk',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isMassBunk ? Colors.orange : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: selectedSubjectId == null
                        ? null
                        : () async {
                            final attendanceNotifier = ref.read(attendanceProvider.notifier);
                            final now = DateTime.now();
                            final today = DateTime(now.year, now.month, now.day);
                            
                            // Determine the status based on user selection
                            AttendanceStatus status;
                            if (isMassBunk) {
                              status = AttendanceStatus.massBunk;
                            } else if (wasAttended) {
                              status = AttendanceStatus.extraClass;
                            } else {
                              status = AttendanceStatus.absent;
                            }
                            
                            await attendanceNotifier.markAttendance(
                              subjectId: selectedSubjectId!,
                              date: today,
                              status: status,
                              count: classCount,
                              notes: isMassBunk ? 'EXTRA_MB' : (wasAttended ? 'EXTRA_ATTENDED' : 'EXTRA_MISSED'),
                            );
                            
                            if (context.mounted) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isMassBunk
                                        ? 'Extra class marked as mass bunk'
                                        : wasAttended 
                                            ? 'Extra class marked as attended (+$classCount)'
                                            : 'Extra class marked as missed (-$classCount)',
                                  ),
                                  backgroundColor: isMassBunk ? Colors.orange : (wasAttended ? Colors.green : Colors.red),
                                ),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Add Extra Class',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}



Widget _statTile(String title, String value, {required Color color}) {
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 6))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      Text(title, style: TextStyle(color: Colors.grey[700], fontSize: 12)),
    ]),
  );
}

// _ribbonSubjectCard removed; replaced by AttendanceRingCard in Needs Attention area.

class _CompactClassTile extends StatelessWidget {
  const _CompactClassTile({required this.item, required this.onTap});
  final TimetableItem item;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final hex = item.subject.color.replaceAll('#', '');
    final cardColor = Color(int.parse('0xff$hex'));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 6))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Ribbon header like Schedule/Subjects
            Container(
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [cardColor, cardColor.withValues(alpha: 0.9)]),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), child: Text(item.subject.code.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13))),
                  const Spacer(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.subject.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('${item.schedule.startTime} · ${item.schedule.venue}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: onTap,
                    style: TextButton.styleFrom(
                      foregroundColor: item.record != null ? Colors.green : null,
                    ),
                    child: item.record != null
                        ? Row(mainAxisSize: MainAxisSize.min, children: const [Icon(Icons.check_circle_outline, size: 18), SizedBox(width: 6), Text('Marked')])
                        : const Text('Mark'),
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

