import 'package:flutter/material.dart';
import '../services/health_profile_store.dart';
import '../theme/asha_theme.dart';

// ============================================================
// LAST PERIOD SCREEN — matches onboarding mockup
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

 // ============================================================
 // DATE FORMAT
 // ============================================================

 String _formatDate(DateTime date) {
 return '${date.day.toString().padLeft(2, '0')}/'
 '${date.month.toString().padLeft(2, '0')}/'
 '${date.year}';
 }

 // ============================================================
 // SELECT DATE — with validation
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
 lastDate: lastDate, // CRITICAL: Prevents future dates
 builder: (context, child) {
 return Theme(
 data: Theme.of(context).copyWith(
 colorScheme: const ColorScheme.light(
 primary: AshaColors.coral,
 ),
 ),
 child: child!,
 );
 },
 );

 if (picked == null) return;

 // Additional validation - double check date is not in future
 if (picked.isAfter(now)) {
 _showError('Please select a date that is not in the future');
 return;
 }

 setState(() {
 _selectedDate = picked;
 });

 // Update HealthProfileStore immediately
 HealthProfileStore.lastPeriodDate = picked;
 await HealthProfileStore.save();
 }

 // ============================================================
 // VALIDATE FORM
 // ============================================================

 bool _validateForm() {
 final now = DateTime.now();

 if (_selectedDate == null) {
 _showError('Please select your last period date');
 return false;
 }

 if (_selectedDate!.isAfter(now)) {
 _showError('Last period date cannot be in the future');
 return false;
 }

 final oneYearAgo = now.subtract(const Duration(days: 365));
 if (_selectedDate!.isBefore(oneYearAgo)) {
 _showError('Please select a date within the last year');
 return false;
 }

 return true;
 }

 void _showError(String message) {
 if (!mounted) return;

 ScaffoldMessenger.of(context).showSnackBar(
 SnackBar(
 content: Text(message),
 duration: const Duration(seconds: 2),
 backgroundColor: Colors.red,
 ),
 );
 }

 // ============================================================
 // ON NEXT PRESSED
 // ============================================================

 Future<void> _onNextPressed() async {
 if (!_validateForm()) return;

 try {
 HealthProfileStore.lastPeriodDate = _selectedDate;
 await HealthProfileStore.save();

 if (!mounted) return;

 Navigator.of(context).pop(_selectedDate);
 } catch (e) {
 _showError('Failed to save date. Please try again.');
 }
 }

 // ============================================================
 // BUILD
 // ============================================================

 @override
 Widget build(BuildContext context) {
 return Scaffold(
 backgroundColor: AshaColors.cream,
 body: SafeArea(
 child: Padding(
 padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 const Text(
 'When did your last\nperiod start?',
 style: TextStyle(
 color: AshaColors.ink,
 fontSize: 26,
 fontWeight: FontWeight.w700,
 height: 1.25,
 ),
 ),
 const SizedBox(height: 8),
 const Text(
 'This is what lets Asha predict your next date.',
 style: TextStyle(
 color: AshaColors.slate,
 fontSize: 13,
 ),
 ),
 const SizedBox(height: 28),
 _buildDateField(),
 const Spacer(),
 _buildNextButton(),
 ],
 ),
 ),
 ),
 );
 }

 // ============================================================
 // DATE FIELD
 // ============================================================

 Widget _buildDateField() {
 return InkWell(
 borderRadius: BorderRadius.circular(28),
 onTap: () => _selectDate(context),
 child: Container(
 padding: const EdgeInsets.symmetric(
 horizontal: 18,
 vertical: 16,
 ),
 decoration: BoxDecoration(
 color: Colors.white,
 borderRadius: BorderRadius.circular(28),
 ),
 child: Row(
 children: [
 const Icon(
 Icons.calendar_today_rounded,
 color: AshaColors.coral,
 size: 20,
 ),
 const SizedBox(width: 14),
 Expanded(
 child: Text(
 _selectedDate != null
 ? _formatDate(_selectedDate!)
 : 'Select a date',
 textAlign: TextAlign.right,
 style: TextStyle(
 color: _selectedDate != null
 ? AshaColors.ink
 : AshaColors.slate,
 fontSize: 15,
 fontWeight: FontWeight.w600,
 ),
 ),
 ),
 ],
 ),
 ),
 );
 }

 // ============================================================
 // NEXT BUTTON
 // ============================================================

 Widget _buildNextButton() {
 return SizedBox(
 width: double.infinity,
 child: ElevatedButton(
 onPressed: _onNextPressed,
 style: ElevatedButton.styleFrom(
 backgroundColor: AshaColors.ink,
 foregroundColor: Colors.white,
 elevation: 0,
 padding: const EdgeInsets.symmetric(vertical: 17),
 shape: RoundedRectangleBorder(
 borderRadius: BorderRadius.circular(30),
 ),
 ),
 child: const Text(
 'Next',
 style: TextStyle(
 fontSize: 15,
 fontWeight: FontWeight.w700,
 ),
 ),
 ),
 );
 }
}