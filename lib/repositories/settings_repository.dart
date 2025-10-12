import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../constants/hive_boxes.dart';

class SettingsRepository extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  SettingsRepository(this._box)
      : super(const AsyncValue.loading()) {
    _load();
  }

  final Box _box;

  static final provider = StateNotifierProvider<SettingsRepository,
      AsyncValue<Map<String, dynamic>>>((ref) {
    final box = Hive.box(settingsBoxName);
    return SettingsRepository(box);
  });

  Future<void> _load() async {
    final data = Map<String, dynamic>.from(_box.toMap().cast<String, dynamic>());
    state = AsyncValue.data(data);
  }

  Future<void> setUserName(String name) async {
    await _box.put('user_name', name);
    await _load();
  }

  Future<void> setProfilePhoto(String? url) async {
    if (url == null) {
      await _box.delete('profile_photo');
    } else {
      await _box.put('profile_photo', url);
    }
    await _load();
  }

  Future<void> setUserEmail(String? email) async {
    if (email == null) {
      await _box.delete('user_email');
    } else {
      await _box.put('user_email', email);
    }
    await _load();
  }

  Future<void> setDailyReminderEnabled(bool enabled) async {
    await _box.put('reminders_enabled', enabled);
    await _load();
  }

  Future<void> setReminderTime(String time) async {
    await _box.put('reminder_time', time);
    await _load();
  }

  /// Mass bunk handling rule. Stored as one of: 'present', 'cancelled', 'absent'
  Future<void> setMassBunkRule(String rule) async {
    await _box.put('mass_bunk_rule', rule);
    await _load();
  }

  /// Store or remove planned total classes for a subject.
  /// If [total] is null, the entry is removed.
  Future<void> setSubjectPlannedClasses(String subjectId, int? total) async {
    final key = 'subject_total_\$subjectId';
    if (total == null) {
      await _box.delete(key);
    } else {
      await _box.put(key, total);
    }
    await _load();
  }

  String? get userName => state.value?['user_name'] as String?;
  String? get profilePhoto => state.value?['profile_photo'] as String?;
  String? get userEmail => state.value?['user_email'] as String?;
  bool get remindersEnabled => (state.value?['reminders_enabled'] as bool?) ?? false;
  String get reminderTime => (state.value?['reminder_time'] as String?) ?? '20:00';
  String? get massBunkRule => state.value?['mass_bunk_rule'] as String?;
}
