import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../constants/hive_boxes.dart';
import '../models/attendance_record.dart';

final _uuid = Uuid();

class AttendanceRepository extends StateNotifier<List<AttendanceRecord>> {
  AttendanceRepository(this._box)
      : super(_box.values.cast<AttendanceRecord>().toList());

  final Box<AttendanceRecord> _box;

  static final provider =
      StateNotifierProvider<AttendanceRepository, List<AttendanceRecord>>(
    (ref) {
      final box = Hive.box<AttendanceRecord>(attendanceBoxName);
      return AttendanceRepository(box);
    },
  );

  Future<void> markAttendance({
    required String subjectId,
    required DateTime date,
    required AttendanceStatus status,
    int count = 1,
    String? notes,
  }) async {
    // Add logging to help diagnose intermittent failures when saving records.
    final normalizedDate = DateTime(date.year, date.month, date.day);
    debugPrint('markAttendance: subject=$subjectId date=$normalizedDate status=$status count=$count notes=${notes != null && notes.isNotEmpty}');
    try {
      final existing = _box.values.cast<AttendanceRecord>().firstWhere(
            (record) => record.subjectId == subjectId && _isSameDay(record.date, normalizedDate),
            orElse: () => AttendanceRecord(id: '', subjectId: '', date: DateTime(0), status: status),
          );
      if (existing.id.isNotEmpty) {
        await _box.put(
          existing.id,
          existing.copyWith(status: status, count: count, notes: notes, date: normalizedDate),
        );
      } else {
        final record = AttendanceRecord(
          id: _uuid.v4(),
          subjectId: subjectId,
          date: normalizedDate,
          status: status,
          count: count,
          notes: notes,
        );
        await _box.put(record.id, record);
      }
    } catch (e, st) {
      // Log any Hive/storage error so we can inspect in crash reports or console
      debugPrint('markAttendance ERROR: $e');
      debugPrint(st.toString());
      rethrow;
    } finally {
      // Always refresh state from the box to ensure in-memory state matches persisted data
      try {
        state = _box.values.cast<AttendanceRecord>().toList();
      } catch (e) {
        debugPrint('markAttendance: failed to refresh state: $e');
      }
    }
  }

  Future<void> deleteRecord(String id) async {
    await _box.delete(id);
    state = _box.values.cast<AttendanceRecord>().toList();
  }

  Future<void> clearAll() async {
    await _box.clear();
    state = _box.values.cast<AttendanceRecord>().toList();
  }

  List<AttendanceRecord> recordsForSubject(String subjectId) {
    return state
        .where((record) => record.subjectId == subjectId)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  double? percentageForSubject(String subjectId) {
    final records = recordsForSubject(subjectId);
    if (records.isEmpty) {
      // No records -> no percentage available
      return null;
    }
    // read mass bunk rule from settings box (defaults to 'present')
    String massRule;
    if (Hive.isBoxOpen(settingsBoxName)) {
      massRule = Hive.box(settingsBoxName).get('mass_bunk_rule') as String? ?? 'present';
    } else {
      // settings box not opened (e.g. in unit tests) — fall back to default
      massRule = 'present';
    }
    final attended = records.fold<int>(0, (acc, r) {
      if (r.status == AttendanceStatus.present || r.status == AttendanceStatus.extraClass) return acc + r.count;
      if (r.status == AttendanceStatus.massBunk && massRule == 'present') return acc + r.count;
      return acc;
    });
    // compute total (held) respecting mass bunk rule
    int total = 0;
    for (final r in records) {
      if (r.status == AttendanceStatus.noClass) continue;
      if (r.status == AttendanceStatus.massBunk) {
        if (massRule == 'cancelled') {
          continue; // don't count
        }
        total += r.count;
      } else {
        total += r.count;
      }
    }
    if (total == 0) {
      // No held classes counted (e.g., all marked as noClass or cancelled)
      return null;
    }
    return attended / total * 100;
  }

  Map<String, int> summaryForSubject(String subjectId) {
    final records = recordsForSubject(subjectId);
    // read mass bunk rule
    String massRule;
    if (Hive.isBoxOpen(settingsBoxName)) {
      massRule = Hive.box(settingsBoxName).get('mass_bunk_rule') as String? ?? 'present';
    } else {
      // settings box not opened (e.g. in unit tests) — fall back to default
      massRule = 'present';
    }
    int held = 0;
    int attended = 0;
    int missed = 0;
    int extraClasses = 0;
    int massBunkCount = 0;
    for (final r in records) {
      if (r.status == AttendanceStatus.noClass) continue;
      
      // Check if this is an extra class (by status or by note markers)
      final isExtra = r.status == AttendanceStatus.extraClass || 
                      (r.notes?.contains('EXTRA_ATTENDED') ?? false) ||
                      (r.notes?.contains('EXTRA_MISSED') ?? false) ||
                      (r.notes?.contains('EXTRA_MB') ?? false);
      
      if (isExtra) {
        extraClasses += r.count;
      }
      
      if (r.status == AttendanceStatus.massBunk) {
        massBunkCount += r.count;
        if (massRule == 'cancelled') {
          continue; // not counted
        } else if (massRule == 'present') {
          held += r.count;
          attended += r.count;
        } else if (massRule == 'absent') {
          // Mass-bunk treated as held, but 'missed' should only count
          // explicit absences by the user. Do not increment 'missed' here.
          held += r.count;
        }
      } else {
        held += r.count;
        if (r.status == AttendanceStatus.present || r.status == AttendanceStatus.extraClass) {
          attended += r.count;
        }
        if (r.status == AttendanceStatus.absent) {
          missed += r.count;
        }
      }
    }
    return {
      'held': held,
      'attended': attended,
      'missed': missed,
      'extra': extraClasses,
      'massBunk': massBunkCount,
    };
   }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
