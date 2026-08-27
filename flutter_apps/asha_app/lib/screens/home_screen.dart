import 'package:flutter/material.dart';
import '../theme/asha_theme.dart';
import '../services/api_service.dart';
import '../services/health_profile_store.dart';
import '../models/prediction.dart';

class HomeScreen extends StatefulWidget {
const HomeScreen({super.key});
@override
State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
Prediction? prediction;
bool loading = true;
String? error;

@override
void initState() {
super.initState();
_load();
}

Future<void> _load() async {
try {
final p = await ApiService.fetchPrediction(userId: 1);
setState(() { prediction = p; loading = false; });
} catch (_) {
setState(() { error = 'Could not reach the server. Is Flask running?'; loading = false; });
}
}


@override
Widget build(BuildContext context) {
if (loading) return const Center(child: CircularProgressIndicator());
if (error != null) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(error!, textAlign: TextAlign.center)));
final p = prediction!;
return SafeArea(
child: SingleChildScrollView(
padding: const EdgeInsets.all(20),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
const Text('Good morning', style: TextStyle(color: AshaColors.slate)),
Text('Vittika 🌼', style: Theme.of(context).textTheme.displayLarge),
]),
GestureDetector(
onTap: () => Navigator.pushNamed(context, '/notifications'),
child: const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.notifications_rounded)),
),
],
),
const SizedBox(height: 16),
const Center(child: AshaMascot()),
const SizedBox(height: 20),
Center(
child: GestureDetector(
onTap: () => Navigator.pushNamed(context, '/why-prediction'),
child: SizedBox(
width: 210, height: 210,
child: Stack(alignment: Alignment.center, children: [
CustomPaint(size: const Size(210, 210), painter: _RingPainter(progress: p.cycleProgress)),
Column(mainAxisSize: MainAxisSize.min, children: [
Text('Day ${p.currentDay}', style: Theme.of(context).textTheme.displayLarge),
Text(p.phaseLabel, style: const TextStyle(fontSize: 12, color: AshaColors.slate)),
const SizedBox(height: 6),
Container(
padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
decoration: BoxDecoration(color: AshaColors.coral, borderRadius: BorderRadius.circular(20)),
child: Text('AI confidence ${p.confidence}%', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
),
]),
]),
),
),
),
const SizedBox(height: 20),
Row(children: [
Expanded(child: AshaCard(tint: AshaColors.mint, child: _stat('🩸 NEXT PERIOD', HealthProfileStore.nextPeriodDisplay))),
const SizedBox(width: 12),
Expanded(child: AshaCard(tint: AshaColors.sky, child: _stat('🌱 FERTILE WINDOW', HealthProfileStore.fertileWindowLabel))),
]),
GestureDetector(
onTap: () => Navigator.pushNamed(context, '/discharge'),
child: AshaCard(tint: AshaColors.sun, child: const Text('💧 Log discharge', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
),
GestureDetector(
onTap: () => Navigator.pushNamed(context, '/find-doctor'),
child: AshaCard(child: const Text('🩺 Find a doctor nearby', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
),
if (p.pcosRisk)
AshaCard(
child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
const Text('⚠ Wellness signal', style: TextStyle(color: AshaColors.alert, fontWeight: FontWeight.bold, fontSize: 12)),
const SizedBox(height: 4),
const Text('Your patterns shifted from your baseline. Worth a conversation with a doctor.', style: TextStyle(fontSize: 12)),
const SizedBox(height: 8),
ElevatedButton(
style: ElevatedButton.styleFrom(backgroundColor: AshaColors.coral),
onPressed: () => Navigator.pushNamed(context, '/find-doctor'),
child: const Text('Find a doctor', style: TextStyle(color: Colors.white, fontSize: 12)),
),
]),
),
],
),
),
);
}

Widget _stat(String label, String value) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
const SizedBox(height: 4),
Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
]);
}

class _RingPainter extends CustomPainter {
final double progress;
_RingPainter({required this.progress});
@override
void paint(Canvas canvas, Size size) {
final center = size.center(Offset.zero);
final radius = size.width / 2 - 10;
final bg = Paint()..color = AshaColors.peach..strokeWidth = 14..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
canvas.drawCircle(center, radius, bg);
final fg = Paint()
..shader = const LinearGradient(colors: [AshaColors.coral, AshaColors.coralDark]).createShader(Rect.fromCircle(center: center, radius: radius))
..strokeWidth = 14..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -1.5708, 6.2832 * progress, false, fg);
}
@override
bool shouldRepaint(covariant _RingPainter old) => old.progress != progress;
}
