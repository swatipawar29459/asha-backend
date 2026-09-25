import 'package:flutter/material.dart';

import '../theme/asha_theme.dart';
import '../services/health_profile_store.dart';

class PersonalInformationScreen extends StatefulWidget {
  const PersonalInformationScreen({super.key});

  @override
  State<PersonalInformationScreen> createState() =>
      _PersonalInformationScreenState();
}

class _PersonalInformationScreenState
    extends State<PersonalInformationScreen> {
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _bmiController;

  int _pcos = 0;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: HealthProfileStore.userName,
    );

    _ageController = TextEditingController(
      text: HealthProfileStore.age?.toString() ?? '',
    );

    _bmiController = TextEditingController(
      text: HealthProfileStore.bmi?.toStringAsFixed(1) ?? '',
    );

    _pcos = HealthProfileStore.pcos;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _bmiController.dispose();
    super.dispose();
  }

  Future<void> _saveInformation() async {
    final name = _nameController.text.trim();
    final ageText = _ageController.text.trim();
    final bmiText = _bmiController.text.trim();

    if (name.isEmpty) {
      _showMessage('Please enter your name.');
      return;
    }

    int? age;

    if (ageText.isNotEmpty) {
      age = int.tryParse(ageText);

      if (age == null || age < 10 || age > 100) {
        _showMessage('Please enter a valid age.');
        return;
      }
    }

    double? bmi;

    if (bmiText.isNotEmpty) {
      bmi = double.tryParse(bmiText);

      if (bmi == null || bmi <= 0 || bmi > 100) {
        _showMessage('Please enter a valid BMI.');
        return;
      }
    }

    HealthProfileStore.userName = name;
    HealthProfileStore.age = age;
    HealthProfileStore.bmi = bmi;
    HealthProfileStore.pcos = _pcos;

    await HealthProfileStore.save();

    if (!mounted) return;

    _showMessage('Personal information saved successfully.');

    Navigator.pop(context, true);
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _pcosText() {
    if (_pcos == 1) {
      return 'Yes';
    }

    return 'No';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Personal Information'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          children: [
            // --------------------------------------------------
            // HEADER
            // --------------------------------------------------

            Center(
              child: Column(
                children: [
                  const AshaMascot(size: 75),

                  const SizedBox(height: 10),

                  Text(
                    'Your Personal Information',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AshaColors.ink,
                        ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'Keep your information updated for a more '
                    'personalized ASHA experience.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(
                          color: AshaColors.ink.withOpacity(0.65),
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // --------------------------------------------------
            // BASIC INFORMATION
            // --------------------------------------------------

            const Text(
              'Basic Information',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AshaColors.ink,
              ),
            ),

            const SizedBox(height: 10),

            AshaCard(
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      hintText: 'Enter your name',
                      prefixIcon: Icon(
                        Icons.person_outline,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Age',
                      hintText: 'Enter your age',
                      prefixIcon: Icon(
                        Icons.cake_outlined,
                      ),
                      suffixText: 'years',
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: _bmiController,
                    keyboardType:
                        const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'BMI',
                      hintText: 'Enter your BMI',
                      prefixIcon: Icon(
                        Icons.monitor_weight_outlined,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --------------------------------------------------
            // HEALTH INFORMATION
            // --------------------------------------------------

            const Text(
              'Health Information',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AshaColors.ink,
              ),
            ),

            const SizedBox(height: 10),

            AshaCard(
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AshaColors.peach,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.favorite_outline,
                        color: AshaColors.coral,
                      ),
                    ),
                    title: const Text(
                      'PCOS',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: const Text(
                      'Do you have PCOS?',
                    ),
                    trailing: DropdownButton<int>(
                      value: _pcos,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(
                          value: 0,
                          child: Text('No'),
                        ),
                        DropdownMenuItem(
                          value: 1,
                          child: Text('Yes'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;

                        setState(() {
                          _pcos = value;
                        });
                      },
                    ),
                  ),

                  const Divider(),

                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AshaColors.peach,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.info_outline,
                        color: AshaColors.coral,
                      ),
                    ),
                    title: const Text(
                      'Current PCOS status',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      _pcosText(),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --------------------------------------------------
            // INFORMATION NOTE
            // --------------------------------------------------

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AshaColors.peach.withOpacity(0.55),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lock_outline,
                    color: AshaColors.coral,
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      'Your information is used to personalize '
                      'your ASHA experience and health insights.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: AshaColors.ink.withOpacity(0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // --------------------------------------------------
            // SAVE BUTTON
            // --------------------------------------------------

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AshaColors.coral,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                onPressed: _saveInformation,
                child: const Text(
                  'Save Changes',
                  style: TextStyle(
                    fontSize: 15,
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