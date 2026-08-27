import 'package:flutter/material.dart';
import '../theme/asha_theme.dart';

class WhyPredictionScreen extends StatelessWidget {
  const WhyPredictionScreen({super.key});

  Widget _bar(String label, double value, Color color) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 70,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 8,
                  backgroundColor: AshaColors.peach,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Why this prediction'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your next period estimate is mainly based on:',
                style: TextStyle(fontSize: 12),
              ),

              const SizedBox(height: 12),

              _bar('Sleep', 0.7, AshaColors.coral),
              _bar('Stress', 0.55, AshaColors.sun),
              _bar('Exercise', 0.3, AshaColors.mintDark),
              _bar('History', 0.85, AshaColors.lavenderDark),

              const SizedBox(height: 8),

              AshaCard(
                tint: AshaColors.lavender,
                child: const Text(
                  'Lower sleep this week nudged the estimate later than your usual average.',
                  style: TextStyle(fontSize: 12),
                ),
              ),

              Text(
                '👥 Women like you',
                style: Theme.of(context).textTheme.titleLarge,
              ),

              const SizedBox(height: 10),

              AshaCard(
                child: const Text(
                  'Similar age, BMI & stress profile typically cycle every 27–31 days.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}