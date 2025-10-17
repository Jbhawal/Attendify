import 'dart:io';

import 'package:attendify/models/attendance_record.dart';
import 'package:attendify/repositories/attendance_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  group('AttendanceRepository', () {
    late Directory tempDir;
    late Box<AttendanceRecord> box;
    late AttendanceRepository repository;

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      tempDir = await Directory.systemTemp.createTemp('attendify_test');
      Hive.init(tempDir.path);
      if (!Hive.isAdapterRegistered(AttendanceRecordAdapter().typeId)) {
        Hive.registerAdapter(AttendanceRecordAdapter());
      }
      if (!Hive.isAdapterRegistered(AttendanceStatusAdapter().typeId)) {
        Hive.registerAdapter(AttendanceStatusAdapter());
      }
      box = await Hive.openBox<AttendanceRecord>('attendance_test');
      repository = AttendanceRepository(box);
    });

    tearDown(() async {
      await box.clear();
      await box.close();
      await Hive.deleteBoxFromDisk('attendance_test');
      await tempDir.delete(recursive: true);
      await Hive.close();
    });

    test('markAttendance replaces existing record for same day', () async {
      const subjectId = 'sub-1';
      final date = DateTime(2024, 10, 5);

      await repository.markAttendance(
        subjectId: subjectId,
        date: date,
        status: AttendanceStatus.present,
      );
      await repository.markAttendance(
        subjectId: subjectId,
        date: date,
        status: AttendanceStatus.absent,
      );

      final records = repository.recordsForSubject(subjectId);
      expect(records.length, 1);
      expect(records.first.status, AttendanceStatus.absent);
    });

    test('percentageForSubject counts extra classes as attended', () async {
      const subjectId = 'ml';
      await repository.markAttendance(
        subjectId: subjectId,
        date: DateTime(2024, 10, 1),
        status: AttendanceStatus.present,
      );
      await repository.markAttendance(
        subjectId: subjectId,
        date: DateTime(2024, 10, 2),
        status: AttendanceStatus.extraClass,
      );
      await repository.markAttendance(
        subjectId: subjectId,
        date: DateTime(2024, 10, 3),
        status: AttendanceStatus.absent,
      );

  final percentage = repository.percentageForSubject(subjectId)!;
  expect(percentage, closeTo(66.6, 0.5));
    });
  });
}
