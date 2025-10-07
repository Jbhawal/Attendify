import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/app_colors.dart';
import '../../models/dashboard_item.dart';
import '../../providers.dart';
import '../../utils/date_utils.dart';
import '../attendance/attendance_bottom_sheet.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final greeting = ref.watch(greetingProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final overallAttendance = ref.watch(overallAttendanceProvider);
    final atRiskSubjects = ref.watch(atRiskSubjectsProvider);
    final todaysClasses = ref.watch(todaysClassesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
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
            const SizedBox(height: 32),
            _sectionTitle('Today’s Classes'),
            const SizedBox(height: 12),
            if (todaysClasses.isEmpty)
              _emptyState(
                context,
                message: 'No classes scheduled today. Enjoy your day or build your timetable!',
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
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
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

