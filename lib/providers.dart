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
  if (subjects.isEmpty) {
    return 0;
  }
  int held = 0;
  int attended = 0;
  for (final subject in subjects) {
    final records = attendance
        .where((record) => record.subjectId == subject.id)
        .where((record) => record.status != AttendanceStatus.noClass);
    final total = records.length;
    if (total == 0) {
      continue;
    }
    held += total;
    attended += records
        .where((record) => record.status == AttendanceStatus.present)
        .length;
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
  int held = 0;
  for (final subject in subjects) {
    final records = attendance.where((record) => record.subjectId == subject.id && record.status != AttendanceStatus.noClass);
    held += records.length;
  }
  return held;
});

final atRiskSubjectsProvider = Provider<List<Subject>>((ref) {
  final subjects = ref.watch(subjectsProvider);
  // watch attendance list so provider refreshes when records change
  ref.watch(attendanceProvider);
  final attendanceRepo = ref.read(attendanceProvider.notifier);

  return subjects.where((subject) {
    // Use the repository's percentage calculation which respects mass-bunk rule
    final percentage = attendanceRepo.percentageForSubject(subject.id);
    // If there are no records percentageForSubject returns null, so
    // subjects with no records won't be considered at-risk.
    if (percentage == null) return false;
    return percentage < 75;
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
