import 'package:flutter/material.dart';
import '../theme/asha_theme.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _auth = AuthService();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirm = TextEditingController();
  String? error;
  bool loading = false;

  Future<void> _register() async {
    if (password.text != confirm.text) { setState(() => error = 'Passwords do not match.'); return; }
    setState(() { loading = true; error = null; });
    try {
      await _auth.register(email.text.trim(), password.text.trim());
      if (mounted) Navigator.pushReplacementNamed(context, '/cycle-setup');
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Create Account', style: Theme.of(context).textTheme.displayLarge),
              const SizedBox(height: 20),
              TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
              const SizedBox(height: 12),
              TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
              const SizedBox(height: 12),
              TextField(controller: confirm, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm Password')),
              if (error != null)
                Padding(padding: const EdgeInsets.only(top: 8), child: Text('⚠ $error', style: const TextStyle(color: AshaColors.alert, fontSize: 12, fontWeight: FontWeight.w600))),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AshaColors.coral, padding: const EdgeInsets.all(16)),
                  onPressed: loading ? null : _register,
                  child: const Text('Sign Up', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}