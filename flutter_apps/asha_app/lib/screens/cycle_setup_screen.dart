import 'package:flutter/material.dart';

import '../theme/asha_theme.dart';
import '../services/health_profile_store.dart';

class CycleSetupScreen extends StatefulWidget {
  const CycleSetupScreen({super.key});

  @override
  State<CycleSetupScreen> createState() =>
      _CycleSetupScreenState();
}

class _CycleSetupScreenState
    extends State<CycleSetupScreen> {
  final ageController = TextEditingController();
  final cycleLengthController =
      TextEditingController();
  final periodLengthController =
      TextEditingController();

  int stress = HealthProfileStore.stress;

  String? error;

  @override
  void initState() {
    super.initState();

    if (HealthProfileStore.age != null) {
      ageController.text =
          HealthProfileStore.age!.toString();
    }

    if (HealthProfileStore.cycleLength > 0) {
      cycleLengthController.text =
          HealthProfileStore.cycleLength.toString();
    }

    if (HealthProfileStore.periodLength != null) {
      periodLengthController.text =
          HealthProfileStore.periodLength!.toString();
    }
  }

  @override
  void dispose() {
    ageController.dispose();
    cycleLengthController.dispose();
    periodLengthController.dispose();
    super.dispose();
  }

  Future<void> saveAndContinue() async {
    final parsedAge =
        int.tryParse(ageController.text.trim());

    final parsedCycleLength =
        int.tryParse(
      cycleLengthController.text.trim(),
    );

    final parsedPeriodLength =
        int.tryParse(
      periodLengthController.text.trim(),
    );

    if (parsedAge == null ||
        parsedAge < 10 ||
        parsedAge > 100) {
      setState(() {
        error = 'Please enter a valid age.';
      });
      return;
    }

    if (parsedCycleLength == null ||
        parsedCycleLength < 15 ||
        parsedCycleLength > 60) {
      setState(() {
        error =
            'Please enter a valid cycle length between 15 and 60 days.';
      });
      return;
    }

    if (parsedPeriodLength == null ||
        parsedPeriodLength < 1 ||
        parsedPeriodLength > 15) {
      setState(() {
        error =
            'Please enter a valid period length between 1 and 15 days.';
      });
      return;
    }

    if (parsedPeriodLength >= parsedCycleLength) {
      setState(() {
        error =
            'Period length should be shorter than cycle length.';
      });
      return;
    }

    FocusScope.of(context).unfocus();

    HealthProfileStore.age = parsedAge;
    HealthProfileStore.cycleLength =
        parsedCycleLength;
    HealthProfileStore.periodLength =
        parsedPeriodLength;
    HealthProfileStore.stress = stress;

    await HealthProfileStore.save();

    debugPrint(
      'Cycle profile saved: '
      'age=${HealthProfileStore.age}, '
      'cycle=${HealthProfileStore.cycleLength}, '
      'period=${HealthProfileStore.periodLength}, '
      'stress=${HealthProfileStore.stress}',
    );

    if (!mounted) return;

    Navigator.pushReplacementNamed(
      context,
      '/onboard-bmi',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Tell us about you',
                style:
                    Theme.of(context)
                        .textTheme
                        .titleLarge,
              ),

              const SizedBox(height: 8),

              const Text(
                'These details help Asha make your cycle prediction more personalized.',
                style: TextStyle(
                  fontSize: 12,
                  color: AshaColors.slate,
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: ageController,
                keyboardType:
                    TextInputType.number,
                decoration:
                    const InputDecoration(
                  labelText: 'Age',
                  hintText: 'Example: 20',
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller:
                    cycleLengthController,
                keyboardType:
                    TextInputType.number,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Average cycle length (days)',
                  hintText: 'Example: 28',
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller:
                    periodLengthController,
                keyboardType:
                    TextInputType.number,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Average period length (days)',
                  hintText: 'Example: 5',
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'STRESS LEVEL (1 = low, 5 = high)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Wrap(
                spacing: 8,
                children: [1, 2, 3, 4, 5]
                    .map(
                      (n) => AshaChip(
                        label: '$n',
                        selected:
                            stress == n,
                        onTap: () {
                          setState(() {
                            stress = n;
                          });
                        },
                      ),
                    )
                    .toList(),
              ),

              if (error != null) ...[
                const SizedBox(height: 16),

                Text(
                  error!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
              ],

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        AshaColors.ink,
                    padding:
                        const EdgeInsets.all(16),
                  ),
                  onPressed:
                      saveAndContinue,
                  child: const Text(
                    'Save & continue',
                    style: TextStyle(
                      color: Colors.white,
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