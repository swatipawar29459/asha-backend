import 'package:flutter/material.dart';
import '../theme/asha_theme.dart';
import '../services/health_profile_store.dart';

class DietScreen extends StatefulWidget {
  const DietScreen({super.key});
  @override
  State<DietScreen> createState() => _DietScreenState();
}

class _DietScreenState extends State<DietScreen> {
  final options = ['Low Carb', 'Balanced', 'High Sugar', 'Vegetarian'];
  String selected = HealthProfileStore.diet;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('How would you describe your diet?', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 20),
              Wrap(spacing: 8, runSpacing: 8, children: options.map((o) =>
                AshaChip(label: o, selected: selected == o, onTap: () => setState(() => selected = o))
              ).toList()),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AshaColors.ink, padding: const EdgeInsets.all(16)),
                  onPressed: () async {
                    HealthProfileStore.diet = selected;
                    await HealthProfileStore.save();
                    Navigator.pushNamed(context, '/onboard-pcos');
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