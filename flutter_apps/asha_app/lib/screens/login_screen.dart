import 'package:flutter/material.dart';
import '../theme/asha_theme.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = AuthService();
  final email = TextEditingController();
  final password = TextEditingController();
  String? error;
  bool loading = false;

  Future<void> _signIn() async {
    setState(() { loading = true; error = null; });
    try {
      await _auth.login(email.text.trim(), password.text.trim());
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
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
              Text('Sign In', style: Theme.of(context).textTheme.displayLarge),
              const SizedBox(height: 20),
              TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
              const SizedBox(height: 12),
              TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
              if (error != null)
                Padding(padding: const EdgeInsets.only(top: 8), child: Text('⚠ $error', style: const TextStyle(color: AshaColors.alert, fontSize: 12, fontWeight: FontWeight.w600))),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AshaColors.coral, padding: const EdgeInsets.all(16)),
                  onPressed: loading ? null : _signIn,
                  child: loading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Sign In', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              TextButton(onPressed: () => Navigator.pushNamed(context, '/register'), child: const Text("Don't have an account? Register")),
            ],
          ),
        ),
      ),
    );
  }
}