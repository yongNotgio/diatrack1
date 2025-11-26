import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';
import 'medication.dart';
import 'health_metrics_history.dart';

class NotificationsScreen extends StatefulWidget {
  final String patientId;

  const NotificationsScreen({Key? key, required this.patientId})
    : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  late Future<List<Map<String, dynamic>>> _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _loadNotifications() {
    setState(() {
      _notificationsFuture = _supabaseService.getNotifications(
        widget.patientId,
      );
    });
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await _supabaseService.markNotificationAsRead(notificationId);
      _loadNotifications();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _navigateBasedOnType(String? type) {
    if (type == null) return;

    switch (type) {
      case 'wound':
        // Navigate to Health Metrics History (Wound Gallery)
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HealthMetricsHistory(patientId: widget.patientId),
          ),
        );
        break;
      case 'medication':
        // Navigate to Medication Screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MedicationScreen(patientId: widget.patientId),
          ),
        );
        break;
      case 'appointment':
      case 'patient':
        // For appointments and patient notifications, go back to home
        // The user likely came from HomeScreen
        Navigator.pop(context);
        break;
      default:
        // For unknown types, just mark as read without navigation
        break;
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _supabaseService.markAllNotificationsAsRead(widget.patientId);
      _loadNotifications();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All notifications marked as read'),
          backgroundColor: Color(0xFF19AC4A),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'appointment':
        return Icons.calendar_today;
      case 'medication':
        return Icons.medication;
      case 'wound':
        return Icons.medical_services;
      case 'patient':
        return Icons.person;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String? type) {
    switch (type) {
      case 'appointment':
        return const Color(0xFF1DA1F2); // Blue
      case 'medication':
        return const Color(0xFF19AC4A); // Green
      case 'wound':
        return const Color(0xFFE74C3C); // Red
      case 'patient':
        return const Color(0xFF9B59B6); // Purple
      default:
        return const Color(0xFF95A5A6); // Gray
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, yyyy').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1DA1F2)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Image.asset(
            'assets/images/diatrack_logo.png',
            height: 32,
            fit: BoxFit.contain,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all, color: Color(0xFF1DA1F2)),
            tooltip: 'Mark all as read',
            onPressed: _markAllAsRead,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _notificationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1DA1F2)),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Color(0xFFE74C3C),
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading notifications',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loadNotifications,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1DA1F2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      child: Text(
                        'Retry',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.notifications_none,
                    color: Color(0xFFBDC3C7),
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF2C3E50),
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Check back later for updates',
                    style: TextStyle(color: Colors.grey, fontFamily: 'Poppins'),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data!;
          final unreadCount =
              notifications.where((n) => n['is_read'] == false).length;

          return RefreshIndicator(
            onRefresh: () async {
              _loadNotifications();
              await Future.delayed(const Duration(milliseconds: 500));
            },
            color: const Color(0xFF1DA1F2),
            child: ListView(
              children: [
                if (unreadCount > 0)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                    child: Text(
                      'You have $unreadCount unread notification${unreadCount != 1 ? 's' : ''}',
                      style: const TextStyle(
                        color: Color(0xFF1DA1F2),
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    final isRead = notification['is_read'] as bool? ?? false;
                    final type = notification['type'] as String?;
                    final createdAt = DateTime.parse(
                      notification['created_at'] as String,
                    );

                    return GestureDetector(
                      onTap: () {
                        // Mark as read if unread
                        if (!isRead) {
                          _markAsRead(notification['notification_id']);
                        }
                        // Navigate based on notification type
                        _navigateBasedOnType(type);
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isRead ? Colors.white : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                isRead
                                    ? const Color(0xFFECF0F1)
                                    : _getNotificationColor(
                                      type,
                                    ).withOpacity(0.3),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: _getNotificationColor(
                                    type,
                                  ).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Icon(
                                    _getNotificationIcon(type),
                                    color: _getNotificationColor(type),
                                    size: 22,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            notification['title'] as String? ??
                                                'Notification',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                              color:
                                                  isRead
                                                      ? const Color(0xFF2C3E50)
                                                      : const Color(0xFF1DA1F2),
                                            ),
                                          ),
                                        ),
                                        if (!isRead)
                                          Container(
                                            width: 8,
                                            height: 8,
                                            margin: const EdgeInsets.only(
                                              left: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getNotificationColor(
                                                type,
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      notification['message'] as String? ??
                                          'No message',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 13,
                                        color: Color(0xFF7F8C8D),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _formatTime(createdAt),
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 12,
                                        color: Color(0xFFBDC3C7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}
