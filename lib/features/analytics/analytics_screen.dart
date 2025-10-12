import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/attendance_record.dart';
import '../../models/subject.dart';
import '../../providers.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjects = ref.watch(subjectsProvider);
    final attendance = ref.watch(attendanceProvider);
    final attendanceRepo = ref.read(attendanceProvider.notifier);

    final overview = _calculateOverview(subjects, attendance);
  final riskBuckets = _calculateRiskBuckets(subjects, attendanceRepo);
    final consistency = _calculateConsistency(attendance);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(title: const Text('Analytics')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            _OverviewCard(overview: overview),
            const SizedBox(height: 20),
            _RiskDistributionCard(buckets: riskBuckets),
            const SizedBox(height: 20),
            _ConsistencyCard(consistency: consistency),
            const SizedBox(height: 20),
            if (subjects.isEmpty) _emptyState(context) else ...[
              const Text('Subject-wise', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              ...subjects.map((s) {
                final summary = attendanceRepo.summaryForSubject(s.id);
                final percent = attendanceRepo.percentageForSubject(s.id);
                return _SubjectAnalyticsCard(
                  subject: s,
                  percentage: percent,
                  summary: summary,
                  canMiss: _calculateCanMiss(summary['held'] ?? 0, summary['attended'] ?? 0),
                  needToAttend: _calculateNeedToAttend(summary['held'] ?? 0, summary['attended'] ?? 0),
                );
              }),
              // removed unnecessary .toList() in spread
            ],
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _calculateOverview(List<Subject> subjects, List<AttendanceRecord> attendance) {

    int held = 0;
    int attended = 0;
    int missed = 0;
    int extra = 0;
    int massBunk = 0;
    int cancelled = 0; // noClass

    for (final record in attendance) {
      if (record.status == AttendanceStatus.noClass) {
        cancelled += 1;
        continue;
      }
      held += 1;
      switch (record.status) {
        case AttendanceStatus.present:
          attended += 1;
          break;
        case AttendanceStatus.absent:
          missed += 1;
          break;
        case AttendanceStatus.extraClass:
          extra += 1;
          attended += 1;
          break;
        case AttendanceStatus.massBunk:
          // treat as missed for percentage but also count separately
          missed += 1;
          massBunk += 1;
          break;
        case AttendanceStatus.noClass:
          break;
      }
    }

    final overallPercentage = held == 0 ? 0.0 : attended / held * 100.0;

    return {
      'subjects': subjects.length,
      'held': held,
      'attended': attended,
      'missed': missed,
      'extra': extra,
      'massBunk': massBunk,
      'cancelled': cancelled,
      'percentage': overallPercentage,
    };
  }



  int _calculateCanMiss(int held, int attended) {
    if (held == 0) return 0;
    final limit = attended / 0.75;
    return (limit - held).floor().clamp(0, 999);
  }

  int _calculateNeedToAttend(int held, int attended) {
    if (held == 0) return 0;
    if (attended / held >= 0.75) return 0;
    final deficit = (0.75 * held) - attended;
    return (deficit / 0.25).ceil().clamp(0, 999);
  }

  Map<String, int> _calculateRiskBuckets(List<Subject> subjects, dynamic attendanceRepo) {
    var safe = 0;
    var warning = 0;
    var risky = 0;
    for (final subject in subjects) {
      final pct = attendanceRepo.percentageForSubject(subject.id);
      if (pct >= 85) {
        safe += 1;
      } else if (pct >= 75) {
        warning += 1;
      } else {
        risky += 1;
      }
    }
    return {'safe': safe, 'warning': warning, 'risky': risky};
  }

  Map<String, dynamic> _calculateConsistency(List<AttendanceRecord> attendance) {
    if (attendance.isEmpty) return {'currentStreak': 0, 'longestStreak': 0, 'lastMarked': null};

    final byDay = <DateTime, List<AttendanceRecord>>{};
    for (final record in attendance) {
      if (record.status == AttendanceStatus.noClass) continue;
      final normalized = DateTime(record.date.year, record.date.month, record.date.day);
      byDay.putIfAbsent(normalized, () => []).add(record);
    }

    if (byDay.isEmpty) return {'currentStreak': 0, 'longestStreak': 0, 'lastMarked': null};

    final days = byDay.keys.toList()..sort();
    var currentStreak = 0;
    var longestStreak = 0;
    DateTime? previousDay;

    for (final day in days) {
      final dayRecords = byDay[day]!;
      final attended = dayRecords.any((record) => record.status == AttendanceStatus.present || record.status == AttendanceStatus.extraClass);
      if (attended) {
        if (previousDay != null && day.difference(previousDay).inDays == 1) {
          currentStreak += 1;
        } else {
          currentStreak = 1;
        }
        longestStreak = currentStreak > longestStreak ? currentStreak : longestStreak;
      } else {
        currentStreak = 0;
      }
      previousDay = day;
    }

    return {'currentStreak': currentStreak, 'longestStreak': longestStreak, 'lastMarked': days.last};
  }

 

  Widget _emptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          const Icon(Icons.insights_outlined, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text('Add some attendance first', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Once you start marking attendance, rich analytics will appear here.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 18, offset: const Offset(0, 8)),
      ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
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
              _statTile('Mass bunk', overview['massBunk'] as int? ?? 0),
              _statTile('Cancelled', overview['cancelled'] as int? ?? 0),
              Container(
                width: 140,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.indigo.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(18)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Overall %', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text('${(overview['percentage'] as double? ?? 0).toStringAsFixed(1)}%', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ]),
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
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$value', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ]),
    );
  }
}



// _ProjectionCard removed because it was unused. Kept analytics UI minimal.

class _RiskDistributionCard extends StatelessWidget {
  const _RiskDistributionCard({required this.buckets});
  final Map<String, int> buckets;

  @override
  Widget build(BuildContext context) {
    final total = buckets.values.fold<int>(0, (acc, value) => acc + value);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 18, offset: const Offset(0, 8)),
      ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Risk Distribution', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        if (total == 0) const Text('Add subjects and start marking attendance to see risk categories.', style: TextStyle(fontSize: 13)) else ...[
          _riskRow(label: 'Healthy (≥85%)', value: buckets['safe'] ?? 0, color: Colors.green, total: total),
          const SizedBox(height: 10),
          _riskRow(label: 'Watchlist (75-84%)', value: buckets['warning'] ?? 0, color: Colors.orangeAccent, total: total),
          const SizedBox(height: 10),
          _riskRow(label: 'Critical (<75%)', value: buckets['risky'] ?? 0, color: Colors.redAccent, total: total),
        ]
      ]),
    );
  }

  Widget _riskRow({required String label, required int value, required Color color, required int total}) {
    final percentage = total == 0 ? 0.0 : (value / total) * 100;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
        Text('${percentage.toStringAsFixed(0)}%', style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      ]),
      const SizedBox(height: 6),
      ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: total == 0 ? 0 : value / total, minHeight: 10, backgroundColor: Colors.grey[200], valueColor: AlwaysStoppedAnimation(color))),
      const SizedBox(height: 4),
      Text('$value subject${value == 1 ? '' : 's'}', style: const TextStyle(fontSize: 11)),
    ]);
  }
}

