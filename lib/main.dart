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

  runApp(const ProviderScope(child: AttendifyApp()));
}
