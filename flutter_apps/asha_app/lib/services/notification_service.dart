
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

  // ============================================================
  // NOTIFICATION IDS
  // ============================================================

  static const int cycleNotificationId = 1001;

  // Stores which Firebase account was last active on this device.
  static const String _activeUidKey =
      'asha_active_notification_uid';

  // Used for one-time cleanup of old notification storage
  // created by previous versions of the app.
  static const String _migrationKey =
      'asha_notification_storage_version';

  static const int _currentStorageVersion = 2;

  // ============================================================
  // CURRENT FIREBASE USER
  // ============================================================

  static String? get _uid =>
      FirebaseAuth.instance.currentUser?.uid;

  // ============================================================
  // ACCOUNT-SPECIFIC KEYS
  // ============================================================

  static String _historyKey(String uid) =>
      'asha_user_${uid}_notification_history';

  static String _createdKey(String uid) =>
      'asha_user_${uid}_cycle_notification_created';

  // ============================================================
  // INITIALIZATION
  // ============================================================

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

    // Clean up storage left by older versions of Asha.
    await _runStorageMigration();
  }

  // ============================================================
  // ACCOUNT SWITCHING
  // ============================================================

  /// Call this after login/register and before loading/scheduling
  /// notifications for the new Firebase account.
  ///
  /// This makes sure the notification service knows exactly which
  /// Firebase account is currently active.
  static Future<void> switchAccount() async {
    final uid = _uid;

    final prefs =
        await SharedPreferences.getInstance();

    final previousUid =
        prefs.getString(_activeUidKey);

    // No Firebase user.
    if (uid == null) {
      await _plugin.cancelAll();

      await prefs.remove(_activeUidKey);

      return;
    }

    // Same account.
    if (previousUid == uid) {
      return;
    }

    // A different Firebase account is now active.
    //
    // Cancel Android notifications that may have been scheduled
    // while the previous account was active.
    await _plugin.cancelAll();

    // IMPORTANT:
    // We do NOT delete the previous account's permanent history.
    //
    // It remains stored under:
    // asha_user_<previousUID>_notification_history
    //
    // The new account will only read:
    // asha_user_<newUID>_notification_history

    await prefs.setString(
      _activeUidKey,
      uid,
    );
  }

  // ============================================================
  // NOTIFICATION TAP
  // ============================================================

  static Future<void> _onNotificationTapped(
    NotificationResponse response,
  ) async {
    final payload = response.payload;

    if (payload == null || payload.isEmpty) {
      return;
    }

    final parts = payload.split('|');

    if (parts.isEmpty) {
      return;
    }

    final type = parts.first;

    // ----------------------------------------------------------
    // CYCLE NOTIFICATION
    // ----------------------------------------------------------

    if (type == 'cycle_notification') {
      if (parts.length < 2) {
        return;
      }

      final notificationUid = parts[1];
      final currentUid = _uid;

      // Never allow a notification belonging to another
      // Firebase account to affect the current account.
      if (currentUid == null ||
          notificationUid != currentUid) {
        return;
      }

      await markAllNotificationsAsRead();

      return;
    }

    // ----------------------------------------------------------
    // REMINDER
    // ----------------------------------------------------------

    if (type == 'reminder') {
      if (parts.length < 2) {
        return;
      }

      final notificationUid = parts[1];
      final currentUid = _uid;

      if (currentUid == null ||
          notificationUid != currentUid) {
        return;
      }

      return;
    }
  }

  // ============================================================
  // CYCLE NOTIFICATION
  // ============================================================

  static Future<void> scheduleCycleNotification({
    int hour = 9,
    int minute = 0,
  }) async {
    final uid = _uid;

    if (uid == null) {
      return;
    }

    // Make absolutely sure the notification service is
    // attached to the current Firebase account.
    await switchAccount();

    // Check again after account switching.
    final currentUid = _uid;

    if (currentUid == null ||
        currentUid != uid) {
      return;
    }

    if (HealthProfileStore.lastPeriodDate == null) {
      return;
    }

    final cycleDay =
        HealthProfileStore.currentCycleDay;

    final lastPeriod =
        HealthProfileStore.lastPeriodDate!;

    // Prevent duplicate notification creation for the
    // same account, cycle day and period start date.
    final alreadyCreated =
        await _wasCycleNotificationCreatedToday(
      uid,
      cycleDay,
      lastPeriod,
    );

    if (alreadyCreated) {
      return;
    }

    final message =
        _getCycleMessage(cycleDay);

    // Save notification to this Firebase account's
    // private notification history.
    await _saveNotification(
      uid: uid,
      title: message.title,
      body: message.body,
      cycleDay: cycleDay,
      lastPeriodDate: lastPeriod,
    );

    // Make sure an old cycle notification is not still
    // scheduled on Android.
    await _plugin.cancel(
      cycleNotificationId,
    );

    final now =
        tz.TZDateTime.now(tz.local);

    tz.TZDateTime scheduled =
        tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // If today's notification time has already passed,
    // schedule it shortly from now.
    if (scheduled.isBefore(now)) {
      scheduled = now.add(
        const Duration(seconds: 5),
      );
    }

    // Check Firebase account one final time before scheduling.
    final finalUid = _uid;

    if (finalUid == null ||
        finalUid != uid) {
      return;
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

  // ============================================================
  // CYCLE MESSAGE
  // ============================================================

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

  // ============================================================
  // CHECK IF TODAY'S CYCLE NOTIFICATION ALREADY EXISTS
  // ============================================================

  static Future<bool> _wasCycleNotificationCreatedToday(
    String uid,
    int cycleDay,
    DateTime lastPeriodDate,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    final raw =
        prefs.getString(
      _createdKey(uid),
    );

    if (raw == null) {
      return false;
    }

    try {
      final decoded =
          jsonDecode(raw);

      if (decoded is! Map) {
        return false;
      }

      final data =
          Map<String, dynamic>.from(decoded);

      final date =
          DateTime.tryParse(
        data['date']?.toString() ?? '',
      );

      final savedCycleDay =
          data['cycleDay'] is num
              ? (data['cycleDay'] as num).toInt()
              : null;

      final savedLastPeriod =
          DateTime.tryParse(
        data['lastPeriodDate']?.toString() ?? '',
      );

      if (date == null ||
          savedCycleDay == null) {
        return false;
      }

      final now =
          DateTime.now();

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

  // ============================================================
  // SAVE NOTIFICATION
  // ============================================================

  static Future<void> _saveNotification({
    required String uid,
    required String title,
    required String body,
    required int cycleDay,
    required DateTime lastPeriodDate,
  }) async {
    final prefs =
        await SharedPreferences.getInstance();

    // Verify the account is still active.
    final currentUid = _uid;

    if (currentUid == null ||
        currentUid != uid) {
      return;
    }

    final key =
        _historyKey(uid);

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
              .where(
                (item) =>
                    item['uid']?.toString() == uid,
              )
              .toList();
        }
      } catch (_) {
        history = [];
      }
    }

    history.insert(
      0,
      {
        'uid': uid,
        'title': title,
        'body': body,
        'cycleDay': cycleDay,
        'date':
            DateTime.now().toIso8601String(),
        'read': false,
      },
    );

    if (history.length > 30) {
      history =
          history.take(30).toList();
    }

    await prefs.setString(
      key,
      jsonEncode(history),
    );

    await prefs.setString(
      _createdKey(uid),
      jsonEncode(
        {
          'date':
              DateTime.now().toIso8601String(),
          'cycleDay': cycleDay,
          'lastPeriodDate':
              lastPeriodDate.toIso8601String(),
        },
      ),
    );
  }

  // ============================================================
  // GET NOTIFICATION HISTORY
  // ============================================================

  static Future<List<Map<String, dynamic>>>
      getNotificationHistory() async {
    final uid = _uid;

    if (uid == null) {
      return [];
    }

    // Ensure this device is currently attached to this account.
    await switchAccount();

    final currentUid = _uid;

    if (currentUid == null ||
        currentUid != uid) {
      return [];
    }

    final prefs =
        await SharedPreferences.getInstance();

    final raw =
        prefs.getString(
      _historyKey(uid),
    );

    if (raw == null) {
      return [];
    }

    try {
      final decoded =
          jsonDecode(raw);

      if (decoded is! List) {
        return [];
      }

      final validHistory = decoded
          .whereType<Map>()
          .map(
            (e) => Map<String, dynamic>.from(e),
          )
          .where(
            (item) =>
                item['uid']?.toString() == uid,
          )
          .toList();

      // If invalid/old-account entries were found,
      // immediately save the cleaned list.
      if (validHistory.length !=
          decoded.length) {
        await prefs.setString(
          _historyKey(uid),
          jsonEncode(validHistory),
        );
      }

      return validHistory;
    } catch (_) {
      return [];
    }
  }

  // ============================================================
  // UNREAD COUNT
  // ============================================================

  static Future<int> getUnreadCount() async {
    final history =
        await getNotificationHistory();

    return history
        .where(
          (item) =>
              item['read'] != true,
        )
        .length;
  }

  // ============================================================
  // MARK ONE AS READ
  // ============================================================

  static Future<void> markNotificationAsRead(
    int index,
  ) async {
    final uid = _uid;

    if (uid == null) {
      return;
    }

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

  // ============================================================
  // MARK ALL AS READ
  // ============================================================

  static Future<void>
      markAllNotificationsAsRead() async {
    final uid = _uid;

    if (uid == null) {
      return;
    }

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

  // Kept for compatibility with existing code.
  static Future<void>
      markAllCycleNotificationsAsRead() async {
    await markAllNotificationsAsRead();
  }

  // ============================================================
  // SAVE NOTIFICATION LIST
  // ============================================================

  static Future<void> _saveNotificationList(
    String uid,
    List<Map<String, dynamic>> history,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    // Only save records belonging to this UID.
    final cleanHistory = history
        .where(
          (item) =>
              item['uid']?.toString() == uid,
        )
        .toList();

    await prefs.setString(
      _historyKey(uid),
      jsonEncode(cleanHistory),
    );
  }

  // ============================================================
  // DAILY REMINDER
  // ============================================================

  static Future<void> scheduleDailyReminder({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    final uid = _uid;

    if (uid == null) {
      return;
    }

    await switchAccount();

    final currentUid = _uid;

    if (currentUid == null ||
        currentUid != uid) {
      return;
    }

    final now =
        tz.TZDateTime.now(tz.local);

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
          scheduled.add(
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
              'Asha health reminders',
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

  // ============================================================
  // COMPATIBILITY METHOD
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
  // CANCEL CYCLE NOTIFICATION
  // ============================================================

  static Future<void>
      cancelCycleNotification() async {
    await _plugin.cancel(
      cycleNotificationId,
    );
  }

  // ============================================================
  // CANCEL REMINDER
  // ============================================================

  static Future<void> cancelReminder(
    int id,
  ) async {
    await _plugin.cancel(id);
  }

  // ============================================================
  // CANCEL ALL SYSTEM NOTIFICATIONS
  // ============================================================

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  // ============================================================
  // STORAGE MIGRATION
  // ============================================================

  static Future<void> _runStorageMigration() async {
    final prefs =
        await SharedPreferences.getInstance();

    final version =
        prefs.getInt(_migrationKey) ?? 0;

    if (version >= _currentStorageVersion) {
      return;
    }

    // ----------------------------------------------------------
    // OLD GENERIC KEYS
    // ----------------------------------------------------------
    //
    // Older versions of Asha may have used generic notification
    // keys that were not tied to Firebase UID.
    //
    // These are removed once so that old-account notifications
    // cannot leak into the new UID-based system.
    //

    const oldGenericKeys = [
      'notification_history',
      'notifications',
      'cycle_notification_created',
      'asha_notification_history',
      'asha_notifications',
      'asha_cycle_notification_created',
    ];

    for (final key in oldGenericKeys) {
      await prefs.remove(key);
    }

    await prefs.setInt(
      _migrationKey,
      _currentStorageVersion,
    );
  }
}

// ============================================================
// CYCLE MESSAGE MODEL
// ============================================================

class _CycleMessage {
  final String title;
  final String body;

  _CycleMessage(
    this.title,
    this.body,
  );
}
