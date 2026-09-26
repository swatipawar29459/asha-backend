import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/asha_theme.dart';
import '../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
const SplashScreen({super.key});
@override
State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
@override
void initState() {
super.initState();
Timer(const Duration(seconds: 5), () {
if (!mounted) return;
final user = AuthService.currentUser;
Navigator.pushReplacementNamed(context, user != null ? '/home' : '/onboarding');
});
}

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: AshaColors.cream,
body: Center(
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Image.asset('assets/images/girl.png', height: 220),
const SizedBox(height: 20),
Text('Asha', style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 38)),
const SizedBox(height: 6),
const Text('Your health. Your journey.', style: TextStyle(color: AshaColors.slate, fontSize: 13)),
],
),
),
);
}
}