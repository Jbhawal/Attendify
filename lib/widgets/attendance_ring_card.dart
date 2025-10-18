import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/settings_repository.dart';

/// AttendanceRingCard: displays attendance donut and an action message using
/// the user-configured attendance threshold stored in SettingsRepository.
class AttendanceRingCard extends ConsumerWidget {
  const AttendanceRingCard({
    super.key,
    required this.subjectId,
    required this.subjectName,
    required this.subjectCode,
    required this.classesHeld,
    required this.classesAttended,
    this.plannedTotal,
    this.size = 120,
    this.onTap,
    this.onLongPress,
    this.subjectColor,
  });

  final String subjectId;
  final String subjectName;
  final String? subjectCode;
  final int classesHeld;
  final int classesAttended;
  final int? plannedTotal;
  final double size;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? subjectColor;

  double _computePercentage(int? planned) {
    if (planned != null && planned > 0) return classesAttended / planned * 100.0;
    if (classesHeld == 0) return 0.0;
    return classesAttended / classesHeld * 100.0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(SettingsRepository.provider);
    final threshold = (settings.value?['attendance_threshold'] as int?) ?? 75;
    final t = threshold / 100.0;

    final pct = _computePercentage(plannedTotal);
    // Display rule: only show card when percent < 85
    if (pct >= 85) return const SizedBox.shrink();

    final inPlannedMode = plannedTotal != null && plannedTotal! > 0;
  final color = pct < (t * 100) ? Colors.redAccent : (pct < 85 ? Colors.orangeAccent : Colors.green);

    int canMiss = 0;
    int needToAttend = 0;
    if (inPlannedMode) {
      final needed = (t * plannedTotal!).ceil() - classesAttended;
      needToAttend = needed > 0 ? needed : 0;
      canMiss = (plannedTotal! - classesAttended - needToAttend) > 0 ? (plannedTotal! - classesAttended - needToAttend) : 0;
    } else {
      if (classesHeld == 0) {
        needToAttend = 0;
        canMiss = 0;
      } else {
        // fallback arithmetic for non-planned mode; keep it conservative
        canMiss = ((classesAttended - (t * classesHeld)) / (t == 0 ? 1 : t)).floor();
        needToAttend = (((t * classesHeld) - classesAttended) / (1 - t)).ceil();
      }
    }

    final missed = (classesHeld - classesAttended).clamp(0, 999);
    final safeCanMiss = canMiss >= 0 ? canMiss : 0;
    final safeNeed = needToAttend >= 0 ? needToAttend : 0;
    final accent = subjectColor ?? color;

    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header ribbon
            Container(
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [accent, accent.withAlpha((0.9 * 255).toInt())]),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(children: [
                Padding(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), child: Text(subjectCode?.toUpperCase() ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14))),
                const Spacer(),
              ]),
            ),

            // Body
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: Text(subjectName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
                  IconButton(
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    tooltip: 'How this is calculated',
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Attendance calculation'),
                        content: Text(inPlannedMode
                            ? 'Projected % = attended / planned total. Shown projection assumes remaining classes follow current attendance pattern.'
                            : 'Percent = attended / classes held. Can Miss and Need to Attend are computed relative to $threshold% threshold.'),
                        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))],
                      ),
                    ),
                    icon: Icon(Icons.info_outline, size: 18, color: Colors.grey[600]),
                  ),
                ]),

                const SizedBox(height: 10),

                // Donut
                SizedBox(
                  width: size,
                  height: size,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: (pct.clamp(0.0, 100.0) / 100.0)),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) {
                      final displayPct = (value * 100).round();
                      return Stack(alignment: Alignment.center, children: [
                        CustomPaint(size: Size(size, size), painter: _DonutPainter(progress: value, color: accent, backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest, strokeWidth: size * 0.12)),
                        Column(mainAxisSize: MainAxisSize.min, children: [
                          Text('$displayPct%', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text('$classesAttended/$classesHeld', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700], fontWeight: FontWeight.w600)),
                        ]),
                      ]);
                    },
                  ),
                ),

                const SizedBox(height: 12),

                // Action text
                Column(children: [
                  Text('Attend $safeNeed more classes to secure $threshold%! You can safely miss $safeCanMiss more classes.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  if (pct < (t * 100)) const SizedBox(height: 8),
                  if (pct < (t * 100))
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.redAccent.withAlpha((0.12 * 255).toInt()), borderRadius: BorderRadius.circular(12)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.warning_amber_rounded, size: 14, color: Colors.redAccent.shade700), const SizedBox(width: 6), Text('Action required', style: TextStyle(color: Colors.redAccent.shade700, fontWeight: FontWeight.w800, fontSize: 12))]),
                    ),
                ]),

                const SizedBox(height: 12),

                // Stats
                Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [_chipStat('Held', classesHeld, Colors.indigo), _chipStat('Attended', classesAttended, Colors.green), _chipStat('Missed', missed, Colors.redAccent), if (plannedTotal != null) _chipStat('Planned', plannedTotal!, Colors.grey)]),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chipStat(String label, int value, Color color) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), decoration: BoxDecoration(color: color.withAlpha((0.08 * 255).toInt()), borderRadius: BorderRadius.circular(12)), child: Column(children: [Text('$value', style: TextStyle(color: color, fontWeight: FontWeight.w800)), const SizedBox(height: 2), Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 11))]));
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.progress, required this.color, required this.backgroundColor, required this.strokeWidth});

  final double progress; // 0..1
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);
    if (progress > 0) {
      final start = -math.pi / 2;
      final sweep = 2 * math.pi * (progress.clamp(0.0, 1.0));
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start, sweep, false, fgPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) {
    return old.progress != progress || old.color != color || old.backgroundColor != backgroundColor || old.strokeWidth != strokeWidth;
  }
}

