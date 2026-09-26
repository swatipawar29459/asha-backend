import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HealthProfileStore {
  static int? userId;
  static String userName = '';
  static int? age;

  static int cycleLength = 28;
  static int? periodLength;

  static int stress = 3;
  static double? bmi;
  static int exerciseFrequency = 1;
  static double sleepHours = 7;
  static String diet = 'Low Carb';
  static int pcos = 0;

  static Set<String> symptoms = {};
  static DateTime? lastPeriodDate;
  static List<DateTime> periodHistory = [];

  static const String _pendingPrefix = 'asha_pending_profile_';

  static String _userPrefix(String uid) => 'asha_user_${uid}_';

  static String _key(String prefix, String name) => '$prefix$name';

  static String? get _firebaseUid =>
      FirebaseAuth.instance.currentUser?.uid;

  static DateTime get _today {
    final now = DateTime.now();

    return DateTime(
      now.year,
      now.month,
      now.day,
    );
  }

  // ============================================================
  // CYCLE CALCULATIONS
  // ============================================================

  static int get currentCycleDay {
    if (lastPeriodDate == null) {
      return 1;
    }

    final last = DateTime(
      lastPeriodDate!.year,
      lastPeriodDate!.month,
      lastPeriodDate!.day,
    );

    final difference = _today.difference(last).inDays;

    if (difference < 0) {
      return 1;
    }

    return difference + 1;
  }

  static bool get isPeriodDueToday {
    final next = predictedNextPeriod;

    if (next == null) return false;

    return _sameDate(_today, next);
  }

  static bool get isPeriodOverdue {
    final next = predictedNextPeriod;

    if (next == null) return false;

    return _today.isAfter(next);
  }

  static int get daysUntilNextPeriod {
    final next = predictedNextPeriod;

    if (next == null) return 0;

    return next.difference(_today).inDays;
  }

  static DateTime? get predictedNextPeriod {
    if (lastPeriodDate == null) {
      return null;
    }

    final last = DateTime(
      lastPeriodDate!.year,
      lastPeriodDate!.month,
      lastPeriodDate!.day,
    );

    return last.add(
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
    final ovulation = ovulationDate;

    if (ovulation == null) {
      return null;
    }

    return DateTimeRange(
      start: ovulation.subtract(
        const Duration(days: 5),
      ),
      end: ovulation,
    );
  }

  static String get fertileWindowLabel {
    final range = fertileWindow;

    if (range == null) {
      return 'Not available';
    }

    return '${range.start.day}/${range.start.month} - '
        '${range.end.day}/${range.end.month}';
  }

  static String get nextPeriodDisplay {
    final next = predictedNextPeriod;

    if (next == null) {
      return 'Not available';
    }

    if (isPeriodDueToday) {
      return 'Today';
    }

    if (isPeriodOverdue) {
      final overdue = _today.difference(next).inDays;

      return 'Overdue by $overdue '
          '${overdue == 1 ? 'day' : 'days'}';
    }

    final days = daysUntilNextPeriod;

    if (days == 1) {
      return 'Tomorrow';
    }

    if (days > 1) {
      return 'In $days days';
    }

    return '${next.day}/${next.month}/${next.year}';
  }

  static bool _sameDate(
    DateTime a,
    DateTime b,
  ) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }

  // ============================================================
  // PROFILE VALIDATION
  // ============================================================

  static bool get hasRequiredPredictionData {
    return age != null &&
        age! > 0 &&
        periodLength != null &&
        periodLength! > 0 &&
        cycleLength > 0 &&
        lastPeriodDate != null;
  }

  // ============================================================
  // RESET
  // ============================================================

  static void resetInMemory() {
    userId = null;
    userName = '';
    age = null;

    cycleLength = 28;
    periodLength = null;

    stress = 3;
    bmi = null;
    exerciseFrequency = 1;
    sleepHours = 7;
    diet = 'Low Carb';
    pcos = 0;

    symptoms = {};
    lastPeriodDate = null;
    periodHistory = [];
  }

  // ============================================================
  // LOAD
  // ============================================================

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    resetInMemory();

    final uid = _firebaseUid;

    if (uid == null) {
      await _loadFromPrefix(
        prefs,
        _pendingPrefix,
      );

      return;
    }

    final prefix = _userPrefix(uid);

    final exists =
        prefs.getBool(
              _key(
                prefix,
                'profile_exists',
              ),
            ) ??
            false;

    // ----------------------------------------------------------
    // If there is no Firebase profile, check for pending
    // onboarding data and automatically adopt it.
    // ----------------------------------------------------------

    if (!exists) {
      final hasPending =
          prefs.getBool(
                _key(
                  _pendingPrefix,
                  'profile_exists',
                ),
              ) ??
              false;

      if (hasPending) {
        await _loadFromPrefix(
          prefs,
          _pendingPrefix,
        );

        await _saveToPrefix(
          prefs,
          prefix,
        );

        await clearPendingProfile();
      } else {
        userName =
            FirebaseAuth.instance.currentUser?.displayName ?? '';

        return;
      }
    } else {
      await _loadFromPrefix(
        prefs,
        prefix,
      );
    }

    if (userName.isEmpty) {
      userName =
          FirebaseAuth.instance.currentUser?.displayName ?? '';
    }
  }

  static Future<void> _loadFromPrefix(
    SharedPreferences prefs,
    String prefix,
  ) async {
    userId = prefs.getInt(
      _key(prefix, 'userId'),
    );

    userName =
        prefs.getString(
              _key(prefix, 'userName'),
            ) ??
            '';

    age = prefs.getInt(
      _key(prefix, 'age'),
    );

    cycleLength =
        prefs.getInt(
              _key(
                prefix,
                'cycleLength',
              ),
            ) ??
            28;

    periodLength = prefs.getInt(
      _key(
        prefix,
        'periodLength',
      ),
    );

    stress =
        prefs.getInt(
              _key(
                prefix,
                'stress',
              ),
            ) ??
            3;

    bmi = prefs.getDouble(
      _key(prefix, 'bmi'),
    );

    exerciseFrequency =
        prefs.getInt(
              _key(
                prefix,
                'exerciseFrequency',
              ),
            ) ??
            1;

    sleepHours =
        prefs.getDouble(
              _key(
                prefix,
                'sleepHours',
              ),
            ) ??
            7;

    diet =
        prefs.getString(
              _key(
                prefix,
                'diet',
              ),
            ) ??
            'Low Carb';

    pcos =
        prefs.getInt(
              _key(
                prefix,
                'pcos',
              ),
            ) ??
            0;

    symptoms =
        (prefs.getStringList(
                  _key(
                    prefix,
                    'symptoms',
                  ),
                ) ??
                [])
            .toSet();

    final lastPeriod =
        prefs.getString(
      _key(
        prefix,
        'lastPeriodDate',
      ),
    );

    if (lastPeriod != null &&
        lastPeriod.isNotEmpty) {
      lastPeriodDate = DateTime.tryParse(
        lastPeriod,
      );
    }

    final history =
        prefs.getStringList(
              _key(
                prefix,
                'periodHistory',
              ),
            ) ??
            [];

    periodHistory = history
        .map(
          (e) => DateTime.tryParse(e),
        )
        .whereType<DateTime>()
        .toList();
  }

  // ============================================================
  // SAVE
  // ============================================================

  static Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();

    final uid = _firebaseUid;

    final prefix =
        uid == null ? _pendingPrefix : _userPrefix(uid);

    await _saveToPrefix(
      prefs,
      prefix,
    );
  }

  static Future<void> _saveToPrefix(
    SharedPreferences prefs,
    String prefix,
  ) async {
    await prefs.setBool(
      _key(
        prefix,
        'profile_exists',
      ),
      true,
    );

    await prefs.setInt(
      _key(prefix, 'userId'),
      userId ?? 0,
    );

    await prefs.setString(
      _key(prefix, 'userName'),
      userName,
    );

    if (age == null) {
      await prefs.remove(
        _key(prefix, 'age'),
      );
    } else {
      await prefs.setInt(
        _key(prefix, 'age'),
        age!,
      );
    }

    await prefs.setInt(
      _key(
        prefix,
        'cycleLength',
      ),
      cycleLength,
    );

    if (periodLength == null) {
      await prefs.remove(
        _key(
          prefix,
          'periodLength',
        ),
      );
    } else {
      await prefs.setInt(
        _key(
          prefix,
          'periodLength',
        ),
        periodLength!,
      );
    }

    await prefs.setInt(
      _key(prefix, 'stress'),
      stress,
    );

    if (bmi == null) {
      await prefs.remove(
        _key(prefix, 'bmi'),
      );
    } else {
      await prefs.setDouble(
        _key(prefix, 'bmi'),
        bmi!,
      );
    }

    await prefs.setInt(
      _key(
        prefix,
        'exerciseFrequency',
      ),
      exerciseFrequency,
    );

    await prefs.setDouble(
      _key(
        prefix,
        'sleepHours',
      ),
      sleepHours,
    );

    await prefs.setString(
      _key(prefix, 'diet'),
      diet,
    );

    await prefs.setInt(
      _key(prefix, 'pcos'),
      pcos,
    );

    await prefs.setStringList(
      _key(prefix, 'symptoms'),
      symptoms.toList(),
    );

    if (lastPeriodDate == null) {
      await prefs.remove(
        _key(
          prefix,
          'lastPeriodDate',
        ),
      );
    } else {
      await prefs.setString(
        _key(
          prefix,
          'lastPeriodDate',
        ),
        lastPeriodDate!.toIso8601String(),
      );
    }

    await prefs.setStringList(
      _key(
        prefix,
        'periodHistory',
      ),
      periodHistory
          .map(
            (e) => e.toIso8601String(),
          )
          .toList(),
    );
  }

  // ============================================================
  // NEW PERIOD
  // ============================================================

  static Future<void> recordNewPeriod(
    DateTime date,
  ) async {
    final cleanDate = DateTime(
      date.year,
      date.month,
      date.day,
    );

    if (lastPeriodDate != null) {
      final alreadyExists =
          periodHistory.any(
        (d) => _sameDate(
          d,
          cleanDate,
        ),
      );

      if (!alreadyExists) {
        periodHistory.add(
          lastPeriodDate!,
        );
      }
    }

    lastPeriodDate = cleanDate;

    await save();
  }

  // ============================================================
  // PENDING PROFILE
  // ============================================================

  static Future<bool>
      adoptPendingProfileForCurrentUser() async {
    final uid = _firebaseUid;

    if (uid == null) {
      return false;
    }

    final prefs =
        await SharedPreferences.getInstance();

    final hasPending =
        prefs.getBool(
              _key(
                _pendingPrefix,
                'profile_exists',
              ),
            ) ??
            false;

    if (!hasPending) {
      return false;
    }

    await _loadFromPrefix(
      prefs,
      _pendingPrefix,
    );

    await _saveToPrefix(
      prefs,
      _userPrefix(uid),
    );

    await clearPendingProfile();

    return true;
  }

  static Future<void> clearPendingProfile() async {
    final prefs =
        await SharedPreferences.getInstance();

    const fields = [
      'profile_exists',
      'userId',
      'userName',
      'age',
      'cycleLength',
      'periodLength',
      'stress',
      'bmi',
      'exerciseFrequency',
      'sleepHours',
      'diet',
      'pcos',
      'symptoms',
      'lastPeriodDate',
      'periodHistory',
    ];

    for (final field in fields) {
      await prefs.remove(
        _key(
          _pendingPrefix,
          field,
        ),
      );
    }
  }

  // ============================================================
  // JSON
  // ============================================================

  static Map<String, dynamic> toJson() {
    return {
      'firebase_uid': _firebaseUid,
      'user_id': userId,
      'user_name': userName,
      'age': age,
      'cycle_length': cycleLength,
      'period_length': periodLength,
      'stress': stress,
      'stress_level': stress,
      'bmi': bmi,
      'exercise_frequency': exerciseFrequency,
      'sleep_hours': sleepHours,
      'diet': diet,
      'pcos': pcos,
      'symptoms': symptoms.toList(),
      'last_period_date':
          lastPeriodDate?.toIso8601String(),
      'period_history':
          periodHistory
              .map(
                (e) => e.toIso8601String(),
              )
              .toList(),
    };
  }
}