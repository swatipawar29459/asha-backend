import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

import 'health_profile_store.dart';

// ============================================================
// NOTIFICATION SERVICE
// ============================================================

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
  // SCHEDULE CYCLE NOTIFICATION - UPDATED WITH VALIDATION
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

    if (currentUid == null || currentUid != uid) {
      return;
    }

    // ============================================================
    // CRITICAL FIX: Check if lastPeriodDate is set
    // ============================================================
    
    if (HealthProfileStore.lastPeriodDate == null) {
      print('⚠️ Cannot schedule notification: lastPeriodDate is null');
      return;
    }

    // ============================================================
    // CRITICAL FIX: Validate lastPeriodDate is not in future
    // ============================================================
    
    final lastPeriod = HealthProfileStore.lastPeriodDate!;
    final now = DateTime.now();
    
    // If lastPeriodDate is in the future, it's invalid
    if (lastPeriod.isAfter(now)) {
      print('⚠️ Cannot schedule notification: lastPeriodDate is in the future');
      print('   lastPeriodDate: $lastPeriod');
      print('   now: $now');
      return;
    }

    final cycleDay =
        HealthProfileStore.currentCycleDay;

    // Prevent duplicate notification creation for the
    // same account, cycle day and period start date.
    final alreadyCreated =
        await _wasCycleNotificationCreatedToday(
      uid,
      cycleDay,
      lastPeriod,
    );

    if (alreadyCreated) {
      print('✓ Notification already created today');
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

    final nowTz =
        tz.TZDateTime.now(tz.local);

    tz.TZDateTime scheduled =
        tz.TZDateTime(
      tz.local,
      nowTz.year,
      nowTz.month,
      nowTz.day,
      hour,
      minute,
    );

    // If today's notification time has already passed,
    // schedule it shortly from now.
    if (scheduled.isBefore(nowTz)) {
      scheduled = nowTz.add(
        const Duration(seconds: 5),
      );
    }

    // Check Firebase account one final time before scheduling.
    final finalUid = _uid;

    if (finalUid == null ||
        finalUid != uid) {
      return;
    }

    print('📢 Scheduling notification for $uid at $scheduled');
    print('   Message: ${message.title}');

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

    print('✅ Notification scheduled successfully');
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
        'You are in your menstrual phase (Cycle Day $cycleDay). '
            'Take care of yourself and stay hydrated.',
      );
    }

    final follicularEnd = periodLength + 7;
    if (cycleDay <= follicularEnd) {
      return _CycleMessage(
        'Asha 🌸 • Follicular Phase',
        'You are in your follicular phase (Cycle Day $cycleDay). '
            'Energy levels may be rising!',
      );
    }

    final ovulationStart = cycleLength - 15;
    final ovulationEnd = cycleLength - 11;
    if (cycleDay >= ovulationStart && cycleDay <= ovulationEnd) {
      return _CycleMessage(
        'Asha 🌸 • Fertile Window',
        'You are in your fertile window (Cycle Day $cycleDay). '
            'This is a great time for conception if you are trying.',
      );
    }

    if (cycleDay <= cycleLength - 1) {
      return _CycleMessage(
        'Asha 🌸 • Luteal Phase',
        'You are in your luteal phase (Cycle Day $cycleDay). '
            'Practice self-care and listen to your body.',
      );
    }

    return _CycleMessage(
      'Asha 🌸 • New Cycle Beginning',
      'Your cycle is about to start. Cycle Day: $cycleDay',
    );
  }

  // ============================================================
  // WAS CYCLE NOTIFICATION CREATED TODAY
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
  // NOTIFICATION HISTORY
  // ============================================================

  static Future<List<Map<String, dynamic>>>
      getNotificationHistory() async {
    final uid = _uid;

    if (uid == null) {
      return [];
    }

    final prefs =
        await SharedPreferences.getInstance();

    final raw =
        prefs.getString(_historyKey(uid));

    if (raw == null) {
      return [];
    }

    try {
      final decoded =
          jsonDecode(raw);

      if (decoded is! List) {
        return [];
      }

      return decoded
          .whereType<Map<String, dynamic>>()
          .where(
            (item) =>
                item['uid']?.toString() == uid,
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ============================================================
  // MARK ALL NOTIFICATIONS AS READ
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

    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      _historyKey(uid),
      jsonEncode(history),
    );
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

    // Clean up old notification storage
    final keys = prefs.getKeys();

    for (final key in keys) {
      if (key.startsWith('asha_notification_')) {
        await prefs.remove(key);
      }
    }

    await prefs.setInt(
      _migrationKey,
      _currentStorageVersion,
    );
  }

  // ============================================================
  // CANCEL ALL NOTIFICATIONS
  // ============================================================

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  static Future<void> markNotificationAsRead(int index) async {}

  static Future<void> cancelReminder(int i) async {}

  static Future<void> scheduleReminder({required int id, required String title, required String body, required int hour, required int minute}) async {}
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