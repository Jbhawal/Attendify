import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/attendance_record.dart';
import '../../models/subject.dart';
import '../../providers.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjects = ref.watch(subjectsProvider);
    final attendance = ref.watch(attendanceProvider);

    final overview = _calculateOverview(subjects, attendance);
    final weeklyTrend = _calculateWeeklyTrend(attendance);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        title: const Text('Analytics'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            _OverviewCard(overview: overview),
            const SizedBox(height: 20),
            _WeeklyTrendCard(trend: weeklyTrend),
            const SizedBox(height: 20),
            if (subjects.isEmpty)
              _emptyState(context)
            else
              ...subjects.map(
                (subject) {
                  final summary = ref
                      .read(attendanceProvider.notifier)
                      .summaryForSubject(subject.id);
                  final percentage = ref
                      .read(attendanceProvider.notifier)
                      .percentageForSubject(subject.id);
                  final canMiss = _calculateCanMiss(summary['held'] ?? 0, summary['attended'] ?? 0);
                  final needToAttend = _calculateNeedToAttend(
                    summary['held'] ?? 0,
                    summary['attended'] ?? 0,
                  );
                  return _SubjectAnalyticsCard(
                    subject: subject,
                    percentage: percentage,
                    summary: summary,
                    canMiss: canMiss,
                    needToAttend: needToAttend,
                  );
                },
              ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _calculateOverview(
    List<Subject> subjects,
    List<AttendanceRecord> attendance,
  ) {
    int held = 0;
    int attendedCount = 0;
    int missed = 0;
    int extra = 0;

    for (final record in attendance) {
      if (record.status == AttendanceStatus.noClass) continue;
      held += 1;
      switch (record.status) {
        case AttendanceStatus.present:
          attendedCount += 1;
          break;
        case AttendanceStatus.absent:
          missed += 1;
          break;
        case AttendanceStatus.extraClass:
          extra += 1;
          attendedCount += 1;
          break;
        case AttendanceStatus.massBunk:
          missed += 1;
          break;
        case AttendanceStatus.noClass:
          break;
      }
    }

    final overallPercentage = held == 0 ? 0 : attendedCount / held * 100;

    return {
      'subjects': subjects.length,
      'held': held,
      'attended': attendedCount,
      'missed': missed,
      'extra': extra,
      'percentage': overallPercentage,
    };
  }

  List<Map<String, dynamic>> _calculateWeeklyTrend(List<AttendanceRecord> attendance) {
    final now = DateTime.now();
    final last7Days = List.generate(7, (index) => now.subtract(Duration(days: 6 - index)));

    return last7Days.map((day) {
      final records = attendance.where((record) => _isSameDay(record.date, day));
      final held = records.where((record) => record.status != AttendanceStatus.noClass).length;
      final attended = records
          .where((record) =>
              record.status == AttendanceStatus.present ||
              record.status == AttendanceStatus.extraClass)
          .length;
      final percentage = held == 0 ? 0 : attended / held * 100;
      return {
        'day': day,
        'percentage': percentage,
        'held': held,
      };
    }).toList();
  }

  int _calculateCanMiss(int held, int attended) {
    if (held == 0) {
      return 0;
    }
    final limit = attended / 0.75;
    return (limit - held).floor().clamp(0, 999);
  }

  int _calculateNeedToAttend(int held, int attended) {
    if (held == 0) {
      return 0;
    }
    if (attended / held >= 0.75) {
      return 0;
    }
    final deficit = (0.75 * held) - attended;
    return (deficit / 0.25).ceil().clamp(0, 999);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _emptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Icon(Icons.insights_outlined, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Add some attendance first',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Once you start marking attendance, rich analytics will appear here.',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.overview});

  final Map<String, dynamic> overview;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Overview',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _statTile('Subjects', overview['subjects'] as int? ?? 0),
              _statTile('Classes Held', overview['held'] as int? ?? 0),
              _statTile('Attended', overview['attended'] as int? ?? 0),
              _statTile('Missed', overview['missed'] as int? ?? 0),
              _statTile('Extra Classes', overview['extra'] as int? ?? 0),
              Container(
                width: 140,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.indigo.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Overall %',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(overview['percentage'] as double? ?? 0).toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statTile(String label, int value) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _WeeklyTrendCard extends StatelessWidget {
  const _WeeklyTrendCard({required this.trend});

  final List<Map<String, dynamic>> trend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weekly Trend',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: trend.map((day) {
                final percentage = (day['percentage'] as double).clamp(0.0, 100.0);
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '${percentage.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            width: 24,
                            height: (percentage / 100) * 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.indigoAccent,
                                  Colors.blueAccent,
                                ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _weekdayLabel(day['day'] as DateTime),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _weekdayLabel(DateTime date) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return labels[(date.weekday + 6) % 7];
  }
}

class _SubjectAnalyticsCard extends StatelessWidget {
  const _SubjectAnalyticsCard({
    required this.subject,
    required this.percentage,
    required this.summary,
    required this.canMiss,
    required this.needToAttend,
  });

  final Subject subject;
  final double percentage;
  final Map<String, int> summary;
  final int canMiss;
  final int needToAttend;

  @override
  Widget build(BuildContext context) {
    final color = Color(int.parse('0xff${subject.color.replaceAll('#', '')}'));
    final statusColor = percentage >= 85
        ? Colors.green
        : percentage >= 75
            ? Colors.orange
            : Colors.redAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 44,
                width: 44,
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
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'By ${subject.professor}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _chip('Held', summary['held'] ?? 0, Colors.indigo),
              _chip('Attended', summary['attended'] ?? 0, Colors.green),
              _chip('Missed', summary['missed'] ?? 0, Colors.redAccent),
              _chip('Extra', summary['extra'] ?? 0, Colors.deepPurple),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _highlightCard(
                  title: 'Can Miss',
                  value: canMiss,
                  description: 'classes at 75%',
                  color: Colors.orangeAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _highlightCard(
                  title: 'Need to Attend',
                  value: needToAttend,
                  description: 'more to reach 75%',
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
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
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _highlightCard({
    required String title,
    required int value,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
