import 'package:flutter/material.dart';
import '../theme/asha_theme.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final periodDays = {4, 5, 6, 7};
    final fertileDays = {19, 20, 21};
    const today = 22;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('June 2026', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 30,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
              itemBuilder: (_, i) {
                final day = i + 1;
                Color? bg; Color fg = AshaColors.ink;
                if (periodDays.contains(day)) { bg = AshaColors.coral; fg = Colors.white; }
                else if (fertileDays.contains(day)) { bg = AshaColors.sky; }
                return Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(shape: BoxShape.circle, color: bg, border: day == today ? Border.all(color: AshaColors.ink, width: 2) : null),
                  child: Center(child: Text('$day', style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w600))),
                );
              },
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: AshaCard(tint: AshaColors.mint, child: const Text('NEXT PERIOD\n4 Jul', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)))),
              const SizedBox(width: 12),
              Expanded(child: AshaCard(tint: AshaColors.sky, child: const Text('FERTILE\n19–21 Jun', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)))),
            ]),
          ],
        ),
      ),
    );
  }
}