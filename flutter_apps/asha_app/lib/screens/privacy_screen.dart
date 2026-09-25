import 'package:flutter/material.dart';

import '../theme/asha_theme.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  Widget _privacyCard({
    required IconData icon,
    required String title,
    required String text,
  }) {
    return AshaCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AshaColors.peach,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AshaColors.coral,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: AshaColors.ink.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Privacy'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          children: [
            const Center(
              child: Icon(
                Icons.shield_outlined,
                size: 70,
                color: AshaColors.coral,
              ),
            ),

            const SizedBox(height: 14),

            const Text(
              'Your Privacy Matters',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AshaColors.ink,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'ASHA is designed to keep your personal health experience private and under your control.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: AshaColors.ink.withOpacity(0.65),
              ),
            ),

            const SizedBox(height: 26),

            _privacyCard(
              icon: Icons.storage_outlined,
              title: 'Your Profile Information',
              text:
                  'Information such as your name, age, cycle information and wellness preferences is used to personalize your ASHA experience.',
            ),

            const SizedBox(height: 12),

            _privacyCard(
              icon: Icons.phone_android_outlined,
              title: 'Local App Data',
              text:
                  'ASHA stores profile settings on your device so your information can remain available when you use the app.',
            ),

            const SizedBox(height: 12),

            _privacyCard(
              icon: Icons.lock_outline,
              title: 'Account Access',
              text:
                  'Your account uses the authentication system configured for ASHA. Keep your login credentials private and do not share your password.',
            ),

            const SizedBox(height: 12),

            _privacyCard(
              icon: Icons.smart_toy_outlined,
              title: 'AI Assistant',
              text:
                  'When you use Asha AI, your question is sent to the app backend so that Asha can generate a response. Avoid entering unnecessary personal information in chat.',
            ),

            const SizedBox(height: 12),

            _privacyCard(
              icon: Icons.medical_information_outlined,
              title: 'Health Guidance',
              text:
                  'ASHA provides general wellness and educational information. It is not a replacement for professional medical advice or diagnosis.',
            ),

            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AshaColors.peach.withOpacity(0.55),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AshaColors.coral,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'For your safety, avoid sharing passwords, financial information or other highly sensitive information in the AI chat.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: AshaColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}