class _ConsistencyCard extends StatelessWidget {
  const _ConsistencyCard({required this.consistency});
  final Map<String, dynamic> consistency;

  @override
  Widget build(BuildContext context) {
    final currentStreak = consistency['currentStreak'] as int? ?? 0;
    final longestStreak = consistency['longestStreak'] as int? ?? 0;
    final lastMarked = consistency['lastMarked'] as DateTime?;
    final formatter = DateFormat('EEE, dd MMM');

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [
  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 18, offset: const Offset(0, 8)),
      ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Consistency Tracker', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _streakTile(title: 'Current streak', value: currentStreak, accent: Colors.blueAccent)),
          const SizedBox(width: 12),
          Expanded(child: _streakTile(title: 'Best streak', value: longestStreak, accent: Colors.purpleAccent)),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          const Icon(Icons.calendar_today, size: 18),
          const SizedBox(width: 12),
          Expanded(child: Text(lastMarked == null ? 'No attendance recorded yet.' : 'Last logged on ${formatter.format(lastMarked)}', style: const TextStyle(fontSize: 13))),
        ]),
      ]),
    );
  }

  Widget _streakTile({required String title, required int value, required Color accent}) {
  return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(18)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('$value days', style: TextStyle(color: accent, fontSize: 18, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
    ]));
  }
}

class _SubjectAnalyticsCard extends StatelessWidget {
  const _SubjectAnalyticsCard({required this.subject, required this.percentage, required this.summary, required this.canMiss, required this.needToAttend});

  final Subject subject;
  final double percentage;
  final Map<String, int> summary;
  final int canMiss;
  final int needToAttend;

  @override
  Widget build(BuildContext context) {
    final color = Color(int.parse('0xff${subject.color.replaceAll('#', '')}'));
    final statusColor = percentage >= 85 ? Colors.green : percentage >= 75 ? Colors.orange : Colors.redAccent;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 14, offset: const Offset(0, 8)),
        ]),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ribbon at the top (flush)
            Container(
              height: 36,
              decoration: BoxDecoration(gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.9)])),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Text(subject.code.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                ),
                const Spacer(),
              ]),
            ),
            // content below ribbon
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(subject.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text('By ${subject.professor}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                ])),
                Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(16)), child: Text('${percentage.toStringAsFixed(1)}%', style: TextStyle(color: statusColor, fontWeight: FontWeight.w600))),
              ]),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Wrap(spacing: 16, runSpacing: 16, children: [
                _chip('Held', summary['held'] ?? 0, Colors.indigo),
                _chip('Attended', summary['attended'] ?? 0, Colors.green),
                _chip('Missed', summary['missed'] ?? 0, Colors.redAccent),
                _chip('Extra', summary['extra'] ?? 0, Colors.deepPurple),
              ]),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(children: [
                Expanded(child: _highlightCard(title: 'Can Miss', value: canMiss, description: 'classes at 75%', color: Colors.orangeAccent)),
                const SizedBox(width: 12),
                Expanded(child: _highlightCard(title: 'Need to Attend', value: needToAttend, description: 'more to reach 75%', color: Colors.green)),
              ]),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$value', style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ]),
    );
  }

  Widget _highlightCard({required String title, required int value, required String description, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$value', style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(description, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ]),
    );
  }
}
