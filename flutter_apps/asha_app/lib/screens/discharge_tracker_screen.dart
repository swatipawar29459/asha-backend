import 'package:flutter/material.dart';

import '../theme/asha_theme.dart';
import '../services/api_service.dart';
import 'package:firebase_auth/firebase_auth.dart';


// ============================================================
// DISCHARGE OPTION
// ============================================================

class DischargeEntry {
  final String label;
  final Color color;

  const DischargeEntry(
    this.label,
    this.color,
  );
}


// ============================================================
// DISCHARGE TRACKER SCREEN
// ============================================================

class DischargeTrackerScreen extends StatefulWidget {
  const DischargeTrackerScreen({
    super.key,
  });

  @override
  State<DischargeTrackerScreen> createState() =>
      _DischargeTrackerScreenState();
}


class _DischargeTrackerScreenState
    extends State<DischargeTrackerScreen> {

  // ==========================================================
  // COLOR OPTIONS
  // ==========================================================

  final List<DischargeEntry> colors = const [

    DischargeEntry(
      'White',
      Color(0xFFF5F1E8),
    ),

    DischargeEntry(
      'Clear',
      Color(0xFFEAF3F5),
    ),

    DischargeEntry(
      'Yellow',
      Color(0xFFF0C94A),
    ),

    DischargeEntry(
      'Brown',
      Color(0xFFD98F3E),
    ),

    DischargeEntry(
      'Green',
      Color(0xFF8FC7B5),
    ),
  ];


  // ==========================================================
  // TEXTURE OPTIONS
  // ==========================================================

  final List<DischargeEntry> textures = const [

    DischargeEntry(
      'Watery',
      Color(0xFFDCEEF2),
    ),

    DischargeEntry(
      'Sticky',
      Color(0xFFF3E9D2),
    ),

    DischargeEntry(
      'Creamy',
      Color(0xFFF5F0E0),
    ),

    DischargeEntry(
      'Egg White',
      Color(0xFFF7F5EA),
    ),

    DischargeEntry(
      'Thick',
      Color(0xFFDCD6CC),
    ),
  ];


  String? selectedColor;
  String? selectedTexture;

  bool saving = false;


  // ==========================================================
  // OPTION GRID
  // ==========================================================

  Widget _optionGrid({
    required List<DischargeEntry> items,
    required String? selected,
    required Function(String) onSelect,
  }) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),

      itemCount: items.length,

      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,

        crossAxisSpacing: 12,

        mainAxisSpacing: 8,

        childAspectRatio: 1.15,
      ),

      itemBuilder: (context, index) {

        final item = items[index];

        final isSelected =
            selected == item.label;

        return GestureDetector(
          onTap: () {
            onSelect(item.label);
          },

          child: Column(
            mainAxisSize: MainAxisSize.min,

            children: [

              AnimatedContainer(
                duration:
                    const Duration(milliseconds: 150),

                width: 48,
                height: 48,

                decoration: BoxDecoration(
                  color: item.color,

                  shape: BoxShape.circle,

                  border: isSelected
                      ? Border.all(
                          color: AshaColors.coral,
                          width: 3,
                        )
                      : Border.all(
                          color: Colors.black12,
                          width: 1,
                        ),
                ),

                child: isSelected
                    ? const Icon(
                        Icons.check,
                        size: 20,
                        color: AshaColors.coral,
                      )
                    : null,
              ),

              const SizedBox(height: 4),

              Text(
                item.label,
                textAlign: TextAlign.center,

                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  // ==========================================================
  // SAVE
  // ==========================================================

  Future<void> _saveEntry() async {

    if (saving) return;

    setState(() {
      saving = true;
    });

    try {

      final user =
          FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception(
          'Please log in again.',
        );
      }

      await ApiService.logSymptoms(
        user.uid,

        {
          'discharge_color':
              selectedColor,

          'discharge_texture':
              selectedTexture,
        },
      );

      if (!mounted) return;

      Navigator.pop(context);

    } catch (e) {

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not save entry: $e',
          ),
        ),
      );

    } finally {

      if (mounted) {

        setState(() {
          saving = false;
        });
      }
    }
  }


  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,

        title: const Text(
          'Log Discharge',
        ),
      ),

      body: SafeArea(

        child: SingleChildScrollView(

          padding:
              const EdgeInsets.fromLTRB(
            20,
            8,
            20,
            24,
          ),

          child: Column(

            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [

              // =================================================
              // COLOR
              // =================================================

              Text(
                'Color',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge,
              ),

              const SizedBox(height: 8),

              _optionGrid(
                items: colors,
                selected: selectedColor,

                onSelect: (value) {

                  setState(() {
                    selectedColor = value;
                  });
                },
              ),


              const SizedBox(height: 14),


              // =================================================
              // TEXTURE
              // =================================================

              Text(
                'Texture',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge,
              ),

              const SizedBox(height: 8),

              _optionGrid(
                items: textures,
                selected: selectedTexture,

                onSelect: (value) {

                  setState(() {
                    selectedTexture = value;
                  });
                },
              ),


              const SizedBox(height: 18),


              // =================================================
              // SAVE BUTTON
              // =================================================

              SizedBox(
                width: double.infinity,

                child: ElevatedButton(

                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        AshaColors.coral,

                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 15,
                    ),

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                  ),

                  onPressed:
                      saving
                          ? null
                          : _saveEntry,

                  child: saving

                      ? const SizedBox(
                          width: 20,
                          height: 20,

                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )

                      : const Text(
                          'Save entry',

                          style: TextStyle(
                            color: Colors.white,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}