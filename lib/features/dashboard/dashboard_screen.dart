import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/app_colors.dart';
import '../../models/dashboard_item.dart';
import '../../providers.dart';
import '../subjects/subject_detail_page.dart';
import '../../utils/date_utils.dart';
import '../attendance/attendance_bottom_sheet.dart';
import '../../models/subject.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final greeting = ref.watch(greetingProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final overallAttendance = ref.watch(overallAttendanceProvider);
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
              atRiskCount: atRiskSubjects.length,
            ),
            const SizedBox(height: 20),

            // Quick stats tiles
            Row(
              children: [
                Expanded(child: _statTile('Overall %', '${overallAttendance.toStringAsFixed(1)}%', color: AppColors.gradientStart)),
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
              // Show Needs Attention subjects as a vertical full-width list (one after another)
              Column(
                children: List.generate(atRiskSubjects.length, (index) {
                  final s = atRiskSubjects[index];
                  final pct = attendanceRepo.percentageForSubject(s.id);
                  final summary = attendanceRepo.summaryForSubject(s.id);
                  final held = summary['held'] ?? 0;
                  final attended = summary['attended'] ?? 0;
                  final settingsMap = ref.watch(settingsProvider).value ?? <String, dynamic>{};
                  final planned = settingsMap['subject_total_\${s.id}'] as int?;
                  final need = _needToAttend(held, attended, planned: planned);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SubjectDetailPage(subject: s, records: ref.read(attendanceProvider).where((r) => r.subjectId == s.id).toList()))),
                      child: _ribbonSubjectCard(context, s, pct, needToAttend: need, fullWidth: true),
                    ),
                  );
                }),
              ),
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

int _needToAttend(int held, int attended, {int? planned}) {
  // Mirror logic from analytics: if planned total provided, calculate remaining must-attend
  if (planned != null && planned > held) {
    final remaining = planned - held;
    final targetAttended = (0.75 * planned).ceil();
    final need = (targetAttended - attended).clamp(0, remaining);
    return need;
  }
  if (held == 0) return 0;
  if (attended / held >= 0.75) return 0;
  final deficit = (0.75 * held) - attended;
  return (deficit / 0.25).ceil().clamp(0, 999);
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
    required this.atRiskCount,
  });

  final String greeting;
  final String date;
  final double overallAttendance;
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
                    text: '${overallAttendance.toStringAsFixed(1)}%',
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

Widget _ribbonSubjectCard(BuildContext context, Subject subject, double percentage, {int? needToAttend, bool fullWidth = false}) {
  final color = Color(int.parse('0xff${subject.color.replaceAll('#', '')}'));
  final card = ClipRRect(
    borderRadius: BorderRadius.circular(14),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ribbon
          Container(
            height: 36,
            decoration: BoxDecoration(gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.9)])),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: [
                Text(subject.code.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                const Spacer(),
                Icon(Icons.warning_amber_rounded, color: Colors.white.withValues(alpha: 0.95), size: 18),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subject.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('${percentage.toStringAsFixed(1)}%', style: TextStyle(color: percentage >= 75 ? Colors.green : Colors.redAccent, fontWeight: FontWeight.w800)),
                    const Spacer(),
                    // small pill showing 'Needs attention' and optionally needToAttend
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.orangeAccent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                      child: Row(children: [
                        Text('Needs', style: TextStyle(color: Colors.orangeAccent.shade700, fontWeight: FontWeight.w700, fontSize: 12)),
                        if (needToAttend != null && needToAttend > 0) ...[
                          const SizedBox(width: 6),
                          Text('$needToAttend', style: TextStyle(color: Colors.orangeAccent.shade700, fontWeight: FontWeight.w900, fontSize: 12)),
                        ]
                      ]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  if (fullWidth) {
    return SizedBox(width: double.infinity, child: card);
  }
  return SizedBox(width: 220, child: card);
}

class _CompactClassTile extends StatelessWidget {
  const _CompactClassTile({required this.item, required this.onTap});
  final TimetableItem item;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 6))]),
        child: Row(children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: Color(int.parse('0xff${item.subject.color.replaceAll('#', '')}')), borderRadius: BorderRadius.circular(10)), child: Center(child: Text(item.subject.code.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.subject.name, style: const TextStyle(fontWeight: FontWeight.w600)), const SizedBox(height: 4), Text('${item.schedule.startTime} · ${item.schedule.venue}', style: TextStyle(color: Colors.grey[600], fontSize: 13))])),
          const SizedBox(width: 8),
          TextButton(onPressed: onTap, child: const Text('Mark')),
        ]),
      ),
    );
  }
}

