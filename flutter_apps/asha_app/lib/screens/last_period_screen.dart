import 'package:flutter/material.dart';
import '../theme/asha_theme.dart';
import '../services/health_profile_store.dart';

class LastPeriodScreen extends StatefulWidget {
const LastPeriodScreen({super.key});
@override
State<LastPeriodScreen> createState() => _LastPeriodScreenState();
}

class _LastPeriodScreenState extends State<LastPeriodScreen> {
DateTime selected = DateTime.now();

@override
Widget build(BuildContext context) {
return Scaffold(
body: SafeArea(
child: Padding(
padding: const EdgeInsets.all(24),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text('When did your last period start?', style: Theme.of(context).textTheme.titleLarge),
const SizedBox(height: 6),
const Text('This is what lets Asha predict your next date.', style: TextStyle(fontSize: 12, color: AshaColors.slate)),
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
Text('${selected.day}/${selected.month}/${selected.year}',
style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
const Icon(Icons.calendar_today, color: AshaColors.coral),
],
),
),
),
const Spacer(),
SizedBox(
width: double.infinity,
child: ElevatedButton(
style: ElevatedButton.styleFrom(backgroundColor: AshaColors.ink, padding: const EdgeInsets.all(16)),
onPressed: () async {
HealthProfileStore.lastPeriodDate = selected;
await HealthProfileStore.save();
Navigator.pushNamed(context, '/onboard-sleep');
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