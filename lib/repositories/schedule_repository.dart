import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import '../constants/hive_boxes.dart';
import '../models/schedule_entry.dart';

final _uuid = Uuid();

class ScheduleRepository extends StateNotifier<List<ScheduleEntry>> {
  ScheduleRepository(this._box) : super(_box.values.cast<ScheduleEntry>().toList());

  final Box<ScheduleEntry> _box;

  static final provider =
      StateNotifierProvider<ScheduleRepository, List<ScheduleEntry>>((ref) {
    final box = Hive.box<ScheduleEntry>(scheduleBoxName);
    return ScheduleRepository(box);
  });

  Future<String> addEntry({
    required String subjectId,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    required String venue,
  }) async {
    final entry = ScheduleEntry(
      id: _uuid.v4(),
      subjectId: subjectId,
      dayOfWeek: dayOfWeek,
      startTime: startTime,
      endTime: endTime,
      venue: venue,
    );
    await _box.put(entry.id, entry);
    state = _box.values.cast<ScheduleEntry>().toList();
    return entry.id;
  }

  Future<void> updateEntry(ScheduleEntry entry) async {
    await _box.put(entry.id, entry);
    state = _box.values.cast<ScheduleEntry>().toList();
  }

  Future<void> deleteEntry(String id) async {
    await _box.delete(id);
    state = _box.values.cast<ScheduleEntry>().toList();
  }

  Future<void> clearAll() async {
    await _box.clear();
    state = _box.values.cast<ScheduleEntry>().toList();
  }

  List<ScheduleEntry> entriesForDay(int weekday) {
    return state
        .where((entry) => entry.dayOfWeek == weekday)
        .toList()
      ..sort((a, b) {
        int toMinutes(String time) {
          final patterns = ['hh:mm a', 'h:mm a', 'HH:mm', 'H:mm'];
          for (final pattern in patterns) {
            try {
              final date = DateFormat(pattern).parseStrict(time.trim().toUpperCase());
              return date.hour * 60 + date.minute;
            } catch (_) {
              // continue
            }
          }
          // If parsing fails, put it at the end
          return 999999;
        }

        return toMinutes(a.startTime).compareTo(toMinutes(b.startTime));
      });
  }
}
