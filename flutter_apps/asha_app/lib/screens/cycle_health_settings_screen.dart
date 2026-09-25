import 'package:flutter/material.dart';

import '../theme/asha_theme.dart';
import '../services/health_profile_store.dart';

class CycleHealthSettingsScreen extends StatefulWidget {
  const CycleHealthSettingsScreen({super.key});

  @override
  State<CycleHealthSettingsScreen> createState() =>
      _CycleHealthSettingsScreenState();
}

class _CycleHealthSettingsScreenState
    extends State<CycleHealthSettingsScreen> {
  late TextEditingController _cycleLengthController;
  late TextEditingController _periodLengthController;

  int _stress = 3;
  int _exercise = 1;
  double _sleep = 7;
  String _diet = 'Low Carb';

  DateTime? _lastPeriodDate;

  @override
  void initState() {
    super.initState();

    _cycleLengthController = TextEditingController(
      text: HealthProfileStore.cycleLength.toString(),
    );

    _periodLengthController = TextEditingController(
      text: HealthProfileStore.periodLength?.toString() ?? '',
    );

    _stress = HealthProfileStore.stress;
    _exercise = HealthProfileStore.exerciseFrequency;
    _sleep = HealthProfileStore.sleepHours;
    _diet = HealthProfileStore.diet;
    _lastPeriodDate = HealthProfileStore.lastPeriodDate;
  }

  @override
  void dispose() {
    _cycleLengthController.dispose();
    _periodLengthController.dispose();
    super.dispose();
  }

  Future<void> _selectLastPeriod() async {
    final now = DateTime.now();

    final selected = await showDatePicker(
      context: context,
      initialDate: _lastPeriodDate ?? now,
      firstDate: DateTime(2020),
      lastDate: now,
      helpText: 'Select your last period date',
    );

    if (selected == null) return;

    setState(() {
      _lastPeriodDate = selected;
    });
  }

  Future<void> _saveSettings() async {
    final cycleLength =
        int.tryParse(_cycleLengthController.text.trim());

    final periodLength =
        int.tryParse(_periodLengthController.text.trim());

    if (cycleLength == null ||
        cycleLength < 15 ||
        cycleLength > 60) {
      _showMessage(
        'Cycle length should be between 15 and 60 days.',
      );
      return;
    }

    if (periodLength != null &&
        (periodLength < 1 || periodLength > 15)) {
      _showMessage(
        'Period length should be between 1 and 15 days.',
      );
      return;
    }

    HealthProfileStore.cycleLength = cycleLength;
    HealthProfileStore.periodLength = periodLength;
    HealthProfileStore.stress = _stress;
    HealthProfileStore.exerciseFrequency = _exercise;
    HealthProfileStore.sleepHours = _sleep;
    HealthProfileStore.diet = _diet;
    HealthProfileStore.lastPeriodDate = _lastPeriodDate;

    await HealthProfileStore.save();

    if (!mounted) return;

    _showMessage('Cycle & health settings saved.');

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

  String _exerciseLabel() {
    if (_exercise == 0) return 'Low';
    if (_exercise == 1) return 'Moderate';
    return 'High';
  }

  String _stressLabel() {
    if (_stress == 1) return 'Very Low';
    if (_stress == 2) return 'Low';
    if (_stress == 3) return 'Moderate';
    if (_stress == 4) return 'High';
    return 'Very High';
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Not set';
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Cycle & Health Settings'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          children: [
            const Text(
              'Cycle Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AshaColors.ink,
              ),
            ),

            const SizedBox(height: 10),

            AshaCard(
              child: Column(
                children: [
                  TextField(
                    controller: _cycleLengthController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Average cycle length',
                      hintText: 'Example: 28',
                      prefixIcon: Icon(
                        Icons.calendar_month_outlined,
                      ),
                      suffixText: 'days',
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: _periodLengthController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Period length',
                      hintText: 'Example: 5',
                      prefixIcon: Icon(
                        Icons.water_drop_outlined,
                      ),
                      suffixText: 'days',
                    ),
                  ),

                  const SizedBox(height: 16),

                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.event_outlined,
                      color: AshaColors.coral,
                    ),
                    title: const Text(
                      'Last period date',
                    ),
                    subtitle: Text(
                      _formatDate(_lastPeriodDate),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                    ),
                    onTap: _selectLastPeriod,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 26),

            const Text(
              'Wellness Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AshaColors.ink,
              ),
            ),

            const SizedBox(height: 10),

            AshaCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Stress Level',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    _stressLabel(),
                    style: const TextStyle(
                      color: AshaColors.coral,
                    ),
                  ),

                  Slider(
                    value: _stress.toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    activeColor: AshaColors.coral,
                    onChanged: (value) {
                      setState(() {
                        _stress = value.round();
                      });
                    },
                  ),

                  const Divider(),

                  const SizedBox(height: 8),

                  const Text(
                    'Exercise Level',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 8),

                  DropdownButtonFormField<int>(
                    value: _exercise,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(
                        Icons.directions_run_outlined,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 0,
                        child: Text('Low'),
                      ),
                      DropdownMenuItem(
                        value: 1,
                        child: Text('Moderate'),
                      ),
                      DropdownMenuItem(
                        value: 2,
                        child: Text('High'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;

                      setState(() {
                        _exercise = value;
                      });
                    },
                  ),

                  const SizedBox(height: 20),

                  Text(
                    'Current level: ${_exerciseLabel()}',
                    style: TextStyle(
                      fontSize: 13,
                      color: AshaColors.ink.withOpacity(0.65),
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'Average Sleep',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    '${_sleep.toStringAsFixed(1)} hours',
                    style: const TextStyle(
                      color: AshaColors.coral,
                    ),
                  ),

                  Slider(
                    value: _sleep,
                    min: 3,
                    max: 12,
                    divisions: 18,
                    activeColor: AshaColors.coral,
                    onChanged: (value) {
                      setState(() {
                        _sleep = value;
                      });
                    },
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'Diet',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 8),

                  DropdownButtonFormField<String>(
                    value: _diet,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(
                        Icons.restaurant_outlined,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Low Carb',
                        child: Text('Low Carb'),
                      ),
                      DropdownMenuItem(
                        value: 'Balanced',
                        child: Text('Balanced'),
                      ),
                      DropdownMenuItem(
                        value: 'Vegetarian',
                        child: Text('Vegetarian'),
                      ),
                      DropdownMenuItem(
                        value: 'Vegan',
                        child: Text('Vegan'),
                      ),
                      DropdownMenuItem(
                        value: 'Other',
                        child: Text('Other'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;

                      setState(() {
                        _diet = value;
                      });
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

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
                onPressed: _saveSettings,
                child: const Text(
                  'Save Settings',
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