import 'package:flutter/material.dart';
import '../theme/asha_theme.dart';
import 'library_screen.dart';

class ArticleScreen extends StatelessWidget {
const ArticleScreen({super.key});
@override
Widget build(BuildContext context) {
final title = ModalRoute.of(context)?.settings.arguments as String? ?? 'Article';
final points = LibraryScreen.articleContent[title] ?? ['Content coming soon.'];

return Scaffold(
appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
body: SafeArea(
child: SingleChildScrollView(
padding: const EdgeInsets.all(20),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(title, style: Theme.of(context).textTheme.displayLarge),
const SizedBox(height: 6),
const Text('3 min read', style: TextStyle(fontSize: 12, color: AshaColors.slate)),
const SizedBox(height: 18),
...points.map((p) => Padding(
padding: const EdgeInsets.only(bottom: 14),
child: Row(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Container(
margin: const EdgeInsets.only(top: 6, right: 10),
width: 6, height: 6,
decoration: const BoxDecoration(color: AshaColors.coral, shape: BoxShape.circle),
),
Expanded(child: Text(p, style: const TextStyle(fontSize: 13, height: 1.5))),
],
),
)),
const SizedBox(height: 12),
AshaCard(
tint: AshaColors.peach,
child: const Text(
'This is general information, not medical advice. If something feels off or persistent, talk to a doctor.',
style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
),
),
],
),
),
),
);
}
}
