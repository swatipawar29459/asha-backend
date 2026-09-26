import 'package:flutter/material.dart';
import '../theme/asha_theme.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  final email = TextEditingController();
  final password = TextEditingController();

  String? error;
  bool loading = false;

  Future<void> _signIn() async {
    if (email.text.trim().isEmpty ||
        password.text.trim().isEmpty) {
      setState(() {
        error = 'Please enter your email and password.';
      });
      return;
    }

    setState(() {
      loading = true;
      error = null;
    });

    try {
      await AuthService.login(
        email.text.trim(),
        password.text.trim(),
      );

      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        '/home',
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [

              const SizedBox(height: 30),

              Text(
                'Sign In',
                style: Theme.of(context)
                    .textTheme
                    .displayLarge,
              ),

              const SizedBox(height: 8),

              const Text(
                'Welcome back to Asha 🌼',
                style: TextStyle(
                  color: AshaColors.slate,
                ),
              ),

              const SizedBox(height: 28),

              TextField(
                controller: email,
                keyboardType:
                    TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon:
                      Icon(Icons.email_outlined),
                ),
              ),

              const SizedBox(height: 14),

              TextField(
                controller: password,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon:
                      Icon(Icons.lock_outline),
                ),
              ),

              if (error != null)
                Padding(
                  padding:
                      const EdgeInsets.only(top: 10),
                  child: Text(
                    '⚠ $error',
                    style: const TextStyle(
                      color: AshaColors.alert,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              const SizedBox(height: 22),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        AshaColors.coral,
                    padding:
                        const EdgeInsets.all(16),
                  ),
                  onPressed:
                      loading ? null : _signIn,
                  child: loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Sign In',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 10),

              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/register',
                    );
                  },
                  child: const Text(
                    "Don't have an account? Register",
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}