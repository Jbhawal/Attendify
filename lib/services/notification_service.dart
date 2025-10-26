import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService()..initialize();
});

class NotificationService {
  NotificationService();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _plugin.initialize(initializationSettings);
    
    // Request notification permissions for Android 13+ (API 33+)
    await _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();
    
    // Request exact alarm permissions for Android 12+ (API 31+)
    await _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
      ?.requestExactAlarmsPermission();
    
    await _plugin
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>()
      ?.requestPermissions(alert: true, badge: true, sound: true);
    _initialized = true;
  }

  Future<void> scheduleDailyReminder({
    required TimeOfDay time,
  }) async {
    if (!_initialized) {
      await initialize();
    }
    final now = DateTime.now();
    final scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);

    await _plugin.zonedSchedule(
      101,
      'Mark today’s attendance',
      'Don’t forget to log your classes for the day.',
      tzDate.isBefore(tz.TZDateTime.now(tz.local))
          ? tzDate.add(const Duration(days: 1))
          : tzDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'attendance_channel',
          'Attendance Reminders',
          channelDescription: 'Daily reminder to mark attendance',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          visibility: NotificationVisibility.public,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
  androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelReminders() async {
    if (!_initialized) {
      await initialize();
    }
    await _plugin.cancelAll();
  }
}
