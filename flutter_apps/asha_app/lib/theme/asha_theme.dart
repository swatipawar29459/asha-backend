import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AshaColors {
  static const cream = Color(0xFFFFF8F1);
  static const peach = Color(0xFFFDE6D8);
  static const peachDark = Color(0xFFF6C4A6);
  static const coral = Color(0xFFD9764F);      // primary accent (was terracotta)
  static const coralDark = Color(0xFFB85A38);
  static const ink = Color(0xFF4A2F22);         // headline text
  static const slate = Color(0xFF8A6250);       // body text
  static const mint = Color(0xFFB7CDB0);        // cycle/positive tint
  static const mintDark = Color(0xFF8FB781);
  static const sky = Color(0xFFAFD6DE);         // fertility tint
  static const sun = Color(0xFFF3D98A);         // energy/tips tint
  static const lavender = Color(0xFFE7DDF2);    // insights tint
  static const lavenderDark = Color(0xFFC3AEDD);
  static const alert = Color(0xFFD9503F);
}

class AshaTheme {
  static ThemeData light() => ThemeData(
        scaffoldBackgroundColor: AshaColors.cream,
        primaryColor: AshaColors.coral,
        colorScheme: ColorScheme.fromSeed(seedColor: AshaColors.coral),
        textTheme: GoogleFonts.interTextTheme().copyWith(
          displayLarge: GoogleFonts.fraunces(fontSize: 26, fontWeight: FontWeight.w600, color: AshaColors.ink),
          titleLarge: GoogleFonts.fraunces(fontSize: 19, fontWeight: FontWeight.w600, color: AshaColors.ink),
          bodyMedium: GoogleFonts.inter(fontSize: 13, color: AshaColors.slate),
        ),
        cardTheme: CardThemeData(elevation: 0, color: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
        inputDecorationTheme: InputDecorationTheme(
          filled: true, fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AshaColors.peachDark)),
        ),
      );
}

class AshaCard extends StatelessWidget {
  final Widget child;
  final Color? tint;
  const AshaCard({super.key, required this.child, this.tint});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tint ?? Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: AshaColors.ink.withOpacity(0.06), blurRadius: 18, offset: const Offset(0, 6))],
        ),
        child: child,
      );
}

class AshaChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const AshaChip({super.key, required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(color: selected ? AshaColors.coral : AshaColors.peach, borderRadius: BorderRadius.circular(20)),
          child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? Colors.white : AshaColors.ink)),
        ),
      );
}

class AshaMascot extends StatelessWidget {
  final double size;
  const AshaMascot({super.key, this.size = 90});
  @override
  Widget build(BuildContext context) => Container(
        width: size, height: size,
        decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [AshaColors.peachDark, AshaColors.coral], begin: Alignment.topLeft, end: Alignment.bottomRight)),
        // TODO: replace with Image.asset('assets/mascot.png') once you add your illustration
        child: Icon(Icons.face_3_rounded, color: Colors.white, size: size * 0.45),
      );
}