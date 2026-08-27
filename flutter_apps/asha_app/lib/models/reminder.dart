import 'package:flutter/material.dart';

class Reminder {
final int id;
final String title;
final TimeOfDay time;
bool enabled;

Reminder({required this.id, required this.title, required this.time, this.enabled = true});
}