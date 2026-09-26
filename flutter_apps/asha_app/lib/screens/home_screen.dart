import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/prediction.dart';
import '../services/api_service.dart';
import '../services/health_profile_store.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
  });

  @override
  State<HomeScreen> createState() =>
      _HomeScreenState();
}

class _HomeScreenState
    extends State<HomeScreen> {
  Prediction? prediction;

  bool isLoading = true;

  String userName = '';

  // ============================================================
  // LOAD HOME DATA
  // ============================================================

  Future<void> _load() async {
    try {
      final user =
          FirebaseAuth.instance.currentUser;

      if (user == null) {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }

        return;
      }

      // ----------------------------------------------------------
      // ALWAYS LOAD THE LOCAL FIREBASE-UID PROFILE FIRST
      // ----------------------------------------------------------

      await HealthProfileStore.load();

      userName =
          HealthProfileStore.userName.isNotEmpty
              ? HealthProfileStore.userName
              : (user.displayName ?? 'there');

      // ----------------------------------------------------------
      // TRY ML BACKEND PREDICTION
      // ----------------------------------------------------------

      Prediction? result;

      try {
        result =
            await ApiService.fetchPrediction(
          userId: user.uid,
        );
      } catch (e) {
        // Backend prediction can fail if the profile is incomplete.
        // Home should still work using the saved cycle data.
        debugPrint(
          'ML prediction unavailable: $e',
        );
      }

      // ----------------------------------------------------------
      // FALLBACK TO SAVED PROFILE DATA
      // ----------------------------------------------------------

      result ??=
          _buildLocalPrediction();

      if (!mounted) return;

      setState(() {
        prediction = result;
        isLoading = false;
      });
    } catch (e) {
      debugPrint(
        'Home load error: $e',
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  // ============================================================
  // LOCAL PREDICTION FALLBACK
  // ============================================================

  Prediction? _buildLocalPrediction() {
    final lastPeriod =
        HealthProfileStore.lastPeriodDate;

    if (lastPeriod == null) {
      return null;
    }

    final cycleLength =
        HealthProfileStore.cycleLength > 0
            ? HealthProfileStore.cycleLength
            : 28;

    final currentDay =
        HealthProfileStore.currentCycleDay;

    final progress =
        (currentDay / cycleLength)
            .clamp(0.0, 1.0);

    final nextPeriod =
        HealthProfileStore.predictedNextPeriod;

    if (nextPeriod == null) {
      return null;
    }

    final nextLabel =
        _formatDate(nextPeriod);

    return Prediction(
      currentDay: currentDay,

      phaseLabel:
          _localPhaseLabel(
        currentDay,
        cycleLength,
      ),

      nextPeriodLabel:
          nextLabel,

      fertileWindowLabel:
          HealthProfileStore
              .fertileWindowLabel,

      cycleProgress:
          progress,

      factorWeights:
          const {},

      pcosRisk:
          HealthProfileStore.pcos == 1
              ? 'Reported PCOS'
              : 'No PCOS reported',

      avgCycleLength:
          cycleLength,

      avgPeriodLength:
          HealthProfileStore.periodLength ??
              5,

      cycleLengthHistory:
          const [],

      predictedCycleLength:
          cycleLength,
    );
  }

  // ============================================================
  // DATE FORMAT
  // ============================================================

  String _formatDate(
    DateTime date,
  ) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // ============================================================
  // LOCAL PHASE
  // ============================================================

  String _localPhaseLabel(
    int day,
    int cycleLength,
  ) {
    if (day <= 5) {
      return 'Menstrual phase';
    }

    final ovulationDay =
        cycleLength - 14;

    if (day < ovulationDay - 5) {
      return 'Follicular phase';
    }

    if (day <= ovulationDay) {
      return 'Fertile phase';
    }

    return 'Luteal phase';
  }

  // ============================================================
  // PERIOD HELPERS
  // ============================================================

  bool _isPeriodDue(
    Prediction p,
  ) {
    final label =
        p.nextPeriodLabel.toLowerCase();

    return label.contains(
          'period due',
        ) ||
        label.contains(
          'period may be due',
        );
  }

  bool _isDueToday(
    Prediction p,
  ) {
    final next =
        HealthProfileStore.predictedNextPeriod;

    if (next == null) {
      return p.nextPeriodLabel
          .toLowerCase()
          .contains(
            'due today',
          );
    }

    final now =
        DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    return next.year == today.year &&
        next.month == today.month &&
        next.day == today.day;
  }

  String _cycleCenterText(
    Prediction p,
  ) {
    if (_isDueToday(p)) {
      return 'Period\ndue today';
    }

    if (_isPeriodDue(p)) {
      return 'Period may\nbe due';
    }

    return 'Day\n${p.currentDay}';
  }

  String _cycleSubText(
    Prediction p,
  ) {
    if (_isPeriodDue(p)) {
      return 'Your period may be starting';
    }

    return p.phaseLabel;
  }

  String _formatNextPeriod(
    Prediction p,
  ) {
    // ----------------------------------------------------------
    // IMPORTANT:
    // Prefer the saved HealthProfileStore cycle calculation.
    // This prevents stale backend labels such as "In 9 days".
    // ----------------------------------------------------------

    final next =
        HealthProfileStore.predictedNextPeriod;

    if (next != null) {
      return _formatDate(next);
    }

    if (p.nextPeriodLabel.isEmpty) {
      return 'Not available';
    }

    return p.nextPeriodLabel;
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> _refresh() async {
    setState(() {
      isLoading = true;
    });

    await _load();
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final p = prediction;

    return Scaffold(
      backgroundColor:
          const Color(0xFFFFF8F3),

      body: SafeArea(
        child: isLoading
            ? const Center(
                child:
                    CircularProgressIndicator(
                  color:
                      Color(0xFFD8754E),
                ),
              )
            : RefreshIndicator(
                color:
                    const Color(0xFFD8754E),

                backgroundColor:
                    Colors.white,

                onRefresh:
                    _refresh,

                child:
                    SingleChildScrollView(
                  physics:
                      const AlwaysScrollableScrollPhysics(),

                  padding:
                      const EdgeInsets.fromLTRB(
                    20,
                    18,
                    20,
                    30,
                  ),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [

                      // ==================================================
                      // TOP BAR
                      // ==================================================

                      Row(
                        children: [

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,

                              children: [

                                Text(
                                  'Hello, ${userName.isEmpty ? 'there' : userName}',

                                  style:
                                      const TextStyle(
                                    fontSize: 25,
                                    fontWeight:
                                        FontWeight.w700,
                                    color:
                                        Color(0xFF4A332B),
                                  ),
                                ),

                                const SizedBox(
                                  height: 5,
                                ),

                                const Text(
                                  'Take care of yourself today 🌷',

                                  style:
                                      TextStyle(
                                    fontSize: 14,
                                    color:
                                        Color(0xFF8D7064),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/notifications',
                              );
                            },

                            child: Container(
                              width: 46,
                              height: 46,

                              decoration:
                                  BoxDecoration(
                                color:
                                    Colors.white,
                                shape:
                                    BoxShape.circle,

                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black
                                        .withOpacity(
                                      0.06,
                                    ),
                                    blurRadius:
                                        10,
                                    offset:
                                        const Offset(
                                      0,
                                      3,
                                    ),
                                  ),
                                ],
                              ),

                              child: const Icon(
                                Icons
                                    .notifications_none_rounded,
                                color:
                                    Color(0xFF5D4037),
                                size: 25,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 24,
                      ),

                      // ==================================================
                      // CYCLE CARD
                      // ==================================================

                      Container(
                        width:
                            double.infinity,

                        padding:
                            const EdgeInsets.all(
                          22,
                        ),

                        decoration:
                            BoxDecoration(
                          color:
                              const Color(
                            0xFFFFE9DC,
                          ),
                          borderRadius:
                              BorderRadius.circular(
                            28,
                          ),
                        ),

                        child: Column(
                          children: [

                            const Text(
                              'Your cycle',

                              style:
                                  TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    FontWeight.w600,
                                color:
                                    Color(0xFF795548),
                              ),
                            ),

                            const SizedBox(
                              height: 18,
                            ),

                            SizedBox(
                              width: 205,
                              height: 205,

                              child: Stack(
                                alignment:
                                    Alignment.center,

                                children: [

                                  SizedBox(
                                    width: 190,
                                    height: 190,

                                    child:
                                        CircularProgressIndicator(
                                      value: p == null
                                          ? 0
                                          : p.cycleProgress
                                              .clamp(
                                              0.0,
                                              1.0,
                                            ),

                                      strokeWidth:
                                          13,

                                      backgroundColor:
                                          Colors.white
                                              .withOpacity(
                                        0.75,
                                      ),

                                      valueColor:
                                          const AlwaysStoppedAnimation<
                                              Color>(
                                        Color(
                                          0xFFD8754E,
                                        ),
                                      ),
                                    ),
                                  ),

                                  if (p != null)
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment
                                              .center,

                                      children: [

                                        Text(
                                          _cycleCenterText(
                                            p,
                                          ),

                                          textAlign:
                                              TextAlign
                                                  .center,

                                          style:
                                              TextStyle(
                                            fontSize:
                                                _isPeriodDue(
                                              p,
                                            )
                                                    ? 20
                                                    : 31,

                                            height:
                                                1.15,

                                            fontWeight:
                                                FontWeight
                                                    .w700,

                                            color:
                                                const Color(
                                              0xFF4A332B,
                                            ),
                                          ),
                                        ),

                                        const SizedBox(
                                          height: 8,
                                        ),

                                        Padding(
                                          padding:
                                              const EdgeInsets
                                                  .symmetric(
                                            horizontal:
                                                18,
                                          ),

                                          child:
                                              Text(
                                            _cycleSubText(
                                              p,
                                            ),

                                            textAlign:
                                                TextAlign
                                                    .center,

                                            style:
                                                const TextStyle(
                                              fontSize:
                                                  13,
                                              color:
                                                  Color(
                                                0xFF8D7064,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),

                            const SizedBox(
                              height: 20,
                            ),

                            if (p != null &&
                                p.predictedCycleLength !=
                                    0)
                              Container(
                                padding:
                                    const EdgeInsets
                                        .symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),

                                decoration:
                                    BoxDecoration(
                                  color: Colors.white
                                      .withOpacity(
                                    0.7,
                                  ),

                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    20,
                                  ),
                                ),

                                child: Row(
                                  mainAxisSize:
                                      MainAxisSize.min,

                                  children: [

                                    const Icon(
                                      Icons
                                          .auto_awesome,
                                      size: 16,
                                      color:
                                          Color(
                                        0xFFD8754E,
                                      ),
                                    ),

                                    const SizedBox(
                                      width: 7,
                                    ),

                                    Text(
                                      'ML prediction: '
                                      '${p.predictedCycleLength} days',

                                      style:
                                          const TextStyle(
                                        fontSize: 12,
                                        fontWeight:
                                            FontWeight
                                                .w600,
                                        color:
                                            Color(
                                          0xFF795548,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height: 18,
                      ),

                      // ==================================================
                      // NEXT PERIOD + FERTILE WINDOW
                      // ==================================================

                      Row(
                        children: [

                          Expanded(
                            child: _InfoCard(
                              icon: Icons
                                  .calendar_month_rounded,

                              title:
                                  'Next period',

                              value: p == null
                                  ? HealthProfileStore
                                      .predictedNextPeriod !=
                                      null
                                      ? _formatDate(
                                          HealthProfileStore
                                              .predictedNextPeriod!,
                                        )
                                      : 'Not available'
                                  : _formatNextPeriod(
                                      p,
                                    ),
                            ),
                          ),

                          const SizedBox(
                            width: 12,
                          ),

                          Expanded(
                            child: _InfoCard(
                              icon: Icons
                                  .favorite_border_rounded,

                              title:
                                  'Fertile window',

                              value: p == null
                                  ? HealthProfileStore
                                      .fertileWindowLabel
                                  : p
                                      .fertileWindowLabel,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 18,
                      ),

                      // ==================================================
                      // MODEL INFORMATION CARD
                      // ==================================================

                      if (p != null &&
                          p.factorWeights.isNotEmpty)
                        _ModelFactorsCard(
                          factors:
                              p.factorWeights,
                        ),

                      if (p != null &&
                          p.factorWeights.isNotEmpty)
                        const SizedBox(
                          height: 18,
                        ),

                      // ==================================================
                      // PCOS WELLNESS INFORMATION
                      // ==================================================

                      if (p != null &&
                          p.pcosRisk ==
                              'Reported PCOS')
                        Container(
                          width:
                              double.infinity,

                          padding:
                              const EdgeInsets.all(
                            18,
                          ),

                          decoration:
                              BoxDecoration(
                            color:
                                Colors.white,

                            borderRadius:
                                BorderRadius.circular(
                              22,
                            ),

                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withOpacity(
                                  0.04,
                                ),
                                blurRadius:
                                    12,
                                offset:
                                    const Offset(
                                  0,
                                  4,
                                ),
                              ),
                            ],
                          ),

                          child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,

                            children: [

                              Container(
                                width: 44,
                                height: 44,

                                decoration:
                                    BoxDecoration(
                                  color:
                                      const Color(
                                    0xFFFFE9DC,
                                  ),

                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    14,
                                  ),
                                ),

                                child: const Icon(
                                  Icons
                                      .favorite_outline_rounded,
                                  color:
                                      Color(
                                    0xFFD8754E,
                                  ),
                                ),
                              ),

                              const SizedBox(
                                width: 13,
                              ),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,

                                  children: [

                                    const Text(
                                      'Wellness information',

                                      style:
                                          TextStyle(
                                        fontSize: 16,
                                        fontWeight:
                                            FontWeight.w700,
                                        color:
                                            Color(
                                          0xFF4A332B,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(
                                      height: 5,
                                    ),

                                    const Text(
                                      'You have reported PCOS in your health profile. This information is considered by the cycle prediction model. It is not a PCOS diagnosis or risk prediction.',

                                      style:
                                          TextStyle(
                                        fontSize: 13,
                                        height: 1.4,
                                        color:
                                            Color(
                                          0xFF8D7064,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(
                        height: 18,
                      ),

                      // ==================================================
                      // QUICK ACTIONS
                      // ==================================================

                      const Text(
                        'Quick actions',

                        style:
                            TextStyle(
                          fontSize: 19,
                          fontWeight:
                              FontWeight.w700,
                          color:
                              Color(0xFF4A332B),
                        ),
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      Row(
                        children: [

                          Expanded(
                            child: _ActionCard(
                              icon: Icons
                                  .water_drop_outlined,

                              title:
                                  'Log discharge',

                              onTap: () {
                                Navigator
                                    .pushNamed(
                                  context,
                                  '/discharge',
                                );
                              },
                            ),
                          ),

                          const SizedBox(
                            width: 12,
                          ),

                          Expanded(
                            child: _ActionCard(
                              icon: Icons
                                  .medical_services_outlined,

                              title:
                                  'Find doctor',

                              onTap: () {
                                Navigator
                                    .pushNamed(
                                  context,
                                  '/find-doctor',
                                );
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      Row(
                        children: [

                          Expanded(
                            child: _ActionCard(
                              icon:
                                  Icons.edit_note_rounded,

                              title:
                                  'Quick log',

                              onTap: () {
                                Navigator
                                    .pushNamed(
                                  context,
                                  '/quick-log',
                                );
                              },
                            ),
                          ),

                          const SizedBox(
                            width: 12,
                          ),

                          Expanded(
                            child: _ActionCard(
                              icon: Icons
                                  .menu_book_outlined,

                              title:
                                  'Health library',

                              onTap: () {
                                Navigator
                                    .pushNamed(
                                  context,
                                  '/article',
                                );
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 25,
                      ),

                      // ==================================================
                      // BOTTOM MESSAGE
                      // ==================================================

                      Container(
                        width:
                            double.infinity,

                        padding:
                            const EdgeInsets.all(
                          18,
                        ),

                        decoration:
                            BoxDecoration(
                          color:
                              const Color(
                            0xFFFFF1E8,
                          ),

                          borderRadius:
                              BorderRadius.circular(
                            22,
                          ),
                        ),

                        child: Row(
                          children: [

                            const Text(
                              '🌸',
                              style:
                                  TextStyle(
                                fontSize: 28,
                              ),
                            ),

                            const SizedBox(
                              width: 12,
                            ),

                            Expanded(
                              child: Text(
                                _isPeriodDue(
                                  p ??
                                      _emptyPrediction(),
                                )
                                    ? 'Listen to your body and take care of yourself today.'
                                    : 'Your body is unique. Keep tracking to understand your cycle better.',

                                style:
                                    const TextStyle(
                                  fontSize: 13,
                                  height: 1.4,
                                  color:
                                      Color(
                                    0xFF795548,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // ============================================================
  // EMPTY PREDICTION
  // ============================================================

  Prediction _emptyPrediction() {
    return Prediction(
      currentDay: 1,
      phaseLabel: '',
      nextPeriodLabel: '',
      fertileWindowLabel: '',
      cycleProgress: 0,
      factorWeights: const {},
      pcosRisk: 'No PCOS reported',
      avgCycleLength: 28,
      avgPeriodLength: 5,
      cycleLengthHistory: const [],
      predictedCycleLength: 28,
    );
  }
}

// ================================================================
// MODEL FACTORS CARD
// ================================================================

class _ModelFactorsCard extends StatelessWidget {
  final Map<String, double> factors;

  const _ModelFactorsCard({
    required this.factors,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final entries =
        factors.entries.toList();

    entries.sort(
      (a, b) =>
          b.value.compareTo(
        a.value,
      ),
    );

    return Container(
      width:
          double.infinity,

      padding:
          const EdgeInsets.all(
        18,
      ),

      decoration:
          BoxDecoration(
        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(
          22,
        ),

        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(
              0.04,
            ),
            blurRadius:
                12,
            offset:
                const Offset(
              0,
              4,
            ),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          const Text(
            'What the model uses',

            style:
                TextStyle(
              fontSize: 16,
              fontWeight:
                  FontWeight.w700,
              color:
                  Color(0xFF4A332B),
            ),
          ),

          const SizedBox(
            height: 5,
          ),

          const Text(
            'These values show the Decision Tree feature importance from the trained model. They describe how the model uses the input features; they do not mean that one factor causes a cycle change.',

            style:
                TextStyle(
              fontSize: 12,
              height: 1.4,
              color:
                  Color(0xFF8D7064),
            ),
          ),

          const SizedBox(
            height: 15,
          ),

          ...entries.map(
            (entry) {

              final value =
                  entry.value.clamp(
                0.0,
                1.0,
              );

              return Padding(
                padding:
                    const EdgeInsets.only(
                  bottom: 12,
                ),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [

                    Row(
                      children: [

                        Expanded(
                          child: Text(
                            entry.key,

                            style:
                                const TextStyle(
                              fontSize: 13,
                              fontWeight:
                                  FontWeight.w600,
                              color:
                                  Color(
                                0xFF5D4037,
                              ),
                            ),
                          ),
                        ),

                        Text(
                          '${(value * 100).toStringAsFixed(1)}%',

                          style:
                              const TextStyle(
                            fontSize: 12,
                            fontWeight:
                                FontWeight.w600,
                            color:
                                Color(
                              0xFFD8754E,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 6,
                    ),

                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(
                        10,
                      ),

                      child:
                          LinearProgressIndicator(
                        value:
                            value,

                        minHeight:
                            7,

                        backgroundColor:
                            const Color(
                          0xFFFFE9DC,
                        ),

                        valueColor:
                            const AlwaysStoppedAnimation<
                                Color>(
                          Color(
                            0xFFD8754E,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ================================================================
// INFO CARD
// ================================================================

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(
        16,
      ),

      decoration:
          BoxDecoration(
        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(
          20,
        ),

        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(
              0.035,
            ),
            blurRadius:
                10,
            offset:
                const Offset(
              0,
              3,
            ),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          Icon(
            icon,
            size: 22,
            color:
                const Color(
              0xFFD8754E,
            ),
          ),

          const SizedBox(
            height: 10,
          ),

          Text(
            title,

            style:
                const TextStyle(
              fontSize: 12,
              color:
                  Color(0xFF9A8176),
            ),
          ),

          const SizedBox(
            height: 5,
          ),

          Text(
            value,

            maxLines: 2,

            overflow:
                TextOverflow.ellipsis,

            style:
                const TextStyle(
              fontSize: 14,
              fontWeight:
                  FontWeight.w700,
              color:
                  Color(0xFF4A332B),
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// ACTION CARD
// ================================================================

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return GestureDetector(
      onTap:
          onTap,

      child: Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),

        decoration:
            BoxDecoration(
          color:
              Colors.white,

          borderRadius:
              BorderRadius.circular(
            20,
          ),

          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withOpacity(
                0.035,
              ),
              blurRadius:
                  10,
              offset:
                  const Offset(
                0,
                3,
              ),
            ),
          ],
        ),

        child: Row(
          children: [

            Container(
              width: 42,
              height: 42,

              decoration:
                  BoxDecoration(
                color:
                    const Color(
                  0xFFFFE9DC,
                ),

                borderRadius:
                    BorderRadius.circular(
                  13,
                ),
              ),

              child: Icon(
                icon,
                color:
                    const Color(
                  0xFFD8754E,
                ),
                size: 22,
              ),
            ),

            const SizedBox(
              width: 10,
            ),

            Expanded(
              child: Text(
                title,

                maxLines:
                    2,

                style:
                    const TextStyle(
                  fontSize: 13,
                  fontWeight:
                      FontWeight.w600,
                  color:
                      Color(0xFF5D4037),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}