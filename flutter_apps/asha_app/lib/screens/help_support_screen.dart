
import 'package:flutter/material.dart';

import '../theme/asha_theme.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  void _showAnswer(
    BuildContext context,
    String title,
    String answer,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(
            22,
            20,
            22,
            30,
          ),
          decoration: const BoxDecoration(
            color: AshaColors.cream,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: AshaColors.ink,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                answer,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AshaColors.ink.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AshaColors.coral,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _faq(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String answer,
  }) {
    return AshaCard(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: AshaColors.peach,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: AshaColors.coral,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
        ),
        onTap: () {
          _showAnswer(
            context,
            title,
            answer,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Help & Support'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          children: [
            const Center(
              child: AshaMascot(size: 75),
            ),

            const SizedBox(height: 12),

            const Text(
              'How can we help?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AshaColors.ink,
              ),
            ),

            const SizedBox(height: 7),

            Text(
              'Find quick answers about using ASHA.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AshaColors.ink.withValues(alpha: 0.65),
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              'Common Questions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AshaColors.ink,
              ),
            ),

            const SizedBox(height: 10),

            _faq(
              context,
              icon: Icons.calendar_month_outlined,
              title: 'How does cycle prediction work?',
              answer:
                  'ASHA uses your saved cycle information and last period date to estimate your next period and fertile window. Predictions are estimates and may change as you log new information.',
            ),

            const SizedBox(height: 10),

            _faq(
              context,
              icon: Icons.notifications_none,
              title: 'Why am I not receiving reminders?',
              answer:
                  'Check that notifications are enabled for ASHA on your phone. Also make sure your cycle information and reminder settings are configured correctly.',
            ),

            const SizedBox(height: 10),

            _faq(
              context,
              icon: Icons.smart_toy_outlined,
              title: 'What can I ask Asha AI?',
              answer:
                  'You can ask Asha about periods, menstrual cycles, ovulation, PMS, common symptoms, self-care and general women’s wellness information.',
            ),

            const SizedBox(height: 10),

            _faq(
              context,
              icon: Icons.medical_services_outlined,
              title: 'Is Asha AI a doctor?',
              answer:
                  'No. Asha provides general educational and wellness guidance. If you have severe, persistent, unusual or concerning symptoms, consult a qualified healthcare professional.',
            ),

            const SizedBox(height: 10),

            _faq(
              context,
              icon: Icons.location_on_outlined,
              title: 'How does Find Doctor work?',
              answer:
                  'Find Doctor can use a location you provide to search for nearby healthcare places. Location access is used for the search rather than for continuously tracking you.',
            ),

            const SizedBox(height: 26),

            AshaCard(
              child: Column(
                children: [
                  const Icon(
                    Icons.support_agent_outlined,
                    size: 40,
                    color: AshaColors.coral,
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'Need more help?',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 7),

                  Text(
                    'If something is not working, note the screen name and the problem you see. This will make it easier for your project support team to troubleshoot it.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: AshaColors.ink.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Center(
              child: Text(
                'ASHA • Your Health. Your Journey.',
                style: TextStyle(
                  fontSize: 12,
                  color: AshaColors.ink.withValues(alpha: 0.55),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

