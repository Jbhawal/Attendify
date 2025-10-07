import 'package:hive/hive.dart';

class ScheduleEntry {
  const ScheduleEntry({
    required this.id,
    required this.subjectId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.venue,
  });

  final String id;
  final String subjectId;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final String venue;

  ScheduleEntry copyWith({
    String? id,
    String? subjectId,
    int? dayOfWeek,
    String? startTime,
    String? endTime,
    String? venue,
  }) {
    return ScheduleEntry(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      venue: venue ?? this.venue,
    );
  }

  factory ScheduleEntry.fromMap(Map<String, dynamic> map) {
    return ScheduleEntry(
      id: map['id'] as String,
      subjectId: map['subject_id'] as String,
      dayOfWeek: map['day_of_week'] as int,
      startTime: map['start_time'] as String,
      endTime: map['end_time'] as String,
      venue: map['venue'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subject_id': subjectId,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'venue': venue,
    };
  }
}

class ScheduleEntryAdapter extends TypeAdapter<ScheduleEntry> {
  @override
  int get typeId => 1;

  @override
  ScheduleEntry read(BinaryReader reader) {
    return ScheduleEntry(
      id: reader.readString(),
      subjectId: reader.readString(),
      dayOfWeek: reader.readInt(),
      startTime: reader.readString(),
      endTime: reader.readString(),
      venue: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, ScheduleEntry obj) {
    writer
      ..writeString(obj.id)
      ..writeString(obj.subjectId)
      ..writeInt(obj.dayOfWeek)
      ..writeString(obj.startTime)
      ..writeString(obj.endTime)
      ..writeString(obj.venue);
  }
}
