import 'package:flutter/material.dart';
import '../theme/asha_theme.dart';
import 'home_screen.dart';
import 'calendar_screen.dart';
import 'chat_screen.dart';
import 'library_screen.dart';
import 'profile_screen.dart';

class RootShell extends StatefulWidget {
const RootShell({super.key});
@override
State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
int _index = 0;
final _screens = const [HomeScreen(), CalendarScreen(), ChatScreen(), LibraryScreen(), ProfileScreen()];

void _showLogMenu(BuildContext context) {
showModalBottomSheet(
context: context,
shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
builder: (sheetContext) => SafeArea(
child: Wrap(
children: [
ListTile(
leading: const Icon(Icons.edit_note, color: AshaColors.coral),
title: const Text('Log symptoms'),
onTap: () {
Navigator.pop(sheetContext);
Navigator.pushNamed(context, '/quick-log');
},
),
ListTile(
leading: const Icon(Icons.water_drop_outlined, color: AshaColors.coral),
title: const Text('Log discharge'),
onTap: () {
Navigator.pop(sheetContext);
Navigator.pushNamed(context, '/discharge');
},
),
ListTile(
leading: const Icon(Icons.calendar_today_outlined, color: AshaColors.coral),
title: const Text('Update last period date'),
onTap: () {
Navigator.pop(sheetContext);
Navigator.pushNamed(context, '/update-last-period').then((_) => setState(() {}));
},
),
],
),
),
);
}

@override
Widget build(BuildContext context) {
return Scaffold(
body: _screens[_index],
floatingActionButton: FloatingActionButton(
onPressed: () => _showLogMenu(context),
backgroundColor: AshaColors.coral,
shape: const CircleBorder(),
child: const Icon(Icons.add, color: Colors.white),
),
floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
bottomNavigationBar: BottomAppBar(
shape: const CircularNotchedRectangle(),
color: Colors.white,
child: Row(
mainAxisAlignment: MainAxisAlignment.spaceAround,
children: [
_navItem(Icons.home_rounded, 'Home', 0),
_navItem(Icons.calendar_month_rounded, 'Tracker', 1),
const SizedBox(width: 40),
_navItem(Icons.chat_bubble_rounded, 'Asha', 2),
_navItem(Icons.menu_book_rounded, 'Health', 3),
_navItem(Icons.person_rounded, 'Profile', 4),
],
),
),
);
}

Widget _navItem(IconData icon, String label, int i) {
final active = _index == i;
return IconButton(
onPressed: () => setState(() => _index = i),
icon: Column(mainAxisSize: MainAxisSize.min, children: [
Icon(icon, color: active ? AshaColors.coral : AshaColors.slate, size: 22),
Text(label, style: TextStyle(fontSize: 9, color: active ? AshaColors.coral : AshaColors.slate)),
]),
);
}
}
