
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/prediction.dart';
import '../services/api_service.dart';
import '../services/health_profile_store.dart';
import '../theme/asha_theme.dart';

import 'discharge_tracker_screen.dart';
import 'find_doctor_screen.dart';
import 'notification_screen.dart';
import 'why_prediction_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color _mint = Color(0xFFDCEEDB);
  static const Color _mintIcon = Color(0xFFE0555A);

  static const Color _skyBlue = Color(0xFFDCEAF3);
  static const Color _skyBlueIcon = Color(0xFF4E9B6E);

  Prediction? _prediction;

  bool _loading = false;
  String _errorMessage = '';

  Timer? _refreshTimer;

  // ============================================================
  // INIT / DISPOSE
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadHomeData();

    _refreshTimer = Timer.periodic(
      const Duration(minutes: 10),
      (_) => _loadHomeData(showLoader: false),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  // ============================================================
  // LOAD HOME DATA
  // ============================================================

  Future<void> _loadHomeData({
    bool showLoader = true,
  }) async {
    if (showLoader && mounted) {
      setState(() {
        _loading = true;
        _errorMessage = '';
      });
    }

    try {
      await HealthProfileStore.load();

      if (!mounted) return;

      final uid = FirebaseAuth.instance.currentUser?.uid;

      if (uid == null || uid.isEmpty) {
        if (!mounted) return;

        setState(() {
          _loading = false;
          _errorMessage =
              'Please log in again to load your personalized prediction.';
        });

        return;
      }

      // IMPORTANT:
      // Prediction still comes from your backend / ML model.
      final result = await ApiService.fetchPrediction(
        userId: uid,
      ).timeout(
        const Duration(seconds: 30),
      );

      if (!mounted) return;

      setState(() {
        _prediction = result;
        _errorMessage = '';
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _errorMessage =
            'Unable to load your personalized prediction. '
            'Please try again.';
      });
    }
  }

  // ============================================================
  // USER NAME
  // ============================================================

  String _getUserName() {
    final storedName = HealthProfileStore.userName.trim();

    if (storedName.isNotEmpty) {
      return storedName;
    }

    final firebaseName =
        FirebaseAuth.instance.currentUser?.displayName?.trim();

    if (firebaseName != null && firebaseName.isNotEmpty) {
      return firebaseName;
    }

    return 'there';
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  Future<void> openScreen(Widget screen) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => screen,
      ),
    );

    if (!mounted) return;

    await _loadHomeData(showLoader: false);
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AshaColors.cream,
      body: SafeArea(
        child: RefreshIndicator(
          color: AshaColors.coral,
          onRefresh: () => _loadHomeData(
            showLoader: false,
          ),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _buildHeader(),
              ),
              SliverToBoxAdapter(
                child: _buildMainContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        16,
        20,
        0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Good Morning',
                  style: TextStyle(
                    color: AshaColors.slate,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '${_getUserName()} 🌼',
                  style: const TextStyle(
                    color: AshaColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          _buildNotificationButton(),
        ],
      ),
    );
  }

  Widget _buildNotificationButton() {
    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: () {
        openScreen(
          const NotificationScreen(),
        );
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.notifications,
          color: AshaColors.ink,
          size: 17,
        ),
      ),
    );
  }

  // ============================================================
  // MAIN CONTENT
  //
  // LAYOUT ADJUSTED: Reduced side padding from 20 to 12
  // for wider content that uses full screen width.
  // ============================================================

  Widget _buildMainContent() {
    if (_loading && _prediction == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 80,
        ),
        child: Center(
          child: CircularProgressIndicator(
            color: AshaColors.coral,
          ),
        ),
      );
    }

    final screenHeight = MediaQuery.sizeOf(context).height;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        12,
        0,
        12,
        25,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (_errorMessage.isNotEmpty)
            _buildErrorCard(),

          // ==================================================
          // EXTRA TOP SPACE
          // Places the cycle section lower on the screen.
          // ==================================================

          SizedBox(
            height: screenHeight * 0.08,
          ),

          // ==================================================
          // CENTER CYCLE CIRCLE
          // ==================================================

          _buildCycleRing(),

          // ==================================================
          // SPACE BETWEEN CIRCLE AND CARDS
          // ==================================================

          SizedBox(
            height: screenHeight * 0.06,
          ),

          // ==================================================
          // NEXT PERIOD + FERTILE WINDOW
          // ==================================================

          _buildPredictionCards(),

          // ==================================================
          // SPACE BETWEEN CARDS AND ACTION BUTTONS
          // ==================================================

          SizedBox(
            height: screenHeight * 0.04,
          ),

          // ==================================================
          // ACTION BUTTONS
          // ==================================================

          _buildActionButtons(),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR CARD
  // ============================================================

  Widget _buildErrorCard() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AshaColors.peach,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.info_outline_rounded,
              color: AshaColors.coral,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _errorMessage,
                style: const TextStyle(
                  color: AshaColors.ink,
                  fontSize: 12,
                ),
              ),
            ),
            TextButton(
              onPressed: () => _loadHomeData(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CYCLE RING
  //
  // SIZE ADJUSTED: Increased from 158x158 to 180x180
  // for larger, more prominent display
  //
  // REFERENCE UI:
  //
  //       DAY 29
  //   Luteal Phase
  //   AI confidence 87%
  //
  // ============================================================

  Widget _buildCycleRing() {
    final prediction = _prediction;

    if (prediction == null) {
      return Column(
        children: [
          const SizedBox(height: 20),

          const Icon(
            Icons.favorite_rounded,
            color: AshaColors.coral,
            size: 36,
          ),

          const SizedBox(height: 10),

          const Text(
            'Your prediction is unavailable',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AshaColors.ink,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'We could not load your personalized cycle\n'
            'prediction from the ML server.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AshaColors.slate,
              fontSize: 11,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 14),

          ElevatedButton(
            onPressed: () => _loadHomeData(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AshaColors.coral,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 11,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Try Again',
              style: TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      );
    }

    final progress =
        prediction.cycleProgress.clamp(0.0, 1.0);

    final confidencePercent =
        prediction.confidence.round();

    return Center(
      child: SizedBox(
        width: 180,
        height: 180,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ==================================================
            // OUTER CIRCLE
            // ==================================================

            SizedBox(
              width: 180,
              height: 180,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 10,
                backgroundColor: AshaColors.peach,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(
                  AshaColors.coral,
                ),
              ),
            ),

            // ==================================================
            // CENTER CONTENT
            // ==================================================

            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // DAY — SAME LINE
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment:
                      CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    const Text(
                      'DAY ',
                      style: TextStyle(
                        color: AshaColors.ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${prediction.currentDay}',
                      style: const TextStyle(
                        color: AshaColors.ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 3),

                // PHASE
                Text(
                  prediction.phaseLabel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AshaColors.slate,
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                  ),
                ),

                const SizedBox(height: 7),

                GestureDetector(
                  onTap: () {
                    openScreen(
                      const WhyPredictionScreen(),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AshaColors.coral,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      'AI confidence $confidencePercent%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PREDICTION CARDS
  // ============================================================

  Widget _buildPredictionCards() {
    final prediction = _prediction;

    if (prediction == null) {
      return const SizedBox.shrink();
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ======================================================
        // NEXT PERIOD
        // ======================================================

        Expanded(
          child: _buildPredictionPill(
            icon: Icons.water_drop_rounded,
            iconColor: _mintIcon,
            label: 'NEXT PERIOD',
            value: prediction.nextPeriodLabel.isEmpty
                ? 'Not available'
                : prediction.nextPeriodLabel,
            tint: _mint,
          ),
        ),

        const SizedBox(width: 8),

        // ======================================================
        // FERTILE WINDOW
        // ======================================================

        Expanded(
          child: _buildPredictionPill(
            icon: Icons.eco_rounded,
            iconColor: _skyBlueIcon,
            label: 'FERTILE WINDOW',
            value: prediction.fertileWindowLabel.isEmpty
                ? 'Not available'
                : prediction.fertileWindowLabel,
            tint: _skyBlue,
          ),
        ),
      ],
    );
  }

  Widget _buildPredictionPill({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required Color tint,
  }) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: iconColor,
                size: 14,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AshaColors.ink,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 3),

          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AshaColors.ink,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACTION BUTTONS
  //
  // WIDTH & HEIGHT ADJUSTED: Buttons now wider and taller
  // Button height increased from 37 to 44
  // ============================================================

  Widget _buildActionButtons() {
    return Column(
      children: [
        // ======================================================
        // LOG DISCHARGE
        // ======================================================

        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton.icon(
            onPressed: () {
              openScreen(
                const DischargeTrackerScreen(),
              );
            },
            icon: const Icon(
              Icons.water_drop_outlined,
              color: AshaColors.ink,
              size: 16,
            ),
            label: const Text(
              'Log discharge',
              style: TextStyle(
                color: AshaColors.ink,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  const Color(0xFFF3D9A0),
              elevation: 0,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(24),
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // ======================================================
        // FIND DOCTOR
        // ======================================================

        SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton.icon(
            onPressed: () {
              openScreen(
                const FindDoctorScreen(),
              );
            },
            icon: const Icon(
              Icons.search_rounded,
              color: AshaColors.slate,
              size: 16,
            ),
            label: const Text(
              'Find a doctor nearby',
              style: TextStyle(
                color: AshaColors.slate,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              side: const BorderSide(
                color: AshaColors.peachDark,
              ),
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(24),
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // ======================================================
        // HEALTH HISTORY
        // ======================================================

        SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/health-history',
              );
            },
            icon: const Icon(
              Icons.history_rounded,
              color: AshaColors.slate,
              size: 16,
            ),
            label: const Text(
              'Health History',
              style: TextStyle(
                color: AshaColors.slate,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              side: const BorderSide(
                color: AshaColors.peachDark,
              ),
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(24),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

