import 'package:flutter/material.dart';
import '../theme/asha_theme.dart';
import '../services/health_profile_store.dart';

class CycleSetupScreen extends StatefulWidget {
  const CycleSetupScreen({super.key});
  @override
  State<CycleSetupScreen> createState() => _CycleSetupScreenState();
}

class _CycleSetupScreenState extends State<CycleSetupScreen> {
  final age = TextEditingController();
  final cycleLength = TextEditingController();
  final periodLength = TextEditingController();
  int stress = 3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tell us about you', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(controller: age, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Age')),
              const SizedBox(height: 12),
              TextField(controller: cycleLength, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Average cycle length (days)')),
              const SizedBox(height: 12),
              TextField(controller: periodLength, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Average period length (days)')),
              const SizedBox(height: 14),
              const Text('STRESS LEVEL (1 = low, 5 = high)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: [1, 2, 3, 4, 5].map((n) =>
                AshaChip(label: '$n', selected: stress == n, onTap: () => setState(() => stress = n))
              ).toList()),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AshaColors.ink, padding: const EdgeInsets.all(16)),
                  onPressed: () async {
                    HealthProfileStore.age = int.tryParse(age.text);
                    HealthProfileStore.cycleLength = int.tryParse(cycleLength.text) ?? 28;
                    HealthProfileStore.periodLength = int.tryParse(periodLength.text);
                    HealthProfileStore.stress = stress;
                    await HealthProfileStore.save();
                    Navigator.pushReplacementNamed(context, '/onboard-bmi');
                    },
                    
                  child: const Text('Save & continue', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}