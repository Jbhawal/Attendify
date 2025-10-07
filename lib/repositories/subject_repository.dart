import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../constants/hive_boxes.dart';
import '../models/subject.dart';

final uuid = Uuid();

class SubjectRepository extends StateNotifier<List<Subject>> {
  SubjectRepository(this._box) : super(_box.values.cast<Subject>().toList());

  final Box<Subject> _box;

  static final provider = StateNotifierProvider<SubjectRepository, List<Subject>>(
    (ref) {
      final box = Hive.box<Subject>(subjectBoxName);
      return SubjectRepository(box);
    },
  );

  Future<void> addSubject({
    required String name,
    required String code,
    required String professor,
    required int credits,
    required String color,
  }) async {
    final subject = Subject(
      id: uuid.v4(),
      name: name,
      code: code,
      professor: professor,
      credits: credits,
      color: color,
      createdDate: DateTime.now(),
    );
    await _box.put(subject.id, subject);
    state = _box.values.cast<Subject>().toList();
  }

  Future<void> updateSubject(Subject updated) async {
    await _box.put(updated.id, updated);
    state = _box.values.cast<Subject>().toList();
  }

  Future<void> deleteSubject(String id) async {
    await _box.delete(id);
    state = _box.values.cast<Subject>().toList();
  }

  Subject? byId(String id) {
    for (final subject in state) {
      if (subject.id == id) {
        return subject;
      }
    }
    return null;
  }
}
