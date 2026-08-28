import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../theme/asha_theme.dart';
import '../services/health_profile_store.dart';
import '../services/api_service.dart';


class SymptomsOnboardScreen
    extends StatefulWidget {

  const SymptomsOnboardScreen({
    super.key,
  });

  @override
  State<SymptomsOnboardScreen> createState() =>
      _SymptomsOnboardScreenState();
}


class _SymptomsOnboardScreenState
    extends State<SymptomsOnboardScreen> {

  final List<String> options = [

    'Cramps',
    'Headache',
    'Fatigue',
    'Bloating',
    'Mood Swings',
  ];


  Set<String> selected =
      HealthProfileStore.symptoms;


  bool loading = false;


  // ==========================================================
  // FINISH
  // ==========================================================

  Future<void> _finish() async {

    if (loading) return;


    setState(() {
      loading = true;
    });


    try {

      final user =
          FirebaseAuth.instance.currentUser;


      if (user == null) {

        throw Exception(
          'Please log in again.',
        );
      }


      HealthProfileStore.symptoms =
          selected;


      await HealthProfileStore.save();


      try {

        await ApiService.logSymptoms(

          user.uid,

          HealthProfileStore.toJson(),
        );

      } catch (e) {

        print(
          'Could not sync symptoms: $e',
        );
      }


      if (!mounted) return;


      Navigator.pushReplacementNamed(
        context,
        '/home',
      );

    } catch (e) {

      if (!mounted) return;


      ScaffoldMessenger.of(context)
          .showSnackBar(

        SnackBar(
          content: Text(
            e.toString(),
          ),
        ),
      );

    } finally {

      if (mounted) {

        setState(() {
          loading = false;
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

      body: SafeArea(

        child: Padding(

          padding:
              const EdgeInsets.all(24),

          child: Column(

            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [

              Text(

                'Any regular symptoms?',

                style:
                    Theme.of(context)
                        .textTheme
                        .titleLarge,
              ),

              const SizedBox(
                height: 20,
              ),


              Wrap(

                spacing: 8,

                runSpacing: 8,

                children:

                    options.map(

                  (option) {

                    return AshaChip(

                      label:
                          option,

                      selected:
                          selected.contains(
                        option,
                      ),

                      onTap: () {

                        setState(() {

                          if (selected
                              .contains(option)) {

                            selected.remove(
                              option,
                            );

                          } else {

                            selected.add(
                              option,
                            );
                          }
                        });
                      },
                    );
                  },

                ).toList(),
              ),


              const Spacer(),


              SizedBox(

                width:
                    double.infinity,

                child:
                    ElevatedButton(

                  style:
                      ElevatedButton.styleFrom(

                    backgroundColor:
                        AshaColors.coral,

                    padding:
                        const EdgeInsets.all(16),
                  ),

                  onPressed:
                      loading
                          ? null
                          : _finish,

                  child:

                      loading

                          ? const SizedBox(

                              width: 18,
                              height: 18,

                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                                color:
                                    Colors.white,
                              ),
                            )

                          : const Text(

                              'Finish',

                              style: TextStyle(
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
}