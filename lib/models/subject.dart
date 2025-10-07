import 'package:hive/hive.dart';

class Subject {
  const Subject({
    required this.id,
    required this.name,
    required this.code,
    required this.professor,
    this.credits = 3,
    required this.color,
    required this.createdDate,
  });

  final String id;
  final String name;
  final String code;
  final String professor;
  final int credits;
  final String color;
  final DateTime createdDate;

  Subject copyWith({
    String? id,
    String? name,
    String? code,
    String? professor,
    int? credits,
    String? color,
    DateTime? createdDate,
  }) {
    return Subject(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      professor: professor ?? this.professor,
      credits: credits ?? this.credits,
      color: color ?? this.color,
      createdDate: createdDate ?? this.createdDate,
    );
  }

  factory Subject.fromMap(Map<String, dynamic> map) {
    return Subject(
      id: map['id'] as String,
      name: map['name'] as String,
      code: map['code'] as String,
      professor: map['professor'] as String,
      credits: (map['credits'] ?? 3) as int,
      color: map['color'] as String,
      createdDate: DateTime.parse(map['created_date'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'professor': professor,
      'credits': credits,
      'color': color,
      'created_date': createdDate.toIso8601String(),
    };
  }
}

class SubjectAdapter extends TypeAdapter<Subject> {
  @override
  int get typeId => 0;

  @override
  Subject read(BinaryReader reader) {
    return Subject(
      id: reader.readString(),
      name: reader.readString(),
      code: reader.readString(),
      professor: reader.readString(),
      credits: reader.readInt(),
      color: reader.readString(),
      createdDate:
          DateTime.fromMillisecondsSinceEpoch(reader.readInt(), isUtc: true).toLocal(),
    );
  }

  @override
  void write(BinaryWriter writer, Subject obj) {
    writer
      ..writeString(obj.id)
      ..writeString(obj.name)
      ..writeString(obj.code)
      ..writeString(obj.professor)
      ..writeInt(obj.credits)
      ..writeString(obj.color)
      ..writeInt(obj.createdDate.toUtc().millisecondsSinceEpoch);
  }
}
