import 'package:flutter/material.dart';
import '../theme/asha_theme.dart';
import '../models/reminder.dart';
import '../services/notification_service.dart';

class RemindersScreen extends StatefulWidget {
 const RemindersScreen({super.key});
 @override
 State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
 final List<Reminder> reminders = [
 Reminder(id: 1, title: 'Sleep reminder', time: const TimeOfDay(hour: 22, minute: 30)),
 Reminder(id: 2, title: 'Drink water', time: const TimeOfDay(hour: 12, minute: 0)),
 Reminder(id: 3, title: 'Log your symptoms', time: const TimeOfDay(hour: 20, minute: 0)),
 ];

 Future<void> _toggle(Reminder r, bool value) async {
 setState(() => r.enabled = value);
 if (value) {
 await NotificationService.scheduleDailyReminder(
 id: r.id, title: 'Asha', body: r.title, hour: r.time.hour, minute: r.time.minute,
 );
 } else {
 await NotificationService.cancel(r.id);
 }
 }

 Future<void> _pickTime(Reminder r) async {
 final picked = await showTimePicker(context: context, initialTime: r.time);
 if (picked != null) {
 setState(() {
 final index = reminders.indexOf(r);
 reminders[index] = Reminder(id: r.id, title: r.title, time: picked, enabled: r.enabled);
 });
 if (r.enabled) {
 await NotificationService.scheduleDailyReminder(
 id: r.id, title: 'Asha', body: r.title, hour: picked.hour, minute: picked.minute,
 );
 }
 }
 }

 Future<void> _addReminder() async {
 final controller = TextEditingController();
 final title = await showDialog<String>(
 context: context,
 builder: (context) => AlertDialog(
 title: const Text('New reminder'),
 content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'e.g. Take medicine')),
 actions: [
 TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
 TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Add')),
 ],
 ),
 );
 if (title == null || title.trim().isEmpty) return;
 final newId = DateTime.now().millisecondsSinceEpoch % 100000;
 final newReminder = Reminder(id: newId, title: title.trim(), time: const TimeOfDay(hour: 9, minute: 0));
 setState(() => reminders.add(newReminder));
 await NotificationService.scheduleDailyReminder(
 id: newId, title: 'Asha', body: newReminder.title, hour: 9, minute: 0,
 );
 }

 @override
 Widget build(BuildContext context) {
 return Scaffold(
 appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('Reminders')),
 floatingActionButton: FloatingActionButton(
 backgroundColor: AshaColors.coral,
 onPressed: _addReminder,
 child: const Icon(Icons.add, color: Colors.white),
 ),
 body: SafeArea(
 child: ListView.builder(
 padding: const EdgeInsets.all(20),
 itemCount: reminders.length,
 itemBuilder: (_, i) {
 final r = reminders[i];
 return AshaCard(
 child: Row(
 children: [
 Expanded(
 child: GestureDetector(
 onTap: () => _pickTime(r),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(r.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
 const SizedBox(height: 4),
 Text(r.time.format(context), style: const TextStyle(fontSize: 12, color: AshaColors.slate)),
 ],
 ),
 ),
 ),
 Switch(
 value: r.enabled,
 activeColor: AshaColors.coral,
 onChanged: (v) => _toggle(r, v),
 ),
 ],
 ),
 );
 },
 ),
 ),
 );
 }
}