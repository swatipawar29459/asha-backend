import 'package:flutter/material.dart';

import '../theme/asha_theme.dart';
import '../services/notification_service.dart';


// ============================================================
// REMINDERS SCREEN
// ============================================================

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({
    super.key,
  });

  @override
  State<RemindersScreen> createState() =>
      _RemindersScreenState();
}


class _RemindersScreenState
    extends State<RemindersScreen> {

  bool periodReminder = true;

  bool symptomReminder = true;

  bool hydrationReminder = false;

  TimeOfDay periodTime =
      const TimeOfDay(
    hour: 9,
    minute: 0,
  );

  TimeOfDay symptomTime =
      const TimeOfDay(
    hour: 20,
    minute: 0,
  );

  TimeOfDay hydrationTime =
      const TimeOfDay(
    hour: 14,
    minute: 0,
  );


  // ==========================================================
  // PICK TIME
  // ==========================================================

  Future<void> _pickTime(
    String type,
  ) async {

    TimeOfDay initialTime;

    if (type == 'period') {

      initialTime =
          periodTime;

    } else if (type == 'symptom') {

      initialTime =
          symptomTime;

    } else {

      initialTime =
          hydrationTime;
    }


    final picked =
        await showTimePicker(

      context: context,

      initialTime:
          initialTime,
    );


    if (picked == null) {
      return;
    }


    setState(() {

      if (type == 'period') {

        periodTime =
            picked;

      } else if (type == 'symptom') {

        symptomTime =
            picked;

      } else {

        hydrationTime =
            picked;
      }
    });
  }


  // ==========================================================
  // FORMAT TIME
  // ==========================================================

  String _formatTime(
    TimeOfDay time,
  ) {

    final hour =
        time.hourOfPeriod == 0
            ? 12
            : time.hourOfPeriod;

    final minute =
        time.minute
            .toString()
            .padLeft(
              2,
              '0',
            );

    final period =
        time.period ==
                DayPeriod.am
            ? 'AM'
            : 'PM';

    return '$hour:$minute $period';
  }


  // ==========================================================
  // SAVE REMINDERS
  // ==========================================================

  Future<void> _saveReminders() async {

    try {

      // ------------------------------------------------------
      // PERIOD REMINDER
      // ------------------------------------------------------

      if (periodReminder) {

        await NotificationService
            .scheduleReminder(
          id: 100,
          title:
              'Asha reminder 🌼',
          body:
              'Your period may be approaching. Check your cycle.',
          hour:
              periodTime.hour,
          minute:
              periodTime.minute,
        );

      } else {

        await NotificationService
            .cancelReminder(
          100,
        );
      }


      // ------------------------------------------------------
      // SYMPTOM REMINDER
      // ------------------------------------------------------

      if (symptomReminder) {

        await NotificationService
            .scheduleReminder(
          id: 101,
          title:
              'How are you feeling today?',
          body:
              'Take a moment to log your symptoms in Asha.',
          hour:
              symptomTime.hour,
          minute:
              symptomTime.minute,
        );

      } else {

        await NotificationService
            .cancelReminder(
          101,
        );
      }


      // ------------------------------------------------------
      // HYDRATION REMINDER
      // ------------------------------------------------------

      if (hydrationReminder) {

        await NotificationService
            .scheduleReminder(
          id: 102,
          title:
              'Hydration reminder 💧',
          body:
              'Take a moment to drink some water.',
          hour:
              hydrationTime.hour,
          minute:
              hydrationTime.minute,
        );

      } else {

        await NotificationService
            .cancelReminder(
          102,
        );
      }


      if (!mounted) return;


      ScaffoldMessenger.of(context)
          .showSnackBar(

        const SnackBar(
          content: Text(
            'Reminders updated successfully.',
          ),
        ),
      );

    } catch (e) {

      if (!mounted) return;


      ScaffoldMessenger.of(context)
          .showSnackBar(

        SnackBar(
          content: Text(
            'Could not update reminders: $e',
          ),
        ),
      );
    }
  }


  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {

    return Scaffold(

      appBar: AppBar(

        backgroundColor:
            Colors.transparent,

        elevation: 0,

        title: const Text(
          'Reminders',
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
              // INTRO
              // =================================================

              Text(

                'Gentle reminders',

                style:
                    Theme.of(context)
                        .textTheme
                        .titleLarge,
              ),

              const SizedBox(
                height: 6,
              ),

              const Text(

                'Choose when Asha should remind you.',

                style: TextStyle(
                  color:
                      AshaColors.slate,
                  fontSize: 13,
                ),
              ),


              const SizedBox(
                height: 20,
              ),


              // =================================================
              // PERIOD REMINDER
              // =================================================

              _reminderCard(

                icon:
                    Icons.calendar_month_rounded,

                title:
                    'Period reminder',

                subtitle:
                    'Get a gentle reminder to check your cycle.',

                enabled:
                    periodReminder,

                time:
                    periodTime,

                onToggle: (value) {

                  setState(() {
                    periodReminder =
                        value;
                  });
                },

                onTimeTap: () {

                  _pickTime(
                    'period',
                  );
                },
              ),


              const SizedBox(
                height: 12,
              ),


              // =================================================
              // SYMPTOM REMINDER
              // =================================================

              _reminderCard(

                icon:
                    Icons.favorite_rounded,

                title:
                    'Daily symptom check',

                subtitle:
                    'Remember to log how you are feeling.',

                enabled:
                    symptomReminder,

                time:
                    symptomTime,

                onToggle: (value) {

                  setState(() {
                    symptomReminder =
                        value;
                  });
                },

                onTimeTap: () {

                  _pickTime(
                    'symptom',
                  );
                },
              ),


              const SizedBox(
                height: 12,
              ),


              // =================================================
              // HYDRATION REMINDER
              // =================================================

              _reminderCard(

                icon:
                    Icons.water_drop_rounded,

                title:
                    'Hydration reminder',

                subtitle:
                    'Get a reminder to stay hydrated.',

                enabled:
                    hydrationReminder,

                time:
                    hydrationTime,

                onToggle: (value) {

                  setState(() {
                    hydrationReminder =
                        value;
                  });
                },

                onTimeTap: () {

                  _pickTime(
                    'hydration',
                  );
                },
              ),


              const SizedBox(
                height: 24,
              ),


              // =================================================
              // SAVE
              // =================================================

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
                      _saveReminders,

                  child:
                      const Text(

                    'Save reminders',

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
  // REMINDER CARD
  // ==========================================================

  Widget _reminderCard({

    required IconData icon,

    required String title,

    required String subtitle,

    required bool enabled,

    required TimeOfDay time,

    required ValueChanged<bool>
        onToggle,

    required VoidCallback
        onTimeTap,
  }) {

    return Container(

      padding:
          const EdgeInsets.all(16),

      decoration:
          BoxDecoration(

        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(
          16,
        ),

        border:
            Border.all(
          color:
              Colors.black12,
        ),
      ),


      child: Column(

        children: [

          Row(

            children: [

              Container(

                width: 42,
                height: 42,

                decoration:
                    BoxDecoration(

                  color:
                      AshaColors.peach,

                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),

                child:
                    Icon(
                  icon,
                  color:
                      AshaColors.coral,
                ),
              ),


              const SizedBox(
                width: 12,
              ),


              Expanded(

                child: Column(

                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [

                    Text(

                      title,

                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(
                      height: 3,
                    ),

                    Text(

                      subtitle,

                      style:
                          const TextStyle(
                        color:
                            AshaColors.slate,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),


              Switch(

                value:
                    enabled,

                activeThumbColor:
                    AshaColors.coral,

                onChanged:
                    onToggle,
              ),
            ],
          ),


          if (enabled) ...[

            const SizedBox(
              height: 12,
            ),

            InkWell(

              onTap:
                  onTimeTap,

              borderRadius:
                  BorderRadius.circular(
                12,
              ),

              child: Container(

                width:
                    double.infinity,

                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),

                decoration:
                    BoxDecoration(

                  color:
                      AshaColors.lavender,

                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),

                child: Row(

                  children: [

                    const Icon(
                      Icons.access_time_rounded,
                      size: 20,
                    ),

                    const SizedBox(
                      width: 8,
                    ),

                    Text(

                      _formatTime(
                        time,
                      ),

                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),

                    const Spacer(),

                    const Text(
                      'Change',
                      style:
                          TextStyle(
                        fontSize: 12,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}