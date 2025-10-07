import 'package:flutter/material.dart';

import 'attendance_record.dart';
import 'schedule_entry.dart';
import 'subject.dart';

class TimetableItem {
  const TimetableItem({
    required this.subject,
    required this.schedule,
    required this.status,
    this.record,
  });

  final Subject subject;
  final ScheduleEntry schedule;
  final AttendanceStatus? status;
  final AttendanceRecord? record;

  Color statusColor() {
    switch (status) {
      case AttendanceStatus.present:
        return Colors.green;
      case AttendanceStatus.absent:
        return Colors.redAccent;
      case AttendanceStatus.noClass:
        return Colors.grey;
      case AttendanceStatus.extraClass:
        return Colors.indigo;
      case AttendanceStatus.massBunk:
        return Colors.orange;
      case null:
        return Colors.blueGrey;
    }
  }

  String statusLabel() {
    return status?.name.replaceAll('_', ' ').toUpperCase() ?? 'UNMARKED';
  }
}
