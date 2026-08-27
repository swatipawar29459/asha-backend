import 'package:flutter/material.dart';
import '../theme/asha_theme.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AshaColors.peach, AshaColors.coral],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: Image.asset(
                      'assets/images/girl.png',
                      height: 260,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Keep Track of\nYour Period',
                        style: Theme.of(context)
                            .textTheme
                            .displayLarge
                            ?.copyWith(fontSize: 28),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Easily and accurately track each phase of your menstrual cycle.',
                        style: TextStyle(fontSize: 13, color: AshaColors.ink),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AshaColors.cream,
                            padding: const EdgeInsets.all(16),
                          ),
                          onPressed: () =>
                              Navigator.pushReplacementNamed(context, '/login'),
                          child: const Text(
                            "Let's Explore",
                            style: TextStyle(
                              color: AshaColors.ink,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}