import 'package:flutter/material.dart';

import '../theme/asha_theme.dart';
import '../services/auth_service.dart';

import 'personal_information_screen.dart';
import 'cycle_health_settings_screen.dart';
import 'privacy_screen.dart';
import 'help_support_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Profile'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ==================================================
            // PROFILE HEADER
            // ==================================================

            Center(
              child: Column(
                children: [
                  const AshaMascot(size: 80),

                  const SizedBox(height: 8),

                  Text(
                    auth.currentUser?.email ?? 'Vittika',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ==================================================
            // PERSONAL INFORMATION
            // ==================================================

            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const PersonalInformationScreen(),
                  ),
                );
              },
              child: const AshaCard(
                child: ListTile(
                  leading: Icon(
                    Icons.person_outline,
                  ),
                  title: Text(
                    'Personal Information',
                  ),
                  subtitle: Text(
                    'Manage your personal details',
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                  ),
                ),
              ),
            ),

            // ==================================================
            // CYCLE & HEALTH SETTINGS
            // ==================================================

            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const CycleHealthSettingsScreen(),
                  ),
                );
              },
              child: const AshaCard(
                child: ListTile(
                  leading: Icon(
                    Icons.calendar_today_outlined,
                  ),
                  title: Text(
                    'Cycle & Health Settings',
                  ),
                  subtitle: Text(
                    'Manage cycle and wellness information',
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                  ),
                ),
              ),
            ),

            // ==================================================
            // REMINDERS
            // ==================================================

            GestureDetector(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/reminders',
                );
              },
              child: const AshaCard(
                child: ListTile(
                  leading: Icon(
                    Icons.notifications_none,
                  ),
                  title: Text(
                    'Reminders',
                  ),
                  subtitle: Text(
                    'Manage your health reminders',
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                  ),
                ),
              ),
            ),

            // ==================================================
            // PRIVACY
            // ==================================================

            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const PrivacyScreen(),
                  ),
                );
              },
              child: const AshaCard(
                child: ListTile(
                  leading: Icon(
                    Icons.lock_outline,
                  ),
                  title: Text(
                    'Privacy',
                  ),
                  subtitle: Text(
                    'Learn how your information is handled',
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                  ),
                ),
              ),
            ),

            // ==================================================
            // HELP & SUPPORT
            // ==================================================

            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const HelpSupportScreen(),
                  ),
                );
              },
              child: const AshaCard(
                child: ListTile(
                  leading: Icon(
                    Icons.help_outline,
                  ),
                  title: Text(
                    'Help & Support',
                  ),
                  subtitle: Text(
                    'FAQs and help with ASHA',
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ==================================================
            // LOG OUT
            // ==================================================

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AshaColors.coral,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () async {
                  try {
                    await auth.logout();

                    if (!context.mounted) return;

                    Navigator.of(context)
                        .pushNamedAndRemoveUntil(
                      '/login',
                      (route) => false,
                    );
                  } catch (e) {
                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      SnackBar(
                        content: Text(
                          'Logout failed: $e',
                        ),
                      ),
                    );
                  }
                },
                child: const Text(
                  'Log Out',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}