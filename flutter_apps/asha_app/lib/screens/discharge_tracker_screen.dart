import 'package:flutter/material.dart';
import '../theme/asha_theme.dart';
import '../services/api_service.dart';

class DischargeEntry { final String label; final Color color; DischargeEntry(this.label, this.color); }

class DischargeTrackerScreen extends StatefulWidget {
  const DischargeTrackerScreen({super.key});
  @override
  State<DischargeTrackerScreen> createState() => _DischargeTrackerScreenState();
}

class _DischargeTrackerScreenState extends State<DischargeTrackerScreen> {
  final colors = [
    DischargeEntry('White', const Color(0xFFF5F1E8)), DischargeEntry('Clear', const Color(0xFFEAF3F5)),
    DischargeEntry('Yellow', const Color(0xFFF0C94A)), DischargeEntry('Brown', const Color(0xFFD98F3E)),
    DischargeEntry('Brown', const Color(0xFFC97A5C)), DischargeEntry('Green', const Color(0xFF8FC7B5)),
  ];
  final textures = [
    DischargeEntry('Watery', const Color(0xFFDCEEF2)), DischargeEntry('Sticky', const Color(0xFFF3E9D2)),
    DischargeEntry('Creamy', const Color(0xFFF5F0E0)), DischargeEntry('Egg White', const Color(0xFFF7F5EA)),
    DischargeEntry('Egg White', const Color(0xFFEFEBDD)), DischargeEntry('Thick', const Color(0xFFDCD6CC)),
  ];
  String? selectedColor;
  String? selectedTexture;

  Widget _eggGrid(List<DischargeEntry> items, String? selected, void Function(String) onSelect) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: 0.8),
      itemBuilder: (_, i) {
        final item = items[i];
        final isSelected = selected == item.label;
        return GestureDetector(
          onTap: () => onSelect(item.label),
          child: Column(children: [
            Container(width: 46, height: 54, decoration: BoxDecoration(color: item.color, borderRadius: BorderRadius.circular(30), border: isSelected ? Border.all(color: AshaColors.coral, width: 3) : null)),
            const SizedBox(height: 6),
            Text(item.label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
          ]),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('Log Discharge')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Color', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              _eggGrid(colors, selectedColor, (v) => setState(() => selectedColor = v)),
              const SizedBox(height: 20),
              Text('Texture', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              _eggGrid(textures, selectedTexture, (v) => setState(() => selectedTexture = v)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AshaColors.coral, padding: const EdgeInsets.all(16)),
                  onPressed: () async {
                    await ApiService.logSymptoms(1, {'discharge_color': selectedColor, 'discharge_texture': selectedTexture});
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Save entry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}