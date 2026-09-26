import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

import 'health_profile_store.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int cycleNotificationId = 1001;

  static String? get _uid =>
      FirebaseAuth.instance.currentUser?.uid;

  static String _historyKey(String uid) =>
      'asha_user_${uid}_notification_history';

  static String _createdKey(String uid) =>
      'asha_user_${uid}_cycle_notification_created';

  static Future<void> init() async {
    tzdata.initializeTimeZones();

    tz.setLocalLocation(
      tz.getLocation('Asia/Kolkata'),
    );

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const settings = InitializationSettings(
      android: androidSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse:
          _onNotificationTapped,
    );

    final android =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await android?.requestNotificationsPermission();
  }

  static Future<void> _onNotificationTapped(
    NotificationResponse response,
  ) async {
    final payload = response.payload;

    if (payload == null || payload.isEmpty) return;

    final parts = payload.split('|');

    if (parts.isEmpty ||
        parts.first != 'cycle_notification') {
      return;
    }

    if (parts.length < 2) return;

    final notificationUid = parts[1];
    final currentUid = _uid;

    // Never let a notification belonging to another
    // Firebase account change the current account.
    if (currentUid == null ||
        notificationUid != currentUid) {
      return;
    }

    await markAllNotificationsAsRead();
  }

  static Future<void> scheduleCycleNotification({
    int hour = 9,
    int minute = 0,
  }) async {
    final uid = _uid;

    if (uid == null) return;
    if (HealthProfileStore.lastPeriodDate == null) return;

    final cycleDay =
        HealthProfileStore.currentCycleDay;

    final lastPeriod =
        HealthProfileStore.lastPeriodDate!;

    final alreadyCreated =
        await _wasCycleNotificationCreatedToday(
      uid,
      cycleDay,
      lastPeriod,
    );

    if (alreadyCreated) return;

    final message =
        _getCycleMessage(cycleDay);

    await _saveNotification(
      uid: uid,
      title: message.title,
      body: message.body,
      cycleDay: cycleDay,
      lastPeriodDate: lastPeriod,
    );

    await _plugin.cancel(
      cycleNotificationId,
    );

    final now = tz.TZDateTime.now(tz.local);

    tz.TZDateTime scheduled =
        tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduled.isBefore(now)) {
      scheduled = now.add(
        const Duration(seconds: 5),
      );
    }

    await _plugin.zonedSchedule(
  cycleNotificationId,
  message.title,
  message.body,
  scheduled,
  const NotificationDetails(
    android: AndroidNotificationDetails(
      'asha_cycle',
      'Asha Cycle Notifications',
      channelDescription:
          'Daily menstrual cycle updates from Asha',
      importance: Importance.high,
      priority: Priority.high,
    ),
  ),
  androidScheduleMode:
      AndroidScheduleMode.exactAllowWhileIdle,
  uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
  payload: 'cycle_notification|$uid',
);
  }

  static _CycleMessage _getCycleMessage(
    int cycleDay,
  ) {
    final cycleLength =
        HealthProfileStore.cycleLength;

    final periodLength =
        HealthProfileStore.periodLength ?? 5;

    if (cycleDay > cycleLength) {
      return _CycleMessage(
        'Asha 🌸 • Period May Be Due',
        'Your period may be due around this time. '
            'You are around Cycle Day $cycleDay.',
      );
    }

    if (cycleDay <= periodLength) {
      return _CycleMessage(
        'Asha 🌸 • Menstrual Phase',
        'You are around Cycle Day $cycleDay. '
            'Take care of yourself and rest if needed.',
      );
    }

    final ovulationDay =
        cycleLength - 14;

    final fertileStart =
        ovulationDay - 5;

    if (cycleDay >= fertileStart &&
        cycleDay < ovulationDay) {
      return _CycleMessage(
        'Asha 🌸 • Fertile Window',
        'You are around Cycle Day $cycleDay, '
            'within your estimated fertile window.',
      );
    }

    if (cycleDay == ovulationDay) {
      return _CycleMessage(
        'Asha 🌸 • Estimated Ovulation',
        'You are around your estimated ovulation day.',
      );
    }

    if (cycleDay == ovulationDay + 1) {
      return _CycleMessage(
        'Asha 🌸 • Luteal Phase',
        'Your cycle is moving into the luteal phase.',
      );
    }

    return _CycleMessage(
      'Asha 🌸 • Cycle Update',
      'You are around Cycle Day $cycleDay.',
    );
  }

  static Future<bool> _wasCycleNotificationCreatedToday(
    String uid,
    int cycleDay,
    DateTime lastPeriodDate,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    final raw =
        prefs.getString(_createdKey(uid));

    if (raw == null) return false;

    try {
      final data =
          jsonDecode(raw) as Map<String, dynamic>;

      final date =
          DateTime.tryParse(
            data['date']?.toString() ?? '',
          );

      final savedCycleDay =
          data['cycleDay'] as int?;

      final savedLastPeriod =
          DateTime.tryParse(
            data['lastPeriodDate']?.toString() ?? '',
          );

      if (date == null ||
          savedCycleDay == null) {
        return false;
      }

      final now = DateTime.now();

      final sameDay =
          date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;

      final sameLastPeriod =
          savedLastPeriod != null &&
          savedLastPeriod.year ==
              lastPeriodDate.year &&
          savedLastPeriod.month ==
              lastPeriodDate.month &&
          savedLastPeriod.day ==
              lastPeriodDate.day;

      return sameDay &&
          savedCycleDay == cycleDay &&
          sameLastPeriod;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _saveNotification({
    required String uid,
    required String title,
    required String body,
    required int cycleDay,
    required DateTime lastPeriodDate,
  }) async {
    final prefs =
        await SharedPreferences.getInstance();

    final key = _historyKey(uid);

    final existingRaw =
        prefs.getString(key);

    List<Map<String, dynamic>> history = [];

    if (existingRaw != null) {
      try {
        final decoded =
            jsonDecode(existingRaw);

        if (decoded is List) {
          history = decoded
              .whereType<Map>()
              .map(
                (e) => Map<String, dynamic>.from(e),
              )
              .toList();
        }
      } catch (_) {}
    }

    history.insert(
      0,
      {
        'uid': uid,
        'title': title,
        'body': body,
        'cycleDay': cycleDay,
        'date': DateTime.now().toIso8601String(),
        'read': false,
      },
    );

    if (history.length > 30) {
      history = history.take(30).toList();
    }

    await prefs.setString(
      key,
      jsonEncode(history),
    );

    await prefs.setString(
      _createdKey(uid),
      jsonEncode({
        'date': DateTime.now().toIso8601String(),
        'cycleDay': cycleDay,
        'lastPeriodDate':
            lastPeriodDate.toIso8601String(),
      }),
    );
  }

  static Future<List<Map<String, dynamic>>>
      getNotificationHistory() async {
    final uid = _uid;

    if (uid == null) return [];

    final prefs =
        await SharedPreferences.getInstance();

    final raw =
        prefs.getString(_historyKey(uid));

    if (raw == null) return [];

    try {
      final decoded = jsonDecode(raw);

      if (decoded is! List) return [];

      return decoded
          .whereType<Map>()
          .map(
            (e) => Map<String, dynamic>.from(e),
          )
          .where(
            (item) =>
                item['uid']?.toString() == uid,
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<int> getUnreadCount() async {
    final history =
        await getNotificationHistory();

    return history.where(
      (item) => item['read'] != true,
    ).length;
  }

  static Future<void> markNotificationAsRead(
    int index,
  ) async {
    final uid = _uid;

    if (uid == null) return;

    final history =
        await getNotificationHistory();

    if (index < 0 ||
        index >= history.length) {
      return;
    }

    history[index]['read'] = true;

    await _saveNotificationList(
      uid,
      history,
    );
  }

  static Future<void> markAllNotificationsAsRead() async {
    final uid = _uid;

    if (uid == null) return;

    final history =
        await getNotificationHistory();

    for (final item in history) {
      item['read'] = true;
    }

    await _saveNotificationList(
      uid,
      history,
    );
  }

  // Kept for compatibility with your existing code.
  static Future<void>
      markAllCycleNotificationsAsRead() async {
    await markAllNotificationsAsRead();
  }

  static Future<void> _saveNotificationList(
    String uid,
    List<Map<String, dynamic>> history,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      _historyKey(uid),
      jsonEncode(history),
    );
  }

  static Future<void> scheduleDailyReminder({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    final uid = _uid;

    if (uid == null) return;

    final now = tz.TZDateTime.now(tz.local);

    var scheduled =
        tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduled.isBefore(now)) {
      scheduled =
          scheduled.add(const Duration(days: 1));
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
      channelDescription: 'Asha health reminders',
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
  payload: 'reminder|$uid',
);
  }

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

  static Future<void> cancelCycleNotification() async {
    await _plugin.cancel(
      cycleNotificationId,
    );
  }

  static Future<void> cancelReminder(int id) async {
    await _plugin.cancel(id);
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}

class _CycleMessage {
  final String title;
  final String body;

  _CycleMessage(this.title, this.body);
}