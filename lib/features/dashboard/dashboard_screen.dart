import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/app_colors.dart';
import '../../models/dashboard_item.dart';
import '../../providers.dart';
import '../subjects/subject_detail_page.dart';
import '../../utils/date_utils.dart';
import '../attendance/attendance_bottom_sheet.dart';
import '../attendance/add_past_attendance_sheet.dart';
import '../../widgets/attendance_ring_card.dart';
 

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

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          children: [
            _HeaderCard(
              greeting: greeting,
              date: DateUtilsX.fullDate.format(selectedDate),
              overallAttendance: overallAttendance,
              overallHeld: overallHeld,
              atRiskCount: atRiskSubjects.length,
            ),
            const SizedBox(height: 20),

            // Quick stats tiles
            Row(
                children: [
                Expanded(child: _statTile('Overall %', overallHeld == 0 ? 'No data' : '${overallAttendance.toStringAsFixed(1)}%', color: AppColors.gradientStart)),
                const SizedBox(width: 12),
                Expanded(child: _statTile('At-risk', '${atRiskSubjects.length}', color: Colors.orangeAccent)),
                const SizedBox(width: 12),
                Expanded(child: _statTile('Today', '${todaysClasses.length}', color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: 20),

            // At-risk subjects horizontal scroller
            if (atRiskSubjects.isNotEmpty) ...[
              _sectionTitle('Needs Attention'),
              const SizedBox(height: 12),
              // Show Needs Attention subjects as a responsive grid of ring cards
              LayoutBuilder(builder: (context, constraints) {
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
              const SizedBox(height: 20),
            ],

            _sectionTitle('Today’s Classes'),
            const SizedBox(height: 12),
            if (todaysClasses.isEmpty)
              _emptyState(
                context,
                message: 'No classes scheduled today. Enjoy your day or build your timetable!',
              )
            else
              Column(
                children: todaysClasses.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _CompactClassTile(item: item, onTap: () => showAttendanceBottomSheet(context: context, ref: ref, item: item)),
                )).toList(),
              ),

            const SizedBox(height: 80),
          ],
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
  });

  final String greeting;
  final String date;
  final double overallAttendance;
  final int overallHeld;
  final int atRiskCount;

  @override
  Widget build(BuildContext context) {
    final overallColor = overallAttendance >= 85
        ? AppColors.safeGreen
        : overallAttendance >= 75
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
                '$atRiskCount subject${atRiskCount == 1 ? '' : 's'} need attention today.',
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

