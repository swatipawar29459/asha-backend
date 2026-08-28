import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../theme/asha_theme.dart';
import '../services/api_service.dart';
import '../models/prediction.dart';


class ReportsScreen extends StatefulWidget {
  const ReportsScreen({
    super.key,
  });

  @override
  State<ReportsScreen> createState() =>
      _ReportsScreenState();
}


class _ReportsScreenState
    extends State<ReportsScreen> {

  Prediction? prediction;

  bool loading = true;

  String? error;


  @override
  void initState() {
    super.initState();

    _loadPrediction();
  }


  // ==========================================================
  // LOAD PREDICTION
  // ==========================================================

  Future<void> _loadPrediction() async {

    try {

      final user =
          FirebaseAuth.instance.currentUser;

      if (user == null) {

        throw Exception(
          'No logged-in user.',
        );
      }


      final result =
          await ApiService.fetchPrediction(
        userId: user.uid,
      );


      if (!mounted) return;


      setState(() {

        prediction = result;

        loading = false;

        error = null;
      });

    } catch (e) {

      if (!mounted) return;


      setState(() {

        loading = false;

        error =
            'Could not load your report.';
      });


      print(
        'Reports prediction error: $e',
      );
    }
  }


  // ==========================================================
  // BUILD
  // ==========================================================

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

          child: Column(

            mainAxisSize:
                MainAxisSize.min,

            children: [

              Text(
                error!,
                textAlign:
                    TextAlign.center,
              ),

              const SizedBox(
                height: 12,
              ),

              ElevatedButton(
                onPressed:
                    _loadPrediction,

                child:
                    const Text(
                  'Try again',
                ),
              ),
            ],
          ),
        ),
      );
    }


    final p = prediction!;


    return SafeArea(

      child: SingleChildScrollView(

        padding:
            const EdgeInsets.all(20),

        child: Column(

          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            // ==================================================
            // TITLE
            // ==================================================

            Text(
              'Your reports',

              style:
                  Theme.of(context)
                      .textTheme
                      .titleLarge,
            ),

            const SizedBox(
              height: 12,
            ),


            // ==================================================
            // CYCLE LENGTH TREND
            // ==================================================

            AshaCard(

              tint:
                  AshaColors.lavender,

              child: Column(

                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  const Text(
                    'CYCLE LENGTH TREND',

                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  SizedBox(
                    height: 80,

                    child: CustomPaint(

                      size:
                          const Size(
                        double.infinity,
                        80,
                      ),

                      painter:
                          _TrendPainter(
                        p.cycleLengthHistory,
                      ),
                    ),
                  ),
                ],
              ),
            ),


            const SizedBox(
              height: 12,
            ),


            // ==================================================
            // STAT CARDS
            // ==================================================

            Row(

              children: [

                Expanded(

                  child: AshaCard(

                    tint:
                        AshaColors.sky,

                    child: Text(

                      'AVG CYCLE\n'
                      '${p.avgCycleLength} days',

                      style:
                          const TextStyle(
                        fontSize: 12,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  width: 12,
                ),

                Expanded(

                  child: AshaCard(

                    tint:
                        AshaColors.sun,

                    child: Text(

                      'AVG PERIOD\n'
                      '${p.avgPeriodLength} days',

                      style:
                          const TextStyle(
                        fontSize: 12,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),


            const SizedBox(
              height: 12,
            ),


            // ==================================================
            // AI PREDICTION
            // ==================================================

            AshaCard(

              tint:
                  AshaColors.mint,

              child: Column(

                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  const Text(
                    'AI PREDICTION',

                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  Text(

                    'Current cycle day: '
                    '${p.currentDay}',

                    style:
                        const TextStyle(
                      fontSize: 13,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 4,
                  ),

                  Text(

                    p.phaseLabel,

                    style:
                        const TextStyle(
                      fontSize: 12,
                      color:
                          AshaColors.slate,
                    ),
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  Text(

                    p.nextPeriodLabel,

                    style:
                        const TextStyle(
                      fontSize: 14,
                      fontWeight:
                          FontWeight.bold,
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
}


// ============================================================
// TREND PAINTER
// ============================================================

class _TrendPainter
    extends CustomPainter {

  final List<int> values;


  _TrendPainter(
    this.values,
  );


  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {

    if (values.isEmpty) {
      return;
    }


    if (values.length == 1) {

      final point =
          Offset(
        size.width / 2,
        size.height / 2,
      );


      canvas.drawCircle(

        point,

        4,

        Paint()
          ..color =
              AshaColors.coral,
      );

      return;
    }


    final maxV =
        values.reduce(
      (a, b) =>
          a > b ? a : b,
    ).toDouble();


    final minV =
        values.reduce(
      (a, b) =>
          a < b ? a : b,
    ).toDouble();


    final range =
        (maxV - minV)
            .clamp(1, 999)
            .toDouble();


    final dx =
        size.width /
        (values.length - 1);


    final path =
        Path();


    for (
      int i = 0;
      i < values.length;
      i++
    ) {

      final x =
          dx * i;


      final y =
          size.height -
          ((values[i] - minV) /
                  range) *
              size.height;


      if (i == 0) {

        path.moveTo(
          x,
          y,
        );

      } else {

        path.lineTo(
          x,
          y,
        );
      }
    }


    canvas.drawPath(

      path,

      Paint()

        ..color =
            AshaColors.coral

        ..strokeWidth = 3

        ..style =
            PaintingStyle.stroke

        ..strokeCap =
            StrokeCap.round,
    );
  }


  @override
  bool shouldRepaint(
    covariant _TrendPainter old,
  ) {

    return old.values != values;
  }
}