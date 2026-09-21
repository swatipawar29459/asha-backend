
import 'package:flutter/material.dart';

import '../services/notification_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({
    super.key,
  });

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

  // ============================================================
  // LOAD LOCAL ASHA NOTIFICATIONS
  // ============================================================

  Future<void> _loadNotifications() async {
    try {
      final data =
          await NotificationService.getNotificationHistory();

      if (!mounted) return;

      setState(() {
        notifications = data;
        loading = false;
      });
    } catch (e) {
      debugPrint(
        'Notification error: $e',
      );

      if (!mounted) return;

      setState(() {
        loading = false;
      });
    }
  }

  // ============================================================
  // MARK ALL READ
  // ============================================================

  Future<void> _markAllRead() async {
    await NotificationService
        .markAllCycleNotificationsAsRead();

    await _loadNotifications();
  }

  // ============================================================
  // MARK ONE READ
  // ============================================================

  Future<void> _markOneRead(int index) async {
    await NotificationService
        .markNotificationAsRead(index);

    await _loadNotifications();
  }

  // ============================================================
  // ICON
  // ============================================================

  IconData _getIcon(
    String title,
  ) {
    final lowerTitle =
        title.toLowerCase();

    if (lowerTitle.contains('period') ||
        lowerTitle.contains('menstrual')) {
      return Icons.water_drop_outlined;
    }

    if (lowerTitle.contains('fertile') ||
        lowerTitle.contains('ovulation')) {
      return Icons.spa_outlined;
    }

    if (lowerTitle.contains('luteal')) {
      return Icons.nightlight_round;
    }

    if (lowerTitle.contains('cycle')) {
      return Icons.calendar_month_outlined;
    }

    return Icons.notifications_none;
  }

  // ============================================================
  // TIME FORMAT
  // ============================================================

  String _formatTime(
    String? dateString,
  ) {
    if (dateString == null) {
      return '';
    }

    try {
      final date =
          DateTime.parse(dateString);

      final now =
          DateTime.now();

      final difference =
          now.difference(date);

      if (difference.inMinutes < 1) {
        return 'Just now';
      }

      if (difference.inMinutes < 60) {
        return '${difference.inMinutes} min ago';
      }

      if (difference.inHours < 24) {
        return '${difference.inHours} hr ago';
      }

      if (difference.inDays == 1) {
        return 'Yesterday';
      }

      if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      }

      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
    } catch (_) {
      return '';
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final unreadCount =
        notifications.where(
      (notification) =>
          notification['read'] != true,
    ).length;

    return Scaffold(
      backgroundColor:
          const Color(0xFFFFF8F3),

      appBar: AppBar(
        backgroundColor:
            const Color(0xFFFFF8F3),
        elevation: 0,
        centerTitle: false,

        title: const Text(
          'Notifications',
          style: TextStyle(
            color:
                Color(0xFF513C35),
            fontSize: 24,
            fontWeight:
                FontWeight.w600,
          ),
        ),

        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed:
                  _markAllRead,
              child: const Text(
                'Mark all read',
                style: TextStyle(
                  color:
                      Color(0xFFD8754E),
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),

      body: loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : notifications.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh:
                      _loadNotifications,

                  child:
                      ListView.builder(
                    padding:
                        const EdgeInsets
                            .fromLTRB(
                      16,
                      12,
                      16,
                      24,
                    ),

                    itemCount:
                        notifications.length,

                    itemBuilder:
                        (context, index) {
                      final notification =
                          notifications[
                              index];

                      final title =
                          notification[
                                  'title'] ??
                              'Asha';

                      final message =
                          notification[
                                  'body'] ??
                              '';

                      final time =
                          _formatTime(
                        notification[
                            'date'],
                      );

                      final isUnread =
                          notification[
                                  'read'] !=
                              true;

                      return GestureDetector(
                        onTap: () async {
                          if (isUnread) {
                            await _markOneRead(
                              index,
                            );
                          }
                        },

                        child:
                            _NotificationCard(
                          icon:
                              _getIcon(
                            title,
                          ),
                          title:
                              title,
                          message:
                              message,
                          time:
                              time,
                          isUnread:
                              isUnread,
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(
          32,
        ),

        child: Column(
          mainAxisAlignment:
              MainAxisAlignment
                  .center,

          children: [
            Container(
              height: 80,
              width: 80,

              decoration:
                  const BoxDecoration(
                color:
                    Color(0xFFFCE4D6),
                shape:
                    BoxShape.circle,
              ),

              child: const Icon(
                Icons
                    .notifications_none_rounded,
                size: 38,
                color:
                    Color(0xFFD8754E),
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            const Text(
              'No notifications yet',
              style: TextStyle(
                color:
                    Color(0xFF513C35),
                fontSize: 20,
                fontWeight:
                    FontWeight.w600,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            const Text(
              'Asha will keep you updated about your cycle, fertile window, and wellness reminders.',
              textAlign:
                  TextAlign.center,

              style: TextStyle(
                color:
                    Color(0xFF806D65),
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

// ============================================================
// NOTIFICATION CARD
// ============================================================

class _NotificationCard
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String time;
  final bool isUnread;

  const _NotificationCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.time,
    required this.isUnread,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),

      padding:
          const EdgeInsets.all(
        16,
      ),

      decoration:
          BoxDecoration(
        color: isUnread
            ? const Color(
                0xFFFFE9DC,
              )
            : const Color(
                0xFFFFF1EA,
              ),

        borderRadius:
            BorderRadius.circular(
          18,
        ),

        border: isUnread
            ? Border.all(
                color: const Color(
                  0xFFF2C7B5,
                ),
              )
            : null,
      ),

      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment
                .start,

        children: [
          // ----------------------------------------------------
          // ICON
          // ----------------------------------------------------

          Container(
            height: 46,
            width: 46,

            decoration:
                const BoxDecoration(
              color:
                  Color(0xFFD8754E),
              shape:
                  BoxShape.circle,
            ),

            child: Icon(
              icon,
              color:
                  Colors.white,
              size: 23,
            ),
          ),

          const SizedBox(
            width: 14,
          ),

          // ----------------------------------------------------
          // CONTENT
          // ----------------------------------------------------

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,

              children: [
                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          if (isUnread)
                            Container(
                              width: 7,
                              height: 7,
                              margin:
                                  const EdgeInsets
                                      .only(
                                right: 7,
                                top: 5,
                              ),
                              decoration:
                                  const BoxDecoration(
                                color:
                                    Color(
                                  0xFFD8754E,
                                ),
                                shape:
                                    BoxShape
                                        .circle,
                              ),
                            ),

                          Expanded(
                            child: Text(
                              title,
                              style:
                                  const TextStyle(
                                color:
                                    Color(
                                  0xFF513C35,
                                ),
                                fontSize: 15,
                                fontWeight:
                                    FontWeight
                                        .w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      width: 8,
                    ),

                    Text(
                      time,
                      style:
                          const TextStyle(
                        color:
                            Color(
                          0xFF967E74,
                        ),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 6,
                ),

                Text(
                  message,
                  style:
                      const TextStyle(
                    color:
                        Color(
                      0xFF6D5A52,
                    ),
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
