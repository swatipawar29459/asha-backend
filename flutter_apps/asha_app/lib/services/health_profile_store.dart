import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HealthProfileStore {
  // ==================================================
  // USER
  // ==================================================

  static int? userId;
  static String userName = '';

  // ==================================================
  // HEALTH PROFILE
  // ==================================================

  static int? age;

  static int cycleLength = 28;
  static int? periodLength;

  static int stress = 3;

  static double? bmi;

  // 0 = Low, 1 = Moderate, 2 = High
  static int exerciseFrequency = 1;

  static double sleepHours = 7;

  static String diet = 'Low Carb';

  static int pcos = 0;

  static Set<String> symptoms = {};

  static DateTime? lastPeriodDate;

  static List<DateTime> periodHistory = [];

  // ==================================================
  // PREDICTION DATES
  // ==================================================

  static DateTime? get predictedNextPeriod {
    if (lastPeriodDate == null) {
      return null;
    }

    return DateTime(
      lastPeriodDate!.year,
      lastPeriodDate!.month,
      lastPeriodDate!.day,
    ).add(
      Duration(days: cycleLength),
    );
  }

  static DateTime? get ovulationDate {
    final next = predictedNextPeriod;

    if (next == null) {
      return null;
    }

    return next.subtract(
      const Duration(days: 14),
    );
  }

  static DateTimeRange? get fertileWindow {
    final ov = ovulationDate;

    if (ov == null) {
      return null;
    }

    return DateTimeRange(
      start: ov.subtract(
        const Duration(days: 5),
      ),
      end: ov,
    );
  }

  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  static String get fertileWindowLabel {
    final w = fertileWindow;

    if (w == null) {
      return 'Add your last period date';
    }

    return '${_formatDate(w.start)} – ${_formatDate(w.end)}';
  }

  static String get nextPeriodDisplay {
    final d = predictedNextPeriod;

    if (d == null) {
      return 'Add your last period date';
    }

    return _formatDate(d);
  }

  // ==================================================
  // CURRENT CYCLE DAY
  // ==================================================

  static int get currentCycleDay {
    if (lastPeriodDate == null) {
      return 1;
    }

    final today = DateTime.now();

    final start = DateTime(
      lastPeriodDate!.year,
      lastPeriodDate!.month,
      lastPeriodDate!.day,
    );

    final current = DateTime(
      today.year,
      today.month,
      today.day,
    );

    final difference =
        current.difference(start).inDays + 1;

    return difference < 1 ? 1 : difference;
  }

  // ==================================================
  // SAVE
  // ==================================================

  static Future<void> save() async {
    final prefs =
        await SharedPreferences.getInstance();

    if (userId != null) {
      await prefs.setInt(
        'userId',
        userId!,
      );
    }

    await prefs.setString(
      'userName',
      userName,
    );

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

    userId =
        prefs.getInt('userId');

    userName =
        prefs.getString('userName') ?? '';

    cycleLength =
        prefs.getInt('cycleLength') ?? 28;

    periodLength =
        prefs.getInt('periodLength');

    age =
        prefs.getInt('age');

    stress =
        prefs.getInt('stress') ?? 3;

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
      'user_id': userId,
      'user_name': userName,
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