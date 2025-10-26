import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/attendance_record.dart';
import 'models/dashboard_item.dart';
import 'models/subject.dart';
import 'repositories/attendance_repository.dart';
import 'repositories/schedule_repository.dart';
import 'repositories/settings_repository.dart';
import 'repositories/subject_repository.dart';
import 'utils/date_utils.dart';

final subjectsProvider = SubjectRepository.provider;
final scheduleProvider = ScheduleRepository.provider;
final attendanceProvider = AttendanceRepository.provider;
final settingsProvider = SettingsRepository.provider;

final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

final todaysClassesProvider = Provider<List<TimetableItem>>((ref) {
  final date = ref.watch(selectedDateProvider);
  final schedules = ref.watch(scheduleProvider);
  final subjects = ref.watch(subjectsProvider);
  final attendance = ref.watch(attendanceProvider);
  final weekday = (date.weekday + 6) % DateTime.daysPerWeek;

  List<TimetableItem> items = [];
  for (final entry in schedules.where((e) => e.dayOfWeek == weekday)) {
    final subject = subjects.firstWhere(
      (subject) => subject.id == entry.subjectId,
      orElse: () => Subject(
        id: '',
        name: 'Unknown',
        code: '',
        professor: '',
        color: '#000000',
        createdDate: DateTime(2000),
      ),
    );
    if (subject.id.isEmpty) {
      continue;
    }
    AttendanceRecord? record;
    for (final item in attendance) {
      if (item.subjectId == subject.id && _isSameDay(item.date, date)) {
        record = item;
        break;
      }
    }
    items.add(TimetableItem(
      subject: subject,
      schedule: entry,
      status: record?.status,
      record: record,
    ));
  }

  items.sort((a, b) => a.schedule.startTime.compareTo(b.schedule.startTime));
  return items;
});

final overallAttendanceProvider = Provider<double>((ref) {
  final attendance = ref.watch(attendanceProvider);
  final subjects = ref.watch(subjectsProvider);
  final settings = ref.watch(settingsProvider).value ?? <String, dynamic>{};
  final massRule = settings['mass_bunk_rule'] as String? ?? 'present';
  
  if (subjects.isEmpty) {
    return 0;
  }
  int held = 0;
  int attended = 0;
  
  for (final subject in subjects) {
    final records = attendance
        .where((record) => record.subjectId == subject.id)
        .where((record) => record.status != AttendanceStatus.noClass)
        .toList();
    
    if (records.isEmpty) {
      continue;
    }
    
    for (final r in records) {
      if (r.status == AttendanceStatus.massBunk) {
        if (massRule == 'cancelled') {
          continue; // not counted
        } else if (massRule == 'present') {
          held += r.count;
          attended += r.count;
        } else if (massRule == 'absent') {
          held += r.count;
        }
      } else {
        held += r.count;
        if (r.status == AttendanceStatus.present || r.status == AttendanceStatus.extraClass) {
          attended += r.count;
        }
      }
    }
  }
  
  if (held == 0) {
    return 100;
  }
  return attended / held * 100;
});

// Total number of held classes across all subjects (ignoring noClass)
final overallHeldProvider = Provider<int>((ref) {
  final attendance = ref.watch(attendanceProvider);
  final subjects = ref.watch(subjectsProvider);
  final settings = ref.watch(settingsProvider).value ?? <String, dynamic>{};
  final massRule = settings['mass_bunk_rule'] as String? ?? 'present';
  
  int held = 0;
  for (final subject in subjects) {
    final records = attendance
        .where((record) => record.subjectId == subject.id && record.status != AttendanceStatus.noClass)
        .toList();
    
    for (final r in records) {
      if (r.status == AttendanceStatus.massBunk) {
        if (massRule == 'cancelled') {
          continue; // not counted
        } else {
          held += r.count;
        }
      } else {
        held += r.count;
      }
    }
  }
  return held;
});

final atRiskSubjectsProvider = Provider<List<Subject>>((ref) {
  final subjects = ref.watch(subjectsProvider);
  // watch attendance list so provider refreshes when records change
  ref.watch(attendanceProvider);
  final attendanceRepo = ref.read(attendanceProvider.notifier);

  final settings = ref.watch(settingsProvider).value ?? <String, dynamic>{};

  final threshold = (settings['attendance_threshold'] as int?) ?? 75;
  final t = threshold / 100.0;

  return subjects.where((subject) {
    // Use the repository's summary which respects mass-bunk rule
    final summary = attendanceRepo.summaryForSubject(subject.id);
    final held = summary['held'] ?? 0;
    final attended = summary['attended'] ?? 0;

    // If a planned total is provided, compute canMiss and only flag when
    // canMiss <= 2 (user-requested threshold). This mirrors analytics logic.
    final plannedKey = 'subject_total_${subject.id}';
    final planned = settings[plannedKey] as int?;
    if (planned != null && planned > held) {
      final remaining = planned - held;
      final targetAttended = (t * planned).ceil();
      final neededNow = (targetAttended - attended).clamp(0, planned);
      final canMiss = (remaining - neededNow).clamp(0, 999);
      return canMiss <= 2;
    }

    // Otherwise fall back to percentage-based rule
    final percentage = attendanceRepo.percentageForSubject(subject.id);
    if (percentage == null) return false;
    return percentage < (t * 100);
  }).toList();
});

final greetingProvider = Provider<String>((ref) {
  final settings = ref.watch(settingsProvider);
  return settings.when(
    data: (map) => DateUtilsX.greetingFor(
      DateTime.now(),
      name: map['user_name'] as String?,
    ),
    loading: () => 'Hi there!',
    error: (_, __) => 'Hello!',
  );
});

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
