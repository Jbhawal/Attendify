import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final existing = _box.values.cast<AttendanceRecord>().firstWhere(
          (record) =>
              record.subjectId == subjectId && _isSameDay(record.date, date),
          orElse: () =>
              AttendanceRecord(id: '', subjectId: '', date: DateTime(0), status: status),
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
    state = _box.values.cast<AttendanceRecord>().toList();
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

  double percentageForSubject(String subjectId) {
    final records = recordsForSubject(subjectId);
    if (records.isEmpty) {
      return 100;
    }
    // read mass bunk rule from settings box (defaults to 'present')
    String massRule = Hive.box(settingsBoxName).get('mass_bunk_rule') as String? ?? 'present';
    final attended = records
        .where((record) => record.status == AttendanceStatus.present || record.status == AttendanceStatus.extraClass)
        .fold<int>(0, (acc, r) => acc + r.count);
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
      return 100;
    }
    return attended / total * 100;
  }

  Map<String, int> summaryForSubject(String subjectId) {
    final records = recordsForSubject(subjectId);
    // read mass bunk rule
    String massRule = Hive.box(settingsBoxName).get('mass_bunk_rule') as String? ?? 'present';
    int held = 0;
    int attended = 0;
    int missed = 0;
    int extraClasses = 0;
    for (final r in records) {
      if (r.status == AttendanceStatus.noClass) continue;
      if (r.status == AttendanceStatus.massBunk) {
        if (massRule == 'cancelled') {
          continue; // not counted
        } else if (massRule == 'present') {
          held += r.count;
          attended += r.count;
        } else if (massRule == 'absent') {
          held += r.count;
          missed += r.count;
        }
      } else {
        held += r.count;
        if (r.status == AttendanceStatus.present || r.status == AttendanceStatus.extraClass) {
          attended += r.count;
        }
        if (r.status == AttendanceStatus.absent) {
          missed += r.count;
        }
        if (r.status == AttendanceStatus.extraClass) {
          extraClasses += r.count;
        }
      }
    }
    return {
      'held': held,
      'attended': attended,
      'missed': missed,
      'extra': extraClasses,
    };
   }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
