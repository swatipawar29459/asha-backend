import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/api_service.dart';
import '../services/health_profile_store.dart';

class NotificationScreen
    extends StatefulWidget {
  const NotificationScreen({
    super.key,
  });

  @override
  State<NotificationScreen>
      createState() =>
          _NotificationScreenState();
}

class _NotificationScreenState
    extends State<NotificationScreen> {
  List<AshaNotification>
      notifications = [];

  bool loading = true;

  String? error;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void>
      _loadNotifications() async {
    try {
      final user =
          FirebaseAuth.instance
              .currentUser;

      if (user == null) {
        setState(() {
          error =
              'Please sign in again.';
          loading = false;
        });
        return;
      }

      await HealthProfileStore.load();

      final data =
          await ApiService
              .fetchNotifications(
        userId: user.uid,
      );

      if (!mounted) return;

      setState(() {
        notifications = data;
        loading = false;
      });
    } catch (e) {
      print(
        'Notification error: $e',
      );

      if (!mounted) return;

      setState(() {
        error =
            'Could not load notifications.';
        loading = false;
      });
    }
  }

  IconData _getIcon(
    String type,
  ) {
    switch (type) {
      case 'period':
        return Icons
            .water_drop_outlined;

      case 'fertile':
        return Icons
            .spa_outlined;

      case 'symptom':
        return Icons
            .favorite_border;

      case 'cycle':
        return Icons
            .calendar_month_outlined;

      case 'wellness':
        return Icons
            .self_improvement_outlined;

      default:
        return Icons
            .notifications_none;
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
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
          TextButton(
            onPressed: () {},
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
          : error != null
              ? Center(
                  child: Padding(
                    padding:
                        const EdgeInsets
                            .all(
                      24,
                    ),
                    child: Text(
                      error!,
                      textAlign:
                          TextAlign.center,
                    ),
                  ),
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
                            notifications
                                .length,
                        itemBuilder:
                            (context,
                                index) {
                          final notification =
                              notifications[
                                  index];

                          return _NotificationCard(
                            icon:
                                _getIcon(
                              notification
                                  .type,
                            ),
                            title:
                                notification
                                    .title,
                            message:
                                notification
                                    .message,
                            time:
                                notification
                                    .time,
                          );
                        },
                      ),
                    ),
    );
  }

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

class _NotificationCard
    extends StatelessWidget {
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
        color:
            const Color(0xFFFFE9DC),
        borderRadius:
            BorderRadius.circular(
          18,
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
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