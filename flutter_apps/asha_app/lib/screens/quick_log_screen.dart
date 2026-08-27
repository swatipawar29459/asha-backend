import 'package:flutter/material.dart';
import '../theme/asha_theme.dart';
import '../services/api_service.dart';

class QuickLogScreen extends StatefulWidget {
  const QuickLogScreen({super.key});
  @override
  State<QuickLogScreen> createState() => _QuickLogScreenState();
}

class _QuickLogScreenState extends State<QuickLogScreen> {
  String flow = 'Medium';
  final Set<String> symptoms = {'Cramps'};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('Log today')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Flow', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: ['Light', 'Medium', 'Heavy'].map((f) => AshaChip(label: '💧 $f', selected: flow == f, onTap: () => setState(() => flow = f))).toList()),
              const SizedBox(height: 18),
              Text('Symptoms', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: ['Cramps', 'Headache', 'Bloating', 'Fatigue'].map((s) => AshaChip(label: s, selected: symptoms.contains(s), onTap: () => setState(() => symptoms.contains(s) ? symptoms.remove(s) : symptoms.add(s)))).toList()),
              const SizedBox(height: 20),
              ListTile(
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                leading: const Icon(Icons.water_drop_rounded, color: AshaColors.coral),
                title: const Text('Also log discharge', style: TextStyle(fontSize: 13)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, '/discharge'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AshaColors.ink, padding: const EdgeInsets.all(16)),
                  onPressed: () async {
                    await ApiService.logSymptoms(1, {'flow': flow, 'symptoms': symptoms.toList()});
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Save log', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}