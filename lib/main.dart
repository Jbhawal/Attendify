import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'constants/hive_boxes.dart';
import 'models/attendance_record.dart';
import 'models/schedule_entry.dart';
import 'models/subject.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive
    ..registerAdapter(SubjectAdapter())
    ..registerAdapter(ScheduleEntryAdapter())
    ..registerAdapter(AttendanceRecordAdapter())
    ..registerAdapter(AttendanceStatusAdapter());

  await Future.wait([
    Hive.openBox<Subject>(subjectBoxName),
    Hive.openBox<ScheduleEntry>(scheduleBoxName),
    Hive.openBox<AttendanceRecord>(attendanceBoxName),
    Hive.openBox(settingsBoxName),
  ]);

  await _seedSampleData();

  runApp(const ProviderScope(child: AttendifyApp()));
}

Future<void> _seedSampleData() async {
  final subjectBox = Hive.box<Subject>(subjectBoxName);
  final attendanceBox = Hive.box<AttendanceRecord>(attendanceBoxName);
  final scheduleBox = Hive.box<ScheduleEntry>(scheduleBoxName);

  // Only seed if no data exists
  if (subjectBox.isNotEmpty) return;

  // Sample subjects
  final subjects = [
    Subject(
      id: 'math-101',
      name: 'Advanced Mathematics',
      code: 'MATH101',
      professor: 'Dr. Sarah Johnson',
      credits: 4,
      color: '#FF6B6B',
      createdDate: DateTime.now(),
    ),
    Subject(
      id: 'cs-201',
      name: 'Data Structures & Algorithms',
      code: 'CS201',
      professor: 'Prof. Michael Chen',
      credits: 3,
      color: '#4ECDC4',
      createdDate: DateTime.now(),
    ),
    Subject(
      id: 'physics-101',
      name: 'Physics I',
      code: 'PHYS101',
      professor: 'Dr. Emily Davis',
      credits: 4,
      color: '#45B7D1',
      createdDate: DateTime.now(),
    ),
    Subject(
      id: 'english-101',
      name: 'English Literature',
      code: 'ENG101',
      professor: 'Ms. Jennifer Wilson',
      credits: 2,
      color: '#96CEB4',
      createdDate: DateTime.now(),
    ),
    Subject(
      id: 'chemistry-101',
      name: 'Organic Chemistry',
      code: 'CHEM101',
      professor: 'Dr. Robert Brown',
      credits: 3,
      color: '#FFEAA7',
      createdDate: DateTime.now(),
    ),
  ];

  // Add subjects
  for (final subject in subjects) {
    await subjectBox.put(subject.id, subject);
  }

  // Sample schedule entries
  final schedules = [
    ScheduleEntry(
      id: 'math-mon',
      subjectId: 'math-101',
      dayOfWeek: 1, // Monday
      startTime: '09:00 AM',
      endTime: '10:30 AM',
      venue: 'Room 201',
    ),
    ScheduleEntry(
      id: 'cs-wed',
      subjectId: 'cs-201',
      dayOfWeek: 3, // Wednesday
      startTime: '11:00 AM',
      endTime: '12:30 PM',
      venue: 'Lab 105',
    ),
    ScheduleEntry(
      id: 'physics-tue',
      subjectId: 'physics-101',
      dayOfWeek: 2, // Tuesday
      startTime: '10:00 AM',
      endTime: '11:30 AM',
      venue: 'Physics Lab',
    ),
    ScheduleEntry(
      id: 'english-thu',
      subjectId: 'english-101',
      dayOfWeek: 4, // Thursday
      startTime: '02:00 PM',
      endTime: '03:30 PM',
      venue: 'Room 305',
    ),
    ScheduleEntry(
      id: 'chemistry-fri',
      subjectId: 'chemistry-101',
      dayOfWeek: 5, // Friday
      startTime: '01:00 PM',
      endTime: '02:30 PM',
      venue: 'Chemistry Lab',
    ),
  ];

  // Add schedules
  for (final schedule in schedules) {
    await scheduleBox.put(schedule.id, schedule);
  }

  // Generate attendance records for the past 8 weeks
  final now = DateTime.now();
  final attendanceRecords = <AttendanceRecord>[];
  final random = DateTime.now().millisecondsSinceEpoch;

  for (int week = 0; week < 8; week++) {
    for (final subject in subjects) {
      final scheduleForSubject = schedules.where((s) => s.subjectId == subject.id);
      if (scheduleForSubject.isEmpty) continue;

      final schedule = scheduleForSubject.first;
      final classDate = now.subtract(Duration(days: week * 7 + (schedule.dayOfWeek - now.weekday + 7) % 7));

      // Skip future dates
      if (classDate.isAfter(now)) continue;

      // Random attendance status with some logic
      AttendanceStatus status;
      final randomValue = (random + week * subject.id.hashCode) % 100;

      if (randomValue < 75) {
        status = AttendanceStatus.present;
      } else if (randomValue < 85) {
        status = AttendanceStatus.absent;
      } else if (randomValue < 90) {
        status = AttendanceStatus.noClass;
      } else if (randomValue < 95) {
        status = AttendanceStatus.extraClass;
      } else {
        status = AttendanceStatus.massBunk;
      }

      // Add some notes occasionally
      String? notes;
      if ((random + week) % 10 == 0) {
        notes = 'Additional notes for this class';
      }

      attendanceRecords.add(AttendanceRecord(
        id: '${subject.id}-${classDate.toIso8601String()}',
        subjectId: subject.id,
        date: classDate,
        status: status,
        notes: notes,
      ));
    }
  }

  // Add attendance records
  for (final record in attendanceRecords) {
    await attendanceBox.put(record.id, record);
  }
}
