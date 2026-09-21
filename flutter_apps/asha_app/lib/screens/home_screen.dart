import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../theme/asha_theme.dart';
import '../services/api_service.dart';
import '../services/health_profile_store.dart';
import '../models/prediction.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() =>
      _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Prediction? prediction;

  bool loading = true;
  String? error;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ==================================================
  // LOAD
  // ==================================================

  Future<void> _load() async {
    try {
      final user =
          _auth.currentUser;

      if (user == null) {
        if (!mounted) return;

        setState(() {
          error =
              'Please sign in again.';
          loading = false;
        });

        return;
      }

      await HealthProfileStore.load();

      print(
        '================================',
      );
      print(
        'Firebase UID: ${user.uid}',
      );
      print(
        'Firebase Name: ${user.displayName}',
      );
      print(
        'Firebase Email: ${user.email}',
      );
      print(
        'Last Period: '
        '${HealthProfileStore.lastPeriodDate}',
      );
      print(
        '================================',
      );

      final p =
          await ApiService.fetchPrediction(
        userId: user.uid,
      );

      print('Prediction object created successfully.');
      print('PCOS Risk: ${p.pcosRisk}');
      print('Current Day: ${p.currentDay}');
      print('Phase: ${p.phaseLabel}');
      print('Confidence: ${p.confidence}');
      print('Next Period: ${p.nextPeriodLabel}');
      print('Fertile Window: ${p.fertileWindowLabel}');
      print('Cycle Progress: ${p.cycleProgress}');

      if (!mounted) return;

      setState(() {
        prediction = p;
        loading = false;
      });
    } catch (e, stackTrace) {
      print('================================');
      print('HOME ERROR: $e');
      print('ERROR TYPE: ${e.runtimeType}');
      print('STACK TRACE:');
      print(stackTrace);
      print('================================');

      if (!mounted) return;

      setState(() {
        error =
            'Could not load your data.';
        loading = false;
      });
    }
  }

  // ==================================================
  // GREETING
  // ==================================================

  String _getGreeting() {
    final hour =
        DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      return 'Good morning';
    } else if (hour >= 12 &&
        hour < 17) {
      return 'Good afternoon';
    } else if (hour >= 17 &&
        hour < 21) {
      return 'Good evening';
    }

    return 'Good night';
  }

  // ==================================================
  // USER NAME
  // ==================================================

  String _getUserName() {
    final user =
        FirebaseAuth.instance.currentUser;

    final name =
        user?.displayName?.trim();

    if (name != null &&
        name.isNotEmpty) {
      return name;
    }

    return 'there';
  }

  // ==================================================
  // USER ID
  // ==================================================

  String _getUserId() {
    final user =
        FirebaseAuth.instance.currentUser;

    return user?.uid ?? '';
  }

  // ==================================================
  // UI
  // ==================================================

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child:
            CircularProgressIndicator(),
      );
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding:
              const EdgeInsets.all(24),
          child: Text(
            error!,
            textAlign:
                TextAlign.center,
          ),
        ),
      );
    }

    if (prediction == null) {
      return const Center(
        child: Text(
          'No prediction available.',
        ),
      );
    }

    final p = prediction!;

    final userName =
        _getUserName();

    final userId =
        _getUserId();

    return SafeArea(
      child: SingleChildScrollView(
        padding:
            const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // HEADER

            Row(
              mainAxisAlignment:
                  MainAxisAlignment
                      .spaceBetween,
              children: [
                Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      _getGreeting(),
                      style:
                          const TextStyle(
                        color:
                            AshaColors.slate,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(
                      height: 2,
                    ),
                    Text(
                      '$userName 🌼',
                      style:
                          Theme.of(
                        context,
                      )
                              .textTheme
                              .displayLarge,
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/notifications',
                    );
                  },
                  child:
                      const CircleAvatar(
                    backgroundColor:
                        Colors.white,
                    child: Icon(
                      Icons
                          .notifications_rounded,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 4,
            ),

            // TEMPORARY UID

            Text(
              'ID: $userId',
              style:
                  const TextStyle(
                fontSize: 9,
                color:
                    AshaColors.slate,
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            const Center(
              child: AshaMascot(),
            ),

            const SizedBox(
              height: 20,
            ),

            // CYCLE RING

            Center(
              child: GestureDetector(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/why-prediction',
                  );
                },
                child: SizedBox(
                  width: 210,
                  height: 210,
                  child: Stack(
                    alignment:
                        Alignment.center,
                    children: [
                      CustomPaint(
                        size:
                            const Size(
                          210,
                          210,
                        ),
                        painter:
                            _RingPainter(
                          progress:
                              p.cycleProgress,
                        ),
                      ),

                      Column(
                        mainAxisSize:
                            MainAxisSize
                                .min,
                        children: [
                          Text(
                            'Day ${p.currentDay}',
                            style:
                                Theme.of(
                              context,
                            )
                                    .textTheme
                                    .displayLarge,
                          ),

                          Text(
                            p.phaseLabel,
                            style:
                                const TextStyle(
                              fontSize:
                                  12,
                              color:
                                  AshaColors.slate,
                            ),
                          ),

                          const SizedBox(
                            height: 6,
                          ),

                          Container(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal:
                                  12,
                              vertical: 5,
                            ),
                            decoration:
                                BoxDecoration(
                              color:
                                  AshaColors
                                      .coral,
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                20,
                              ),
                            ),
                            child:
                                Text(
                              'AI confidence ${p.confidence}%',
                              style:
                                  const TextStyle(
                                color:
                                    Colors
                                        .white,
                                fontSize:
                                    10,
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            // NEXT PERIOD + FERTILE WINDOW

            Row(
              children: [
                Expanded(
                  child: AshaCard(
                    tint:
                        AshaColors.mint,
                    child: _stat(
                      '🩸 NEXT PERIOD',
                      p.nextPeriodLabel,
                    ),
                  ),
                ),

                const SizedBox(
                  width: 12,
                ),

                Expanded(
                  child: AshaCard(
                    tint:
                        AshaColors.sky,
                    child: _stat(
                      '🌱 FERTILE WINDOW',
                      p.fertileWindowLabel,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 4,
            ),

            // DISCHARGE

            GestureDetector(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/discharge',
                );
              },
              child: AshaCard(
                tint:
                    AshaColors.sun,
                child:
                    const Text(
                  '💧 Log discharge',
                  style:
                      TextStyle(
                    fontWeight:
                        FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),

            // DOCTOR

            GestureDetector(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/find-doctor',
                );
              },
              child: AshaCard(
                child:
                    const Text(
                  '🩺 Find a doctor nearby',
                  style:
                      TextStyle(
                    fontWeight:
                        FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),

            // PCOS

            if (p.pcosRisk == 'Moderate' ||
                p.pcosRisk == 'High')
              AshaCard(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    const Text(
                      '⚠ Wellness signal',
                      style:
                          TextStyle(
                        color:
                            AshaColors
                                .alert,
                        fontWeight:
                            FontWeight
                                .bold,
                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    const Text(
                      'Your patterns shifted from your baseline. Worth a conversation with a doctor.',
                      style:
                          TextStyle(
                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    ElevatedButton(
                      style:
                          ElevatedButton
                              .styleFrom(
                        backgroundColor:
                            AshaColors
                                .coral,
                      ),
                      onPressed: () {
                        Navigator
                            .pushNamed(
                          context,
                          '/find-doctor',
                        );
                      },
                      child:
                          const Text(
                        'Find a doctor',
                        style:
                            TextStyle(
                          color:
                              Colors
                                  .white,
                          fontSize:
                              12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ==================================================
  // STAT
  // ==================================================

  Widget _stat(
    String label,
    String value,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style:
              const TextStyle(
            fontSize: 11,
            fontWeight:
                FontWeight.bold,
          ),
        ),

        const SizedBox(
          height: 4,
        ),

        Text(
          value,
          style:
              const TextStyle(
            fontWeight:
                FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// CYCLE RING
// ============================================================

class _RingPainter
    extends CustomPainter {
  final double progress;

  _RingPainter({
    required this.progress,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final center =
        size.center(
      Offset.zero,
    );

    final radius =
        size.width / 2 - 10;

    final bg = Paint()
      ..color =
          AshaColors.peach
      ..strokeWidth = 14
      ..style =
          PaintingStyle.stroke
      ..strokeCap =
          StrokeCap.round;

    canvas.drawCircle(
      center,
      radius,
      bg,
    );

    final fg = Paint()
      ..shader =
          const LinearGradient(
        colors: [
          AshaColors.coral,
          AshaColors.coralDark,
        ],
      ).createShader(
        Rect.fromCircle(
          center: center,
          radius: radius,
        ),
      )
      ..strokeWidth = 14
      ..style =
          PaintingStyle.stroke
      ..strokeCap =
          StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(
        center: center,
        radius: radius,
      ),
      -1.5708,
      6.2832 * progress,
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(
    covariant _RingPainter old,
  ) {
    return old.progress !=
        progress;
  }
}