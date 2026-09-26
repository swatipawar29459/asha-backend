import 'package:flutter/material.dart';
import '../services/health_profile_store.dart';

// ============================================================
// LAST PERIOD SCREEN - CORRECTED & COMPLETE
// ============================================================

class LastPeriodScreen extends StatefulWidget {
  const LastPeriodScreen({Key? key}) : super(key: key);

  @override
  State<LastPeriodScreen> createState() => _LastPeriodScreenState();
}

class _LastPeriodScreenState extends State<LastPeriodScreen> {
  // ============================================================
  // STATE VARIABLES
  // ============================================================
  
  late DateTime? _selectedDate = HealthProfileStore.lastPeriodDate;
  late TextEditingController _dateController;

  @override
  void initState() {
    super.initState();
    
    _dateController = TextEditingController();
    
    // Set initial date if exists
    if (_selectedDate != null) {
      _dateController.text = 
        '${_selectedDate!.day.toString().padLeft(2, '0')}/'
        '${_selectedDate!.month.toString().padLeft(2, '0')}/'
        '${_selectedDate!.year}';
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  // ============================================================
  // METHOD 1: _selectDate - UPDATED WITH DATE VALIDATION
  // ============================================================

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    
    // Don't allow future dates - max date is TODAY
    final firstDate = DateTime(now.year - 5);
    final lastDate = now;
    
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: firstDate,
      lastDate: lastDate, // ✅ CRITICAL: Prevents future dates
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFE07B4D), // Asha coral color
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      // Additional validation - double check date is not in future
      if (picked.isAfter(now)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select a date that is not in the future'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      // Update state with selected date
      setState(() {
        _selectedDate = picked;
        _dateController.text = 
          '${picked.day.toString().padLeft(2, '0')}/'
          '${picked.month.toString().padLeft(2, '0')}/'
          '${picked.year}';
      });

      // Also update HealthProfileStore immediately
      HealthProfileStore.lastPeriodDate = picked;
      await HealthProfileStore.save();

      print('✅ Last period date set to: $picked');
    }
  }

  // ============================================================
  // METHOD 2: _validateForm - VALIDATE ALL FIELDS
  // ============================================================

  bool _validateForm() {
    final now = DateTime.now();

    // Check last period date is selected
    if (_selectedDate == null) {
      _showError('Please select your last period date');
      return false;
    }

    // Check date is not in future
    if (_selectedDate!.isAfter(now)) {
      _showError('Last period date cannot be in the future');
      return false;
    }

    // Check if date is too old (more than 1 year ago)
    final oneYearAgo = now.subtract(const Duration(days: 365));
    if (_selectedDate!.isBefore(oneYearAgo)) {
      _showError('Please select a date within the last year');
      return false;
    }

    return true;
  }

  // ============================================================
  // METHOD 3: _showError - HELPER METHOD
  // ============================================================

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // METHOD 4: _showSuccess - HELPER METHOD
  // ============================================================

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // ============================================================
  // METHOD 5: onSavePressed - SAVE WITH VALIDATION
  // ============================================================

  Future<void> onSavePressed() async {
    // Validate form first
    if (!_validateForm()) {
      return; // Validation failed, error shown
    }

    if (_selectedDate == null) {
      _showError('Please select a last period date');
      return;
    }

    try {
      // Save the date to HealthProfileStore
      HealthProfileStore.lastPeriodDate = _selectedDate;
      await HealthProfileStore.save();

      print('✅ Last period date saved: $_selectedDate');

      _showSuccess('Last period date saved successfully!');

      // Optional: Navigate to next screen or pop
      // await Future.delayed(const Duration(seconds: 1));
      // if (mounted) {
      //   Navigator.of(context).pushNamed('/next-screen');
      // }

    } catch (e) {
      print('❌ Error saving date: $e');
      _showError('Failed to save date. Please try again.');
    }
  }

  // ============================================================
  // METHOD 6: onSkipPressed - SKIP THIS STEP
  // ============================================================

  Future<void> onSkipPressed() async {
    try {
      // Don't set lastPeriodDate, user can set it later
      print('⏭️  Skipped last period date setup');
      
      _showSuccess('You can update this later in your profile');

      // Navigate to next screen
      // await Future.delayed(const Duration(seconds: 1));
      // if (mounted) {
      //   Navigator.of(context).pushNamed('/next-screen');
      // }

    } catch (e) {
      print('❌ Error in skip: $e');
    }
  }

  // ============================================================
  // BUILD METHOD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('When did your last period start?'),
        backgroundColor: const Color(0xFFE07B4D),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instruction text
            const Text(
              'Select the date when your last period started',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Date picker button
            GestureDetector(
              onTap: () => _selectDate(context),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFFE07B4D),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      color: Color(0xFFE07B4D),
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _dateController,
                        enabled: false,
                        decoration: InputDecoration(
                          hintText: 'Select a date',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                          ),
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Info box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE07B4D).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '💡 Tip: This helps us predict your next period and fertile window. You can update this anytime in your profile.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFFE07B4D),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(height: 48),

            // Save button
            ElevatedButton(
              onPressed: onSavePressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE07B4D),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Skip button
            TextButton(
              onPressed: onSkipPressed,
              child: const Text(
                'Skip for now',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFFE07B4D),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}