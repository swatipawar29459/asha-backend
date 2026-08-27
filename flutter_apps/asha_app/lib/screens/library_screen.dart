import 'package:flutter/material.dart';
import '../theme/asha_theme.dart';

class LibraryScreen extends StatefulWidget {
const LibraryScreen({super.key});

static const categories = ['Teen Health', 'Reproductive', 'PCOS', 'Nutrition', 'Mental Health'];

static const articlesByCategory = {
'Teen Health': ["First period basics — what's normal", 'Talking to a guardian about your cycle'],
'Reproductive': ['Understanding ovulation', 'Fertility window explained', 'Signs of a healthy cycle'],
'PCOS': ['PCOS symptoms to know', 'Lifestyle changes that help', 'When to get tested for PCOS'],
'Nutrition': ['Eating for hormone balance', 'Iron-rich foods during your period', 'Foods that ease period pain'],
'Mental Health': ['Mood swings and your cycle', 'Coping with PMS anxiety', 'Building a self-care routine'],
};

static const Map<String, IconData> icons = {
"First period basics — what's normal": Icons.favorite_border,
'Talking to a guardian about your cycle': Icons.chat_bubble_outline,
'Understanding ovulation': Icons.egg_outlined,
'Fertility window explained': Icons.calendar_month_outlined,
'Signs of a healthy cycle': Icons.check_circle_outline,
'PCOS symptoms to know': Icons.info_outline,
'Lifestyle changes that help': Icons.directions_walk,
'When to get tested for PCOS': Icons.medical_services_outlined,
'Eating for hormone balance': Icons.restaurant_outlined,
'Iron-rich foods during your period': Icons.bloodtype_outlined,
'Foods that ease period pain': Icons.local_dining_outlined,
'Mood swings and your cycle': Icons.mood_outlined,
'Coping with PMS anxiety': Icons.self_improvement_outlined,
'Building a self-care routine': Icons.spa_outlined,
};

static const Map<String, List<String>> articleContent = {
"First period basics — what's normal": [
'A first period usually arrives between ages 10–15, though anywhere in that range is normal.',
'Cycles can be irregular for the first 1–2 years — that\'s expected, not a problem.',
'A typical period lasts 3–7 days, with a cycle (start to next start) of 21–35 days.',
'Mild cramping, mood changes, and bloating are common and usually manageable with rest, warmth, or over-the-counter pain relief.',
'See a doctor if: periods haven\'t started by 16, bleeding soaks through a pad/tampon every hour for several hours, or pain stops you from daily activities.',
],
'Talking to a guardian about your cycle': [
'Pick a calm, private moment rather than bringing it up in passing.',
'It can help to write down what you want to say first, especially for the first conversation.',
'Bring specifics: when it started, how you\'re feeling, and any products you need.',
'If a parent isn\'t approachable, a school nurse, aunt, older sister, or family doctor are all good alternatives.',
'You are not overreacting or being dramatic by asking for help — this is a normal part of growing up that deserves support.',
],
'Understanding ovulation': [
'Ovulation is when an ovary releases an egg — usually once per cycle, around the midpoint.',
'In a 28-day cycle, this typically falls around day 14, but it varies person to person.',
'Signs can include a slight temperature rise, changes in discharge (clearer, stretchier), and mild one-sided pelvic twinges.',
'The egg survives about 24 hours after release, which is why the days just before ovulation matter most for fertility.',
'Tracking apps estimate ovulation from cycle history, but it can shift month to month with stress, illness, or travel.',
],
'Fertility window explained': [
'The fertility window is the ~6-day stretch when pregnancy is possible: the 5 days before ovulation plus ovulation day itself.',
'Sperm can survive in the body up to 5 days, which is why the window starts before the egg is even released.',
'The window shifts if your cycle length changes month to month — a single average won\'t always be accurate.',
'This window is useful for both trying to conceive and for understanding your body better, regardless of that goal.',
],
'Signs of a healthy cycle': [
'A cycle length anywhere from 21–35 days is considered typical — "regular" doesn\'t mean exactly 28 days for everyone.',
'Consistent length month to month (within a few days) is a good sign, more so than the exact number.',
'Manageable pain, predictable flow, and a period lasting 3–7 days are all healthy signs.',
'Tracking over 3+ months gives a much clearer picture than judging any single cycle alone.',
],
'PCOS symptoms to know': [
'PCOS (Polycystic Ovary Syndrome) is a hormonal condition, not something caused by anything you did.',
'Common signs: irregular or missed periods, excess facial/body hair, acne, and weight changes.',
'Not everyone with PCOS has visible ovarian cysts — the name is a bit misleading.',
'It\'s diagnosed by a doctor using a combination of symptoms, blood tests, and sometimes ultrasound — not from an app or a single symptom.',
'If your cycles have been irregular for several months, that alone is worth mentioning to a doctor, even without other symptoms.',
],
'Lifestyle changes that help': [
'Regular movement (even walking) can improve insulin sensitivity, which is often linked to PCOS symptoms.',
'Balanced meals with protein and fiber help smooth out blood sugar swings that can worsen symptoms.',
'Consistent sleep matters — poor sleep is linked to worse hormonal regulation.',
'These changes support symptom management but don\'t replace a doctor\'s guidance or, where needed, medication.',
],
'When to get tested for PCOS': [
'Consider talking to a doctor if periods have been irregular (very long, very short, or unpredictable) for 3+ months.',
'Other prompts: unexplained new acne or hair growth, or difficulty managing weight despite consistent habits.',
'Testing usually involves a physical exam, blood work (hormone levels), and sometimes a pelvic ultrasound.',
'Getting tested early makes any needed management easier — there\'s no downside to asking.',
],
'Eating for hormone balance': [
'Consistent meal timing helps stabilize blood sugar, which in turn supports hormone regulation.',
'Include protein and healthy fats at each meal — they slow digestion and reduce energy crashes.',
'Cruciferous vegetables (broccoli, cauliflower) support estrogen metabolism.',
'Limiting excess sugar and ultra-processed food can reduce inflammation linked to period pain.',
],
'Iron-rich foods during your period': [
'Menstrual blood loss can lower iron levels, especially with heavier periods.',
'Good sources: spinach, lentils, chickpeas, red meat, pumpkin seeds, and fortified cereals.',
'Pairing iron-rich food with vitamin C (citrus, tomatoes) improves absorption.',
'Tea and coffee right after meals can reduce iron absorption — space them out if you\'re low on energy.',
'Ongoing fatigue, dizziness, or paleness can be signs of low iron worth checking with a doctor.',
],
'Foods that ease period pain': [
'Anti-inflammatory foods — berries, fatty fish, leafy greens, ginger — may help ease cramps for some people.',
'Warm foods and drinks (soups, herbal tea) can be soothing alongside the physical warmth of a heating pad.',
'Reducing salt slightly around your period can help ease bloating-related discomfort.',
'Magnesium-rich foods (nuts, seeds, dark chocolate) are linked to reduced cramp severity in some studies.',
],
'Mood swings and your cycle': [
'Hormone shifts (especially estrogen and progesterone) directly affect mood-regulating brain chemicals.',
'It\'s common to feel more irritable, teary, or anxious in the days before a period (the luteal phase).',
'Tracking mood alongside your cycle can help you tell the difference between "this is cycle-related" and "this needs more attention."',
'Light exercise, sleep, and reducing caffeine in the days before your period can soften the effect for some people.',
],
'Coping with PMS anxiety': [
'Cyclical anxiety that consistently worsens before your period and eases after it starts may be linked to PMS or PMDD.',
'Grounding techniques (slow breathing, naming things you can see/hear) can help in the moment.',
'Reducing caffeine and alcohol in the days before your period can lessen anxiety spikes for some people.',
'If anxiety is severe enough to disrupt daily life every cycle, that\'s worth discussing with a doctor — effective treatments exist.',
],
'Building a self-care routine': [
'Small, repeatable habits (a set bedtime, 10 minutes of quiet time) tend to stick better than big occasional gestures.',
'Try syncing self-care intensity to your cycle phase — more rest in the days before your period, more energy for activity around ovulation.',
'A routine doesn\'t need to be elaborate — journaling, a short walk, or simply logging how you feel all count.',
'The goal is consistency, not perfection — missing a day doesn\'t undo the routine.',
],
};

@override
State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
String query = '';
String activeCategory = 'Teen Health';

@override
Widget build(BuildContext context) {
final filtered = query.isEmpty
? LibraryScreen.articlesByCategory[activeCategory]!
: LibraryScreen.articlesByCategory.values.expand((v) => v).where((a) => a.toLowerCase().contains(query.toLowerCase())).toList();

return SafeArea(
child: SingleChildScrollView(
padding: const EdgeInsets.all(20),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text('Health Library', style: Theme.of(context).textTheme.titleLarge),
const SizedBox(height: 4),
const Text('Answers, not search results.', style: TextStyle(fontSize: 12, color: AshaColors.slate)),
const SizedBox(height: 12),
TextField(
decoration: const InputDecoration(hintText: 'Search "teenagers", "PCOS"...', prefixIcon: Icon(Icons.search)),
onChanged: (v) => setState(() => query = v),
),
const SizedBox(height: 14),
Wrap(spacing: 8, children: LibraryScreen.categories.map((c) => AshaChip(label: c, selected: activeCategory == c, onTap: () => setState(() { activeCategory = c; query = ''; }))).toList()),
const SizedBox(height: 18),
GridView.builder(
shrinkWrap: true,
physics: const NeverScrollableScrollPhysics(),
itemCount: filtered.length,
gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: 0.82,
),
itemBuilder: (_, i) {
final title = filtered[i];
final icon = LibraryScreen.icons[title] ?? Icons.article_outlined;
return GestureDetector(
onTap: () => Navigator.pushNamed(context, '/article', arguments: title),
child: Container(
padding: const EdgeInsets.all(14),
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(18),
boxShadow: [BoxShadow(color: AshaColors.ink.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Container(
width: 42, height: 42,
decoration: BoxDecoration(color: AshaColors.peach, borderRadius: BorderRadius.circular(12)),
child: Icon(icon, color: AshaColors.coral, size: 20),
),
const SizedBox(height: 12),
Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, height: 1.3), maxLines: 3, overflow: TextOverflow.ellipsis),
const Spacer(),
const Text('Read →', style: TextStyle(fontSize: 11, color: AshaColors.coral, fontWeight: FontWeight.bold)),
],
),
),
);
},
),
],
),
),
);
}
}