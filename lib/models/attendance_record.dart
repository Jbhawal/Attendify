import 'package:hive/hive.dart';

enum AttendanceStatus {
  present,
  absent,
  noClass,
  extraClass,
  massBunk,
}

class AttendanceRecord {
  const AttendanceRecord({
    required this.id,
    required this.subjectId,
    required this.date,
    required this.status,
    this.notes,
  });

  final String id;
  final String subjectId;
  final DateTime date;
  final AttendanceStatus status;
  final String? notes;

  AttendanceRecord copyWith({
    String? id,
    String? subjectId,
    DateTime? date,
    AttendanceStatus? status,
    String? notes,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      date: date ?? this.date,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      id: map['id'] as String,
      subjectId: map['subject_id'] as String,
      date: DateTime.parse(map['date'] as String),
      status: AttendanceStatus.values.firstWhere(
        (value) => value.name == (map['status'] as String),
        orElse: () => AttendanceStatus.present,
      ),
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subject_id': subjectId,
      'date': date.toIso8601String(),
      'status': status.name,
      'notes': notes,
    };
  }
}

class AttendanceRecordAdapter extends TypeAdapter<AttendanceRecord> {
  @override
  int get typeId => 2;

  @override
  AttendanceRecord read(BinaryReader reader) {
    return AttendanceRecord(
      id: reader.readString(),
      subjectId: reader.readString(),
      date: DateTime.fromMillisecondsSinceEpoch(reader.readInt(), isUtc: true).toLocal(),
      status: AttendanceStatus.values[reader.readInt()],
      notes: reader.readBool() ? reader.readString() : null,
    );
  }

  @override
  void write(BinaryWriter writer, AttendanceRecord obj) {
    writer
      ..writeString(obj.id)
      ..writeString(obj.subjectId)
      ..writeInt(obj.date.toUtc().millisecondsSinceEpoch)
      ..writeInt(obj.status.index);
    if (obj.notes == null) {
      writer.writeBool(false);
    } else {
      writer
        ..writeBool(true)
        ..writeString(obj.notes!);
    }
  }
}

class AttendanceStatusAdapter extends TypeAdapter<AttendanceStatus> {
  @override
  int get typeId => 3;

  @override
  AttendanceStatus read(BinaryReader reader) {
    return AttendanceStatus.values[reader.readInt()];
  }

  @override
  void write(BinaryWriter writer, AttendanceStatus obj) {
    writer.writeInt(obj.index);
  }
}
