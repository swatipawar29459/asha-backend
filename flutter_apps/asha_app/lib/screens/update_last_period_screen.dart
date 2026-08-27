import 'package:flutter/material.dart';
import '../theme/asha_theme.dart';
import '../services/health_profile_store.dart';

class UpdateLastPeriodScreen extends StatefulWidget {
const UpdateLastPeriodScreen({super.key});
@override
State<UpdateLastPeriodScreen> createState() => _UpdateLastPeriodScreenState();
}

class _UpdateLastPeriodScreenState extends State<UpdateLastPeriodScreen> {
DateTime selected = HealthProfileStore.lastPeriodDate ?? DateTime.now();

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('Update last period')),
body: SafeArea(
child: Padding(
padding: const EdgeInsets.all(24),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Text('When did your most recent period start?', style: TextStyle(fontSize: 13)),
const SizedBox(height: 20),
AshaCard(
child: GestureDetector(
onTap: () async {
final picked = await showDatePicker(
context: context,
initialDate: selected,
firstDate: DateTime.now().subtract(const Duration(days: 90)),
lastDate: DateTime.now(),
);
if (picked != null) setState(() => selected = picked);
},
child: Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
Text('${selected.day}/${selected.month}/${selected.year}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
const Icon(Icons.calendar_today, color: AshaColors.coral),
],
),
),
),
const Spacer(),
SizedBox(
width: double.infinity,
child: ElevatedButton(
style: ElevatedButton.styleFrom(backgroundColor: AshaColors.coral, padding: const EdgeInsets.all(16)),
onPressed: () async {
if (HealthProfileStore.lastPeriodDate != null) {
HealthProfileStore.periodHistory.add(HealthProfileStore.lastPeriodDate!);
}
HealthProfileStore.lastPeriodDate = selected;
await HealthProfileStore.save();
if (context.mounted) Navigator.pop(context);
},
child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
),
),
],
),
),
),
);
}
}