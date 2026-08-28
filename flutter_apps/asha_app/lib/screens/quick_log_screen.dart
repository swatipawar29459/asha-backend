import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../theme/asha_theme.dart';
import '../services/api_service.dart';


// ============================================================
// QUICK LOG SCREEN
// ============================================================

class QuickLogScreen extends StatefulWidget {
  const QuickLogScreen({
    super.key,
  });

  @override
  State<QuickLogScreen> createState() =>
      _QuickLogScreenState();
}


class _QuickLogScreenState
    extends State<QuickLogScreen> {

  String flow = 'Medium';

  final Set<String> symptoms = {
    'Cramps',
  };

  bool saving = false;


  // ==========================================================
  // SAVE LOG
  // ==========================================================

  Future<void> _saveLog() async {

    if (saving) return;

    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please log in again.',
          ),
        ),
      );

      return;
    }


    setState(() {
      saving = true;
    });


    try {

      await ApiService.logSymptoms(

        user.uid,

        {
          'flow': flow,

          'symptoms':
              symptoms.toList(),

          'date':
              DateTime.now()
                  .toIso8601String(),
        },
      );


      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Today’s log has been saved.',
          ),
        ),
      );


      Navigator.pop(context);

    } catch (e) {

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not save log: $e',
          ),
        ),
      );

    } finally {

      if (mounted) {

        setState(() {
          saving = false;
        });
      }
    }
  }


  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        backgroundColor:
            Colors.transparent,

        elevation: 0,

        title: const Text(
          'Log today',
        ),
      ),


      body: SafeArea(

        child: SingleChildScrollView(

          padding:
              const EdgeInsets.all(20),

          child: Column(

            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [

              // =================================================
              // FLOW
              // =================================================

              Text(
                'Flow',

                style:
                    Theme.of(context)
                        .textTheme
                        .titleLarge,
              ),

              const SizedBox(
                height: 10,
              ),


              Wrap(

                spacing: 8,

                runSpacing: 8,

                children: [

                  _flowChip(
                    'Light',
                  ),

                  _flowChip(
                    'Medium',
                  ),

                  _flowChip(
                    'Heavy',
                  ),
                ],
              ),


              const SizedBox(
                height: 22,
              ),


              // =================================================
              // SYMPTOMS
              // =================================================

              Text(
                'Symptoms',

                style:
                    Theme.of(context)
                        .textTheme
                        .titleLarge,
              ),

              const SizedBox(
                height: 10,
              ),


              Wrap(

                spacing: 8,

                runSpacing: 8,

                children: [

                  _symptomChip(
                    'Cramps',
                  ),

                  _symptomChip(
                    'Headache',
                  ),

                  _symptomChip(
                    'Bloating',
                  ),

                  _symptomChip(
                    'Fatigue',
                  ),

                  _symptomChip(
                    'Mood Swings',
                  ),
                ],
              ),


              const SizedBox(
                height: 22,
              ),


              // =================================================
              // DISCHARGE
              // =================================================

              ListTile(

                contentPadding:
                    const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),

                tileColor:
                    Colors.white,

                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),

                leading: const Icon(
                  Icons.water_drop_rounded,

                  color:
                      AshaColors.coral,
                ),

                title: const Text(
                  'Also log discharge',

                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),

                trailing:
                    const Icon(
                  Icons.chevron_right,
                ),

                onTap: () {

                  Navigator.pushNamed(
                    context,
                    '/discharge',
                  );
                },
              ),


              const SizedBox(
                height: 24,
              ),


              // =================================================
              // SAVE BUTTON
              // =================================================

              SizedBox(

                width:
                    double.infinity,

                child:
                    ElevatedButton(

                  style:
                      ElevatedButton.styleFrom(

                    backgroundColor:
                        AshaColors.ink,

                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 16,
                    ),

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                    ),
                  ),

                  onPressed:
                      saving
                          ? null
                          : _saveLog,

                  child:

                      saving

                          ? const SizedBox(
                              width: 20,
                              height: 20,

                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                                color:
                                    Colors.white,
                              ),
                            )

                          : const Text(
                              'Save log',

                              style:
                                  TextStyle(
                                color:
                                    Colors.white,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  // ==========================================================
  // FLOW CHIP
  // ==========================================================

  Widget _flowChip(
    String value,
  ) {

    return AshaChip(

      label:
          '💧 $value',

      selected:
          flow == value,

      onTap: () {

        setState(() {
          flow = value;
        });
      },
    );
  }


  // ==========================================================
  // SYMPTOM CHIP
  // ==========================================================

  Widget _symptomChip(
    String value,
  ) {

    return AshaChip(

      label:
          value,

      selected:
          symptoms.contains(value),

      onTap: () {

        setState(() {

          if (symptoms.contains(value)) {

            symptoms.remove(
              value,
            );

          } else {

            symptoms.add(
              value,
            );
          }
        });
      },
    );
  }
}