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

  Future<void> setDailyReminderEnabled(bool enabled) async {
    await _box.put('reminders_enabled', enabled);
    await _load();
  }

  Future<void> setReminderTime(String time) async {
    await _box.put('reminder_time', time);
    await _load();
  }

  String? get userName => state.value?['user_name'] as String?;
  bool get remindersEnabled => (state.value?['reminders_enabled'] as bool?) ?? false;
  String get reminderTime => (state.value?['reminder_time'] as String?) ?? '20:00';
}
