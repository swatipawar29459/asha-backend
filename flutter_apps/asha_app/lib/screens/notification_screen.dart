import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = [
      {
        'type': 'period',
        'title': 'Your period may start soon',
        'message':
            'Your predicted period is in 3 days. Make sure you are prepared.',
        'time': 'Today',
        'icon': Icons.water_drop_outlined,
      },
      {
        'type': 'fertile',
        'title': 'Fertile window approaching',
        'message':
            'Your predicted fertile window starts tomorrow.',
        'time': 'Yesterday',
        'icon': Icons.spa_outlined,
      },
      {
        'type': 'symptom',
        'title': 'How are you feeling today?',
        'message':
            'Take a moment to log your symptoms and keep your cycle history updated.',
        'time': 'Yesterday',
        'icon': Icons.favorite_border,
      },
      {
        'type': 'cycle',
        'title': 'Update your cycle',
        'message':
            'Keeping your period dates updated helps Asha improve your predictions.',
        'time': '2 days ago',
        'icon': Icons.calendar_month_outlined,
      },
      {
        'type': 'wellness',
        'title': 'Take care of yourself today',
        'message':
            'Stay hydrated, get enough rest, and listen to your body.',
        'time': '3 days ago',
        'icon': Icons.self_improvement_outlined,
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8F3),
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Color(0xFF513C35),
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Mark all notifications as read.
            },
            child: const Text(
              'Mark all read',
              style: TextStyle(
                color: Color(0xFFD8754E),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
      body: notifications.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                16,
                12,
                16,
                24,
              ),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];

                return _NotificationCard(
                  icon: notification['icon'] as IconData,
                  title: notification['title'] as String,
                  message: notification['message'] as String,
                  time: notification['time'] as String,
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 80,
              width: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFFCE4D6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 38,
                color: Color(0xFFD8754E),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No notifications yet',
              style: TextStyle(
                color: Color(0xFF513C35),
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Asha will keep you updated about your cycle, '
              'fertile window, and wellness reminders.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF806D65),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String time;

  const _NotificationCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE9DC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: const BoxDecoration(
              color: Color(0xFFD8754E),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 23,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Color(0xFF513C35),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      time,
                      style: const TextStyle(
                        color: Color(0xFF967E74),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xFF6D5A52),
                    fontSize: 13,
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
}