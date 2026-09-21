import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

import 'health_profile_store.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // ============================================================
  // NOTIFICATION IDS
  // ============================================================

  static const int cycleNotificationId = 1001;

  // ============================================================
  // INITIALIZE NOTIFICATIONS
  // ============================================================

  static Future<void> init() async {
    // Initialize timezone database
    tzdata.initializeTimeZones();

    // Use the device's local timezone
    tz.setLocalLocation(
      tz.getLocation(
        DateTime.now().timeZoneName,
      ),
    );

    // Android initialization
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings =
        InitializationSettings(
      android: androidSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse:
          _onNotificationTapped,
    );

    // Android 13+ notification permission
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.requestNotificationsPermission();
  }

  // ============================================================
  // NOTIFICATION TAPPED
  // ============================================================

  static Future<void> _onNotificationTapped(
    NotificationResponse response,
  ) async {
    final payload = response.payload;

    if (payload == 'cycle_notification') {
      await markAllCycleNotificationsAsRead();
    }
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
  // CYCLE NOTIFICATION
  // ============================================================

  static Future<void> scheduleCycleNotification({
    int hour = 9,
    int minute = 0,
  }) async {
    final lastPeriod =
        HealthProfileStore.lastPeriodDate;

    if (lastPeriod == null) {
      return;
    }

    final cycleLength =
        HealthProfileStore.cycleLength;

    final cycleDay =
        HealthProfileStore.currentCycleDay;

    if (cycleDay < 1) {
      return;
    }

    // ----------------------------------------------------------
    // Avoid creating the same cycle notification repeatedly.
    // ----------------------------------------------------------

    final alreadyCreated =
        await _wasCycleNotificationCreatedToday(
      cycleDay,
    );

    if (alreadyCreated) {
      return;
    }

    // ----------------------------------------------------------
    // Determine the appropriate message.
    // ----------------------------------------------------------

    final cycleMessage =
        _getCycleMessage(
      cycleDay: cycleDay,
      cycleLength: cycleLength,
    );

    // ----------------------------------------------------------
    // Save notification in Asha's own notification history.
    // ----------------------------------------------------------

    await _saveNotification(
      title: cycleMessage.title,
      body: cycleMessage.body,
      cycleDay: cycleDay,
    );

    // ----------------------------------------------------------
    // Cancel any previous cycle notification.
    // We only want the current cycle notification.
    // ----------------------------------------------------------

    await _plugin.cancel(
      cycleNotificationId,
    );

    final now =
        tz.TZDateTime.now(tz.local);

    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // If today's notification time has already passed,
    // send it shortly after the app is opened.
    //
    // This makes testing easier and prevents the user from
    // waiting until tomorrow just because they opened Asha
    // after 9:00 AM.
    if (scheduled.isBefore(now)) {
      scheduled =
          now.add(const Duration(seconds: 5));
    }

    await _plugin.zonedSchedule(
      cycleNotificationId,
      cycleMessage.title,
      cycleMessage.body,
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'asha_cycle',
          'Asha Cycle Notifications',
          channelDescription:
              'Menstrual cycle information and wellness notifications from Asha',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode:
          AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'cycle_notification',
    );
  }

  // ============================================================
  // CYCLE MESSAGE LOGIC
  // ============================================================

  static _CycleMessage _getCycleMessage({
    required int cycleDay,
    required int cycleLength,
  }) {
    final periodLength =
        HealthProfileStore.periodLength ?? 5;

    // ----------------------------------------------------------
    // If cycle is longer than the user's expected cycle length.
    // ----------------------------------------------------------

    if (cycleDay > cycleLength) {
      return _CycleMessage(
        title: 'Asha 🌸 • Period May Be Due',
        body:
            'You are around Cycle Day $cycleDay. '
            'Your predicted period may be due around this time. '
            'Cycle timing can naturally vary from month to month.',
      );
    }

    // ----------------------------------------------------------
    // Menstrual phase
    // ----------------------------------------------------------

    if (cycleDay <= periodLength) {
      return _CycleMessage(
        title:
            'Asha 🌸 • Cycle Day $cycleDay',
        body:
            'You are in the menstrual phase. '
            'Bleeding, cramps, tiredness, bloating, or mood changes '
            'can occur during this phase. Stay hydrated, rest when '
            'needed, and listen to your body.',
      );
    }

    // ----------------------------------------------------------
    // Estimated ovulation day
    //
    // Ovulation is estimated around 14 days before the next
    // expected period.
    // ----------------------------------------------------------

    final ovulationDay =
        cycleLength - 14;

    // Protect against very short/invalid cycle lengths.
    if (ovulationDay <= periodLength) {
      return _CycleMessage(
        title:
            'Asha 🌱 • Cycle Day $cycleDay',
        body:
            'You are in the later part of your cycle. '
            'Your cycle timing may vary naturally, so use this '
            'prediction as a general guide rather than an exact measure.',
      );
    }

    // ----------------------------------------------------------
    // Fertile window
    //
    // Approximately 5 days before ovulation through ovulation.
    // ----------------------------------------------------------

    final fertileStart =
        ovulationDay - 5;

    if (cycleDay >= fertileStart &&
        cycleDay < ovulationDay) {
      return _CycleMessage(
        title:
            'Asha 💧 • Cycle Day $cycleDay',
        body:
            'You are in your predicted fertile window. '
            'Ovulation is estimated to be approaching. '
            'Fertile-window timing can vary between cycles, '
            'so this is only an estimate.',
      );
    }

    // ----------------------------------------------------------
    // Estimated ovulation day
    // ----------------------------------------------------------

    if (cycleDay == ovulationDay) {
      return _CycleMessage(
        title:
            'Asha 🌼 • Cycle Day $cycleDay',
        body:
            'Today is your predicted ovulation day based on '
            'your current cycle length. Ovulation can happen '
            'earlier or later than predicted, so this should '
            'be treated as an estimate.',
      );
    }

    // ----------------------------------------------------------
    // Day immediately after estimated ovulation
    // ----------------------------------------------------------

    if (cycleDay == ovulationDay + 1) {
      return _CycleMessage(
        title:
            'Asha 🌙 • Cycle Day $cycleDay',
        body:
            'You are moving into the luteal phase. '
            'Hormonal changes occur during this part of the cycle, '
            'and some people may notice changes in energy, mood, '
            'appetite, or other PMS-related symptoms.',
      );
    }

    // ----------------------------------------------------------
    // Luteal phase
    // ----------------------------------------------------------

    return _CycleMessage(
      title:
          'Asha 🌙 • Cycle Day $cycleDay',
      body:
          'You are in the luteal phase. '
          'As your next period approaches, some people experience '
          'bloating, breast tenderness, mood changes, tiredness, '
          'or appetite changes. Everyone experiences cycles differently.',
    );
  }

  // ============================================================
  // CHECK WHETHER TODAY'S CYCLE NOTIFICATION EXISTS
  // ============================================================

  static Future<bool>
      _wasCycleNotificationCreatedToday(
    int cycleDay,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    final saved =
        prefs.getString(
      'asha_cycle_notification_created',
    );

    if (saved == null) {
      return false;
    }

    try {
      final data =
          jsonDecode(saved);

      final savedDate =
          data['date'];

      final savedCycleDay =
          data['cycleDay'];

      final today =
          DateTime.now();

      final todayString =
          '${today.year}-'
          '${today.month.toString().padLeft(2, '0')}-'
          '${today.day.toString().padLeft(2, '0')}';

      return savedDate == todayString &&
          savedCycleDay == cycleDay;
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // SAVE CYCLE NOTIFICATION
  // ============================================================

  static Future<void> _saveNotification({
    required String title,
    required String body,
    required int cycleDay,
  }) async {
    final prefs =
        await SharedPreferences.getInstance();

    final notifications =
        prefs.getStringList(
              'asha_notification_history',
            ) ??
            [];

    final now =
        DateTime.now();

    final notification = {
      'title': title,
      'body': body,
      'cycleDay': cycleDay,
      'date': now.toIso8601String(),
      'read': false,
    };

    notifications.insert(
      0,
      jsonEncode(notification),
    );

    // Keep the most recent 30 notifications.
    if (notifications.length > 30) {
      notifications.removeRange(
        30,
        notifications.length,
      );
    }

    await prefs.setStringList(
      'asha_notification_history',
      notifications,
    );

    final todayString =
        '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';

    await prefs.setString(
      'asha_cycle_notification_created',
      jsonEncode({
        'date': todayString,
        'cycleDay': cycleDay,
      }),
    );
  }

  // ============================================================
  // GET NOTIFICATION HISTORY
  // ============================================================

  static Future<List<Map<String, dynamic>>>
      getNotificationHistory() async {
    final prefs =
        await SharedPreferences.getInstance();

    final saved =
        prefs.getStringList(
              'asha_notification_history',
            ) ??
            [];

    return saved
        .map<Map<String, dynamic>>(
          (item) {
            try {
              return Map<String, dynamic>.from(
                jsonDecode(item),
              );
            } catch (_) {
              return <String, dynamic>{};
            }
          },
        )
        .where(
          (item) => item.isNotEmpty,
        )
        .toList();
  }

  // ============================================================
  // GET UNREAD COUNT
  // ============================================================

  static Future<int> getUnreadCount() async {
    final notifications =
        await getNotificationHistory();

    return notifications.where(
      (notification) =>
          notification['read'] != true,
    ).length;
  }

  // ============================================================
  // MARK ONE NOTIFICATION AS READ
  // ============================================================

  static Future<void> markNotificationAsRead(
    int index,
  ) async {
    final notifications =
        await getNotificationHistory();

    if (index < 0 ||
        index >= notifications.length) {
      return;
    }

    notifications[index]['read'] = true;

    await _saveNotificationList(
      notifications,
    );
  }

  // ============================================================
  // MARK ALL AS READ
  // ============================================================

  static Future<void>
      markAllCycleNotificationsAsRead() async {
    final notifications =
        await getNotificationHistory();

    for (final notification
        in notifications) {
      notification['read'] = true;
    }

    await _saveNotificationList(
      notifications,
    );
  }

  // ============================================================
  // SAVE NOTIFICATION LIST
  // ============================================================

  static Future<void> _saveNotificationList(
    List<Map<String, dynamic>> notifications,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setStringList(
      'asha_notification_history',
      notifications
          .map(
            (notification) =>
                jsonEncode(notification),
          )
          .toList(),
    );
  }

  // ============================================================
  // CANCEL ONE REMINDER
  // ============================================================

  static Future<void> cancelReminder(
    int id,
  ) async {
    await _plugin.cancel(id);
  }

  // ============================================================
  // CANCEL ONE NOTIFICATION
  // ============================================================

  static Future<void> cancel(
    int id,
  ) async {
    await _plugin.cancel(id);
  }

  // ============================================================
  // CANCEL ALL NOTIFICATIONS
  // ============================================================

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}

// ============================================================
// CYCLE MESSAGE MODEL
// ============================================================

class _CycleMessage {
  final String title;
  final String body;

  _CycleMessage({
    required this.title,
    required this.body,
  });
}
