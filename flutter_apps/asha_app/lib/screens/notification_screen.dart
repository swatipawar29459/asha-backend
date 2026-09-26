import 'package:flutter/material.dart';

import '../services/notification_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() =>
      _NotificationScreenState();
}

class _NotificationScreenState
    extends State<NotificationScreen> {
  List<Map<String, dynamic>> notifications = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      loading = true;
    });

    final data =
        await NotificationService.getNotificationHistory();

    if (!mounted) return;

    setState(() {
      notifications = data;
      loading = false;
    });
  }

  Future<void> _markAllRead() async {
    await NotificationService.markAllNotificationsAsRead();
    await _loadNotifications();
  }

  Future<void> _markRead(int index) async {
    await NotificationService.markNotificationAsRead(index);
    await _loadNotifications();
  }

  IconData _getIcon(String title) {
    final lower = title.toLowerCase();

    if (lower.contains('period')) {
      return Icons.water_drop_outlined;
    }

    if (lower.contains('fertile') ||
        lower.contains('ovulation')) {
      return Icons.favorite_outline;
    }

    if (lower.contains('luteal')) {
      return Icons.nightlight_outlined;
    }

    return Icons.notifications_none_rounded;
  }

  String _formatTime(dynamic value) {
    if (value == null) return '';

    final date =
        DateTime.tryParse(value.toString());

    if (date == null) return '';

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.isNegative) {
      return 'Just now';
    }

    if (difference.inMinutes < 1) {
      return 'Just now';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    }

    if (difference.inHours < 24 &&
        now.day == date.day) {
      return '${difference.inHours} hr ago';
    }

    final today =
        DateTime(now.year, now.month, now.day);

    final notificationDay =
        DateTime(date.year, date.month, date.day);

    final days =
        today.difference(notificationDay).inDays;

    if (days == 1) {
      return 'Yesterday';
    }

    if (days < 7) {
      return '$days days ago';
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFFFFF8F3);
    const accent = Color(0xFFD8754E);
    const dark = Color(0xFF4A342D);
    const lightText = Color(0xFF8C746A);

    final unreadCount = notifications
        .where((item) => item['read'] != true)
        .length;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: dark,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text(
                'Mark all read',
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(
                color: accent,
              ),
            )
          : RefreshIndicator(
              color: accent,
              onRefresh: _loadNotifications,
              child: notifications.isEmpty
                  ? ListView(
                      physics:
                          const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 150),
                        Icon(
                          Icons.notifications_none_rounded,
                          size: 64,
                          color: lightText,
                        ),
                        SizedBox(height: 16),
                        Center(
                          child: Text(
                            'No notifications yet',
                            style: TextStyle(
                              color: dark,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        Center(
                          child: Text(
                            'Your Asha updates will appear here.',
                            style: TextStyle(
                              color: lightText,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        16,
                        10,
                        16,
                        30,
                      ),
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final item =
                            notifications[index];

                        final isUnread =
                            item['read'] != true;

                        return GestureDetector(
                          onTap: () {
                            if (isUnread) {
                              _markRead(index);
                            }
                          },
                          child: Container(
                            margin:
                                const EdgeInsets.only(
                              bottom: 12,
                            ),
                            padding:
                                const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isUnread
                                  ? const Color(0xFFFFE9DC)
                                  : Colors.white,
                              borderRadius:
                                  BorderRadius.circular(18),
                              border: Border.all(
                                color: isUnread
                                    ? const Color(
                                        0xFFF2C9B5,
                                      )
                                    : const Color(
                                        0xFFF1E3DC,
                                      ),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration:
                                      BoxDecoration(
                                    color: const Color(
                                      0xFFFFF0E8,
                                    ),
                                    borderRadius:
                                        BorderRadius.circular(
                                      14,
                                    ),
                                  ),
                                  child: Icon(
                                    _getIcon(
                                      item['title']
                                              ?.toString() ??
                                          '',
                                    ),
                                    color: accent,
                                  ),
                                ),
                                const SizedBox(width: 13),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item['title']
                                                      ?.toString() ??
                                                  'Asha',
                                              style:
                                                  const TextStyle(
                                                color: dark,
                                                fontSize: 15,
                                                fontWeight:
                                                    FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          if (isUnread)
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration:
                                                  const BoxDecoration(
                                                color: accent,
                                                shape: BoxShape
                                                    .circle,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(
                                        height: 5,
                                      ),
                                      Text(
                                        item['body']
                                                ?.toString() ??
                                            '',
                                        style:
                                            const TextStyle(
                                          color: lightText,
                                          fontSize: 13,
                                          height: 1.4,
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 8,
                                      ),
                                      Text(
                                        _formatTime(
                                          item['date'],
                                        ),
                                        style:
                                            const TextStyle(
                                          color: lightText,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}