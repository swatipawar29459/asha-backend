import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // ============================================================
  // INITIALIZE NOTIFICATIONS
  // ============================================================

  static Future<void> init() async {
    // Initialize timezone database
    tzdata.initializeTimeZones();

    // Android initialization
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings =
        InitializationSettings(
      android: androidSettings,
    );

    await _plugin.initialize(settings);

    // Android 13+ notification permission
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.requestNotificationsPermission();
  }

  // ============================================================
  // SCHEDULE DAILY REMINDER
  // ============================================================

  static Future<void> scheduleDailyReminder({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    final now = tz.TZDateTime.now(tz.local);

    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // If today's time has already passed,
    // schedule it for tomorrow.
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(
        const Duration(days: 1),
      );
    }

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'asha_reminders',
          'Asha Reminders',
          channelDescription:
              'Daily wellness reminders from Asha',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode:
          AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents:
          DateTimeComponents.time,
    );
  }

  // ============================================================
  // SCHEDULE REMINDER
  // Used by reminders_screen.dart
  // ============================================================

  static Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    await scheduleDailyReminder(
      id: id,
      title: title,
      body: body,
      hour: hour,
      minute: minute,
    );
  }

  // ============================================================
  // CANCEL ONE REMINDER
  // ============================================================

  static Future<void> cancelReminder(int id) async {
    await _plugin.cancel(id);
  }

  // ============================================================
  // CANCEL ONE NOTIFICATION
  // ============================================================

  static Future<void> cancel(int id) async {
    await _plugin.cancel(id);
  }

  // ============================================================
  // CANCEL ALL NOTIFICATIONS
  // ============================================================

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}