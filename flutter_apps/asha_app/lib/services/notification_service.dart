import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

class NotificationService {
 static final _plugin = FlutterLocalNotificationsPlugin();

 static Future<void> init() async {
 tzdata.initializeTimeZones();
 const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
 const settings = InitializationSettings(android: androidSettings);
 await _plugin.initialize(settings);
 }

 static Future<void> scheduleDailyReminder({
 required int id,
 required String title,
 required String body,
 required int hour,
 required int minute,
 }) async {
 final now = tz.TZDateTime.now(tz.local);
 var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
 if (scheduled.isBefore(now)) {
 scheduled = scheduled.add(const Duration(days: 1));
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
 channelDescription: 'Daily wellness reminders',
 importance: Importance.high,
 priority: Priority.high,
 ),
 ),
 androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
 uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
 matchDateTimeComponents: DateTimeComponents.time,
 );
 }

 static Future<void> cancel(int id) async => _plugin.cancel(id);
 static Future<void> cancelAll() async => _plugin.cancelAll();
}