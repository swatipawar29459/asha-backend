import 'package:flutter/material.dart';
import '../theme/asha_theme.dart';
import '../services/health_profile_store.dart';

class ExerciseScreen extends StatefulWidget {
const ExerciseScreen({super.key});

@override
State<ExerciseScreen> createState() =>
_ExerciseScreenState();
}

class _ExerciseScreenState
extends State<ExerciseScreen> {

int selected =
HealthProfileStore.exerciseFrequency;

@override
Widget build(BuildContext context) {
return Scaffold(
body: SafeArea(
child: Padding(
padding: const EdgeInsets.all(24),
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Text(
'How often do you exercise?',
style: Theme.of(context)
.textTheme
.titleLarge,
),

const SizedBox(height: 8),

const Text(
'This helps Asha understand your lifestyle patterns.',
style: TextStyle(
fontSize: 12,
color: AshaColors.slate,
),
),

const SizedBox(height: 24),

AshaChip(
label: 'Low',
selected: selected == 0,
onTap: () {
setState(() {
selected = 0;
});
},
),

const SizedBox(height: 10),

AshaChip(
label: 'Moderate',
selected: selected == 1,
onTap: () {
setState(() {
selected = 1;
});
},
),

const SizedBox(height: 10),

AshaChip(
label: 'High',
selected: selected == 2,
onTap: () {
setState(() {
selected = 2;
});
},
),

const Spacer(),

SizedBox(
width: double.infinity,
child: ElevatedButton(
style: ElevatedButton.styleFrom(
backgroundColor:
AshaColors.ink,
padding:
const EdgeInsets.all(16),
),
onPressed: () async {
HealthProfileStore
.exerciseFrequency =
selected;

await HealthProfileStore.save();

if (!mounted) return;

Navigator.pushReplacementNamed(
context,
'/onboard-last-period',
);
},
child: const Text(
'Next',
style: TextStyle(
color: Colors.white,
fontWeight: FontWeight.bold,
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