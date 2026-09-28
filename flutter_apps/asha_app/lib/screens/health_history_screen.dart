import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/asha_theme.dart';

class HealthHistoryScreen extends StatelessWidget {
  const HealthHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Health History'),
        ),
        body: const Center(
          child: Text('Please log in again.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health History'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('health_logs')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load your health history.\n\n'
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final logs = snapshot.data?.docs ?? [];

          if (logs.isEmpty) {
            return _emptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              return _HealthLogCard(
                data: logs[index].data(),
              );
            },
          );
        },
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_rounded,
              size: 64,
              color: AshaColors.coral,
            ),
            const SizedBox(height: 18),
            const Text(
              'No health history yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Your discharge and symptom entries will appear here after you save them.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _HealthLogCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _HealthLogCard({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final String? dischargeColor =
        data['discharge_color']?.toString();

    final String? dischargeTexture =
        data['discharge_texture']?.toString();

    final dynamic rawSymptoms = data['symptoms'];

    List<String> symptoms = [];

    if (rawSymptoms is List) {
      symptoms = rawSymptoms
          .map((item) => item.toString())
          .where((item) => item.isNotEmpty)
          .toList();
    }

    final Timestamp? timestamp =
        data['createdAt'] is Timestamp
            ? data['createdAt'] as Timestamp
            : null;

    final DateTime? dateTime = timestamp?.toDate();

    final String dateLabel = dateTime == null
        ? 'Recently saved'
        : _formatDate(dateTime);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.favorite_rounded,
                  color: AshaColors.coral,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    dateLabel,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (dischargeColor != null &&
                dischargeColor.isNotEmpty)
              _infoRow(
                Icons.water_drop_outlined,
                'Discharge',
                dischargeColor,
              ),
            if (dischargeTexture != null &&
                dischargeTexture.isNotEmpty) ...[
              const SizedBox(height: 10),
              _infoRow(
                Icons.texture_rounded,
                'Texture',
                dischargeTexture,
              ),
            ],
            if (symptoms.isNotEmpty) ...[
              const SizedBox(height: 10),
              _infoRow(
                Icons.health_and_safety_outlined,
                'Symptoms',
                symptoms.join(', '),
              ),
            ],
            const SizedBox(height: 16),
            _buildFeedback(
              color: dischargeColor,
              symptoms: symptoms,
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: AshaColors.coral,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
              ),
              children: [
                TextSpan(
                  text: '$title: ',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeedback({
    String? color,
    required List<String> symptoms,
  }) {
    final bool hasDischarge =
        color != null && color.isNotEmpty;

    final bool hasSymptoms = symptoms.isNotEmpty;

    String title;
    String message;
    IconData icon;

    if (hasDischarge && hasSymptoms) {
      title = 'Your health note';
      message =
          'Asha has saved your discharge and symptoms together so you can notice patterns over time. '
          'Discharge can naturally vary during the menstrual cycle. '
          'If you also notice unusual odor, itching, soreness, pain, or unusual bleeding, '
          'consider speaking with a healthcare professional.';
      icon = Icons.health_and_safety_outlined;
    } else if (hasDischarge) {
      title = 'About your discharge';
      message =
          'Vaginal discharge can naturally change in amount, texture, and appearance during the menstrual cycle. '
          'This entry has been saved so you can track your personal pattern over time.';
      icon = Icons.water_drop_outlined;
    } else if (hasSymptoms) {
      title = 'About your symptoms';
      message =
          'Asha has saved these symptoms so you can track when they occur and compare them with your cycle over time.';
      icon = Icons.favorite_border_rounded;
    } else {
      title = 'Health entry saved';
      message =
          'Your health entry has been saved to your private history.';
      icon = Icons.check_circle_outline_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AshaColors.coral.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 22,
            color: AshaColors.coral,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final int hour = dateTime.hour == 0
        ? 12
        : dateTime.hour > 12
            ? dateTime.hour - 12
            : dateTime.hour;

    final String minute =
        dateTime.minute.toString().padLeft(2, '0');

    final String period =
        dateTime.hour >= 12 ? 'PM' : 'AM';

    return '${dateTime.day}/${dateTime.month}/${dateTime.year} • '
        '$hour:$minute $period';
  }
}