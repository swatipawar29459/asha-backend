import 'package:flutter/material.dart';
import '../theme/asha_theme.dart';
import '../services/health_profile_store.dart';
import '../services/api_service.dart';

class SymptomsOnboardScreen extends StatefulWidget {
  const SymptomsOnboardScreen({super.key});
  @override
  State<SymptomsOnboardScreen> createState() => _SymptomsOnboardScreenState();
}

class _SymptomsOnboardScreenState extends State<SymptomsOnboardScreen> {
  final options = ['Cramps', 'Headache', 'Fatigue', 'Bloating', 'Mood Swings'];
  Set<String> selected = HealthProfileStore.symptoms;
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Any regular symptoms?', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 20),
              Wrap(spacing: 8, runSpacing: 8, children: options.map((o) =>
                AshaChip(label: o, selected: selected.contains(o),
                  onTap: () => setState(() => selected.contains(o) ? selected.remove(o) : selected.add(o)))
              ).toList()),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AshaColors.coral, padding: const EdgeInsets.all(16)),
                  onPressed: loading ? null : () async {
                    setState(() => loading = true);
                    HealthProfileStore.symptoms = selected;
                    await HealthProfileStore.save();
                    try {
                      await ApiService.logSymptoms(1, HealthProfileStore.toJson());
                    } catch (_) {}
                    if (context.mounted) Navigator.pushReplacementNamed(context, '/home');
                  },
                  child: loading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Finish', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}