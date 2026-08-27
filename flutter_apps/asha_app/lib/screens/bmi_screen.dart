import 'package:flutter/material.dart';
import '../theme/asha_theme.dart';
import '../services/health_profile_store.dart';

class BmiScreen extends StatefulWidget {
const BmiScreen({super.key});

@override
State<BmiScreen> createState() => _BmiScreenState();
}

class _BmiScreenState extends State<BmiScreen> {
final controller = TextEditingController();

String? error;

@override
void initState() {
super.initState();

if (HealthProfileStore.bmi != null) {
controller.text =
HealthProfileStore.bmi!.toString();
}
}

@override
void dispose() {
controller.dispose();
super.dispose();
}

Future<void> save() async {
final value =
double.tryParse(controller.text.trim());

if (value == null || value <= 0) {
setState(() {
error = 'Please enter a valid BMI.';
});
return;
}

HealthProfileStore.bmi = value;

await HealthProfileStore.save();

if (!mounted) return;

Navigator.pushReplacementNamed(
context,
'/onboard-exercise',
);
}

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
'What is your BMI?',
style: Theme.of(context)
.textTheme
.titleLarge,
),

const SizedBox(height: 8),

const Text(
'Enter your BMI value. '
'You can find it from a health check '
'or calculate it using your height and weight.',
style: TextStyle(
fontSize: 12,
color: AshaColors.slate,
),
),

const SizedBox(height: 24),

TextField(
controller: controller,
keyboardType:
const TextInputType.numberWithOptions(
decimal: true,
),
decoration: InputDecoration(
labelText: 'BMI',
hintText: 'Example: 22.5',
errorText: error,
),
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
onPressed: save,
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