import 'package:flutter/material.dart';
import '../theme/asha_theme.dart';
import '../services/health_profile_store.dart';

class PcosScreen extends StatefulWidget {
  const PcosScreen({super.key});
  @override
  State<PcosScreen> createState() => _PcosScreenState();
}

class _PcosScreenState extends State<PcosScreen> {
  int selected = HealthProfileStore.pcos;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Do you have PCOS?', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 20),
              Wrap(spacing: 8, children: [
                AshaChip(label: 'Yes', selected: selected == 1, onTap: () => setState(() => selected = 1)),
                AshaChip(label: 'No', selected: selected == 0, onTap: () => setState(() => selected = 0)),
              ]),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AshaColors.ink, padding: const EdgeInsets.all(16)),
                  onPressed: () async {
                    HealthProfileStore.pcos = selected;
                    await HealthProfileStore.save();
                    Navigator.pushNamed(context, '/onboard-symptoms');
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