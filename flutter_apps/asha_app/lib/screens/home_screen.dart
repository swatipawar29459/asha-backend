
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/prediction.dart';
import '../services/api_service.dart';
import '../services/health_profile_store.dart';
import '../theme/asha_theme.dart';

import 'discharge_tracker_screen.dart';
import 'find_doctor_screen.dart';
import 'library_screen.dart';
import 'notification_screen.dart';
import 'quick_log_screen.dart';
import 'why_prediction_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Prediction? _prediction;

  bool _loading = false;

  String _errorMessage = '';

  Timer? _refreshTimer;

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
      // Load the current user's locally stored profile first.
      await HealthProfileStore.load();

      if (!mounted) return;

      // Get the CURRENTLY logged-in Firebase user.
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


      /*
       * IMPORTANT:
       *
       * We do NOT check:
       * HealthProfileStore.hasRequiredPredictionData
       *
       * here.
       *
       * We send the current user's UID and profile to the backend.
       */

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

      /*
       * Do NOT create a fake/local prediction here.
       *
       * If the ML backend fails, show an error instead of
       * displaying a different calculated date and making it
       * look like the ML prediction.
       */
      setState(() {
        _loading = false;
        _errorMessage =
            'Unable to load your personalized prediction. '
            'Please try again.';
      });
    }
  }

  // ============================================================
  // DATE FORMAT
  // ============================================================

  // ignore: unused_element
  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day} ${months[date.month - 1]}';
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
        18,
        20,
        8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, ${_getUserName()} 🌷',
                  style: const TextStyle(
                    color: AshaColors.ink,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Let’s take care of you today.',
                  style: TextStyle(
                    color: AshaColors.slate,
                    fontSize: 13,
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
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          openScreen(
            const NotificationScreen(),
          );
        },
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AshaColors.peachDark,
            ),
          ),
          child: const Icon(
            Icons.notifications_none_rounded,
            color: AshaColors.coral,
            size: 25,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // MAIN CONTENT
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        10,
        20,
        30,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_errorMessage.isNotEmpty)
            _buildErrorCard(),

          _buildCycleCard(),

          const SizedBox(height: 4),

          _buildPredictionCards(),

          const SizedBox(height: 4),

          _buildQuickActions(),

          const SizedBox(height: 4),

          _buildHealthInsight(),

          const SizedBox(height: 4),

          _buildDoctorCard(),

          const SizedBox(height: 4),

          _buildAshaCard(),

          const SizedBox(height: 8),

          _buildPredictionInfoButton(),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR CARD
  // ============================================================

  Widget _buildErrorCard() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AshaCard(
        tint: AshaColors.peach,
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
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CYCLE CARD
  // ============================================================

  Widget _buildCycleCard() {
    final prediction = _prediction;

    if (prediction == null) {
      return AshaCard(
        tint: AshaColors.peach,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AshaColors.coral,
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Your prediction is unavailable',
                    style: TextStyle(
                      color: AshaColors.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'We could not load your personalized cycle prediction from the ML server.',
              style: TextStyle(
                color: AshaColors.slate,
                fontSize: 13,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _loadHomeData();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AshaColors.coral,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    vertical: 13,
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
            ),
          ],
        ),
      );
    }

    final progress =
        prediction.cycleProgress.clamp(0.0, 1.0);

    return AshaCard(
      tint: Colors.white,
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 112,
                height: 112,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 112,
                      height: 112,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 9,
                        backgroundColor: AshaColors.peach,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(
                          AshaColors.coral,
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${prediction.currentDay}',
                          style: const TextStyle(
                            color: AshaColors.ink,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Text(
                          'cycle day',
                          style: TextStyle(
                            color: AshaColors.slate,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your cycle',
                      style: TextStyle(
                        color: AshaColors.slate,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      prediction.phaseLabel,
                      style: const TextStyle(
                        color: AshaColors.ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${prediction.avgCycleLength}-day average cycle',
                      style: const TextStyle(
                        color: AshaColors.slate,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${prediction.avgPeriodLength}-day period',
                      style: const TextStyle(
                        color: AshaColors.slate,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AshaColors.peach,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(
                AshaColors.coral,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text(
                'Cycle progress',
                style: TextStyle(
                  color: AshaColors.slate,
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(
                  color: AshaColors.coral,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
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
        Expanded(
          child: _buildInfoCard(
            icon: Icons.calendar_month_rounded,
            title: 'Next period',
            value: prediction.nextPeriodLabel.isEmpty
                ? 'Not available'
                : prediction.nextPeriodLabel,
            subtitle: 'Based on your ML prediction',
            tint: AshaColors.peach,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInfoCard(
            icon: Icons.spa_rounded,
            title: 'Fertile window',
            value: prediction.fertileWindowLabel.isEmpty
                ? 'Not available'
                : prediction.fertileWindowLabel,
            subtitle: 'Estimated fertile days',
            tint: AshaColors.lavender,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color tint,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: 0.75,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AshaColors.coral,
              size: 20,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: AshaColors.slate,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AshaColors.ink,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: const TextStyle(
              color: AshaColors.slate,
              fontSize: 10,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // QUICK ACTIONS
  // ============================================================

  Widget _buildQuickActions() {
    return AshaCard(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick actions',
            style: TextStyle(
              color: AshaColors.ink,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildQuickAction(
                  icon: Icons.edit_calendar_rounded,
                  label: 'Log symptoms',
                  onTap: () {
                    openScreen(
                      const QuickLogScreen(),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildQuickAction(
                  icon: Icons.water_drop_outlined,
                  label: 'Discharge',
                  onTap: () {
                    openScreen(
                      const DischargeTrackerScreen(),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildQuickAction(
                  icon: Icons.local_library_outlined,
                  label: 'Health library',
                  onTap: () {
                    openScreen(
                      const LibraryScreen(),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 13,
          horizontal: 5,
        ),
        decoration: BoxDecoration(
          color: AshaColors.peach,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: AshaColors.coral,
              size: 25,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(
                color: AshaColors.ink,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEALTH INSIGHT
  // ============================================================

  Widget _buildHealthInsight() {
    final prediction = _prediction;

    if (prediction == null) {
      return AshaCard(
        tint: AshaColors.lavender,
        child: Row(
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_outline_rounded,
                color: AshaColors.coral,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Your personalized health insights will appear here after your prediction loads.',
                style: TextStyle(
                  color: AshaColors.ink,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final hasPcos =
        prediction.pcosRisk == 'Reported PCOS';

    return AshaCard(
      tint: AshaColors.lavender,
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasPcos
                  ? Icons.health_and_safety_outlined
                  : Icons.favorite_outline_rounded,
              color: AshaColors.coral,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Health insight',
                  style: TextStyle(
                    color: AshaColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  hasPcos
                      ? 'Your profile shows reported PCOS. Keep tracking your symptoms and cycle patterns.'
                      : 'Your current profile shows no reported PCOS. Continue tracking your cycle and symptoms regularly.',
                  style: const TextStyle(
                    color: AshaColors.slate,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DOCTOR CARD
  // ============================================================

  Widget _buildDoctorCard() {
    return AshaCard(
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AshaColors.peach,
              borderRadius:
                  BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.local_hospital_outlined,
              color: AshaColors.coral,
              size: 27,
            ),
          ),
          const SizedBox(width: 13),
          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Need professional help?',
                  style: TextStyle(
                    color: AshaColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Find nearby doctors and clinics.',
                  style: TextStyle(
                    color: AshaColors.slate,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              openScreen(
                const FindDoctorScreen(),
              );
            },
            icon: const Icon(
              Icons.arrow_forward_ios_rounded,
              color: AshaColors.coral,
              size: 17,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ASHA CARD
  // ============================================================

  Widget _buildAshaCard() {
    return const AshaCard(
      tint: AshaColors.peach,
      child: Row(
        children: [
          AshaMascot(
            size: 58,
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Talk to Asha',
                  style: TextStyle(
                    color: AshaColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Have a question about your menstrual health?',
                  style: TextStyle(
                    color: AshaColors.slate,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chat_bubble_outline_rounded,
            color: AshaColors.coral,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // WHY PREDICTION
  // ============================================================

  Widget _buildPredictionInfoButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          openScreen(
            const WhyPredictionScreen(),
          );
        },
        icon: const Icon(
          Icons.info_outline_rounded,
          size: 18,
        ),
        label: const Text(
          'How is my prediction calculated?',
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AshaColors.coral,
          side: const BorderSide(
            color: AshaColors.peachDark,
          ),
          padding: const EdgeInsets.symmetric(
            vertical: 13,
          ),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }
}

