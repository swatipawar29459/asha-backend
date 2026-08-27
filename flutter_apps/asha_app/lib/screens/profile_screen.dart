import 'package:flutter/material.dart';
import '../theme/asha_theme.dart';
import '../services/auth_service.dart';

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
const SizedBox(height: 20),
GestureDetector(
onTap: () => ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('Personal Information screen coming soon')),
),
child: const AshaCard(
child: ListTile(
leading: Icon(Icons.person_outline),
title: Text('Personal Information'),
trailing: Icon(Icons.chevron_right),
),
),
),
GestureDetector(
onTap: () => ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('Cycle & Health Settings coming soon')),
),
child: const AshaCard(
child: ListTile(
leading: Icon(Icons.calendar_today_outlined),
title: Text('Cycle & Health Settings'),
trailing: Icon(Icons.chevron_right),
),
),
),
GestureDetector(
onTap: () => Navigator.pushNamed(context, '/reminders'),
child: const AshaCard(
child: ListTile(
leading: Icon(Icons.notifications_none),
title: Text('Reminders'),
trailing: Icon(Icons.chevron_right),
),
),
),
GestureDetector(
onTap: () => ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('Privacy & Help Support coming soon')),
),
child: const AshaCard(
child: ListTile(
leading: Icon(Icons.lock_outline),
title: Text('Privacy & Help Support'),
trailing: Icon(Icons.chevron_right),
),
),
),
const SizedBox(height: 12),
SizedBox(
width: double.infinity,
child: ElevatedButton(
style: ElevatedButton.styleFrom(
backgroundColor: AshaColors.coral,
padding: const EdgeInsets.all(16),
),
onPressed: () async {
try {
await auth.logout();
if (!context.mounted) return;
Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
} catch (e) {
if (!context.mounted) return;
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text('Logout failed: $e')),
);
}
},
child: const Text(
'Log Out',
style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
),
),
),
],
),
),
);
}
}