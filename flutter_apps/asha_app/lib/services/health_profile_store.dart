import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HealthProfileStore {
 static int? age;

 static int cycleLength = 28;
 static int? periodLength;

 static int stress = 3;

 // NEW
 static double? bmi;
 static int exerciseFrequency = 1;
 // 0 = Low, 1 = Moderate, 2 = High

 static double sleepHours = 7;

 static String diet = 'Low Carb';

 static int pcos = 0;

 static Set<String> symptoms = {};

 static DateTime? lastPeriodDate;

 static List<DateTime> periodHistory = [];

 static DateTime? get predictedNextPeriod {
 if (lastPeriodDate == null) return null;

 return lastPeriodDate!.add(
 Duration(days: cycleLength),
 );
 }

 static DateTime? get ovulationDate {
 final next = predictedNextPeriod;

 if (next == null) return null;

 return next.subtract(
 const Duration(days: 14),
 );
 }

 static DateTimeRange? get fertileWindow {
 final ov = ovulationDate;

 if (ov == null) return null;

 return DateTimeRange(
 start: ov.subtract(
 const Duration(days: 5),
 ),
 end: ov,
 );
 }

 static String get fertileWindowLabel {
 final w = fertileWindow;

 if (w == null) {
 return 'Add your last period date';
 }

 return '${w.start.day}/${w.start.month} – '
 '${w.end.day}/${w.end.month}';
 }

 static String get nextPeriodDisplay {
 final d = predictedNextPeriod;

 if (d == null) {
 return 'Add your last period date';
 }

 return '${d.day}/${d.month}/${d.year}';
 }

 // ==================================================
 // SAVE
 // ==================================================

 static Future<void> save() async {
 final prefs =
 await SharedPreferences.getInstance();

 await prefs.setInt(
 'cycleLength',
 cycleLength,
 );

 if (periodLength != null) {
 await prefs.setInt(
 'periodLength',
 periodLength!,
 );
 }

 if (age != null) {
 await prefs.setInt(
 'age',
 age!,
 );
 }

 await prefs.setInt(
 'stress',
 stress,
 );

 // NEW
 if (bmi != null) {
 await prefs.setDouble(
 'bmi',
 bmi!,
 );
 }

 await prefs.setInt(
 'exerciseFrequency',
 exerciseFrequency,
 );

 await prefs.setDouble(
 'sleepHours',
 sleepHours,
 );

 await prefs.setString(
 'diet',
 diet,
 );

 await prefs.setInt(
 'pcos',
 pcos,
 );

 await prefs.setStringList(
 'symptoms',
 symptoms.toList(),
 );

 if (lastPeriodDate != null) {
 await prefs.setString(
 'lastPeriodDate',
 lastPeriodDate!.toIso8601String(),
 );
 }

 await prefs.setStringList(
 'periodHistory',
 periodHistory
 .map(
 (d) => d.toIso8601String(),
 )
 .toList(),
 );
 }

 // ==================================================
 // LOAD
 // ==================================================

 static Future<void> load() async {
 final prefs =
 await SharedPreferences.getInstance();

 cycleLength =
 prefs.getInt('cycleLength') ?? 28;

 periodLength =
 prefs.getInt('periodLength');

 age =
 prefs.getInt('age');

 stress =
 prefs.getInt('stress') ?? 3;

 // NEW
 bmi =
 prefs.getDouble('bmi');

 exerciseFrequency =
 prefs.getInt('exerciseFrequency') ?? 1;

 sleepHours =
 prefs.getDouble('sleepHours') ?? 7;

 diet =
 prefs.getString('diet') ?? 'Low Carb';

 pcos =
 prefs.getInt('pcos') ?? 0;

 symptoms =
 (prefs.getStringList('symptoms') ?? [])
 .toSet();

 final lastStr =
 prefs.getString('lastPeriodDate');

 if (lastStr != null) {
 lastPeriodDate =
 DateTime.tryParse(lastStr);
 }

 final historyStrs =
 prefs.getStringList('periodHistory') ?? [];

 periodHistory =
 historyStrs
 .map(
 (s) => DateTime.parse(s),
 )
 .toList();
 }

 // ==================================================
 // JSON FOR FLASK
 // ==================================================

 static Map<String, dynamic> toJson() {
 return {
 'age': age,
 'cycle_length': cycleLength,
 'period_length': periodLength,
 'bmi': bmi,
 'stress_level': stress,
 'exercise_frequency': exerciseFrequency,
 'sleep_hours': sleepHours,
 'diet': diet,
 'pcos': pcos,
 'symptoms': symptoms.toList(),
 'last_period_date':
 lastPeriodDate?.toIso8601String(),
 };
 }
}