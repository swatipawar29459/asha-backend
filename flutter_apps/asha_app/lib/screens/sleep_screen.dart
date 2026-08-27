import 'package:flutter/material.dart';
import '../theme/asha_theme.dart';
import '../services/health_profile_store.dart';

class SleepScreen extends StatefulWidget {
  const SleepScreen({super.key});
  @override
  State<SleepScreen> createState() => _SleepScreenState();
}

class _SleepScreenState extends State<SleepScreen> {
  double hours = HealthProfileStore.sleepHours;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('How many hours do you sleep?', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 30),
              Center(child: Text('${hours.toStringAsFixed(1)} hrs', style: Theme.of(context).textTheme.displayLarge)),
              Slider(
                value: hours, min: 3, max: 12, divisions: 18,
                activeColor: AshaColors.coral,
                label: hours.toStringAsFixed(1),
                onChanged: (v) => setState(() => hours = v),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AshaColors.ink, padding: const EdgeInsets.all(16)),
                  onPressed: () async {
                    HealthProfileStore.sleepHours = hours;
                    await HealthProfileStore.save();
                    Navigator.pushNamed(context, '/onboard-diet');
                  },
                  child: const Text('Next', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}