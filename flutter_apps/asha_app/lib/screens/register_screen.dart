import 'package:flutter/material.dart';
import '../theme/asha_theme.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _auth = AuthService();

  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirm = TextEditingController();

  String? error;
  bool loading = false;

  // ==================================================
  // REGISTER
  // ==================================================

  Future<void> _register() async {
    final userName = name.text.trim();
    final userEmail = email.text.trim();
    final userPassword = password.text.trim();
    final userConfirm = confirm.text.trim();

    // Name validation
    if (userName.isEmpty) {
      setState(() {
        error = 'Please enter your name.';
      });
      return;
    }

    // Email validation
    if (userEmail.isEmpty) {
      setState(() {
        error = 'Please enter your email.';
      });
      return;
    }

    // Password validation
    if (userPassword.isEmpty) {
      setState(() {
        error = 'Please enter a password.';
      });
      return;
    }

    // Confirm password
    if (userPassword != userConfirm) {
      setState(() {
        error = 'Passwords do not match.';
      });
      return;
    }

    setState(() {
      loading = true;
      error = null;
    });

    try {
      await _auth.register(
        userEmail,
        userPassword,
        userName,
      );

      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        '/cycle-setup',
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
    name.dispose();
    email.dispose();
    password.dispose();
    confirm.dispose();
    super.dispose();
  }

  // ==================================================
  // UI
  // ==================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const SizedBox(height: 20),

              Text(
                'Create Account',
                style: Theme.of(context)
                    .textTheme
                    .displayLarge,
              ),

              const SizedBox(height: 8),

              const Text(
                'Let’s create your Asha profile 🌼',
                style: TextStyle(
                  color: AshaColors.slate,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 28),

              // NAME
              TextField(
                controller: name,
                textCapitalization:
                    TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'Enter your name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),

              const SizedBox(height: 14),

              // EMAIL
              TextField(
                controller: email,
                keyboardType:
                    TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter your email',
                  prefixIcon:
                      Icon(Icons.email_outlined),
                ),
              ),

              const SizedBox(height: 14),

              // PASSWORD
              TextField(
                controller: password,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  hintText: 'Create a password',
                  prefixIcon:
                      Icon(Icons.lock_outline),
                ),
              ),

              const SizedBox(height: 14),

              // CONFIRM PASSWORD
              TextField(
                controller: confirm,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  hintText: 'Enter password again',
                  prefixIcon:
                      Icon(Icons.lock_outline),
                ),
              ),

              // ERROR
              if (error != null)
                Padding(
                  padding:
                      const EdgeInsets.only(top: 12),
                  child: Text(
                    '⚠ $error',
                    style: const TextStyle(
                      color: AshaColors.alert,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // SIGN UP BUTTON
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
                      loading ? null : _register,
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
                          'Sign Up',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 12),

              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Already have an account? Sign In',
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