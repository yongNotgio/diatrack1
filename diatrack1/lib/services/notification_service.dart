// --- lib/services/notification_service.dart ---
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/reminder.dart'
    as app_reminder; // Use alias to avoid name clash
import 'package:flutter/material.dart'; // For TimeOfDay

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  Future<void> initialize() async {
    // Initialization settings for Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher'); // Default icon

    // Initialization settings for iOS
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
          onDidReceiveLocalNotification: (id, title, body, payload) async {
            // Handle notification tapped logic here for older iOS versions
          },
        );

    final InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    // Initialize timezone database
    tz.initializeTimeZones();
    // TODO: Set the local location based on user's timezone if possible
    // tz.setLocalLocation(tz.getLocation('America/Detroit')); // Example

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // Handle notification tapped logic here (when app is running or background)
        if (response.payload != null) {
          debugPrint('notification payload: ${response.payload}');
          // You can navigate to a specific screen based on the payload
        }
      },
    );

    // Request permissions for Android 13+
    final androidPlugin =
        flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    if (androidPlugin != null) {
      await androidPlugin
          .requestNotificationsPermission(); // For Android 13+ targeting API 33+
      // For older Android versions or if targeting lower API, permission might be needed differently or implicitly granted.
    }

    // Request permissions for iOS
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> scheduleDailyReminderNotification(
    app_reminder.Reminder reminder,
  ) async {
    if (!reminder.isActive) return; // Don't schedule inactive reminders

    // Ensure reminderId can be parsed as int for notification ID
    // Hashing might be safer if reminderId is a long UUID string
    final notificationId =
        reminder.reminderId.hashCode % 2147483647; // Keep within int32 range

    await flutterLocalNotificationsPlugin.zonedSchedule(
      notificationId, // Use a unique ID based on the reminder
      'Health Reminder: ${reminder.reminderType}', // Title
      reminder.message ??
          'Time to record your ${reminder.reminderType}.', // Body
      _nextInstanceOfTime(
        reminder.reminderTime,
      ), // Calculate next schedule time
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder_channel_id', // Channel ID
          'Daily Reminders', // Channel Name
          channelDescription: 'Channel for daily health reminders',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
          icon: '@mipmap/ic_launcher', // Ensure this icon exists
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents:
          DateTimeComponents.time, // Match only time for daily repeat
      payload: 'reminder_${reminder.reminderId}', // Optional payload
    );
    print(
      "Scheduled notification for reminder: ${reminder.reminderId} at ${reminder.reminderTime}",
    );
  }

  // Helper function to calculate the next occurrence of a specific time
  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  // Cancel a specific notification
  Future<void> cancelNotification(String reminderId) async {
    final notificationId = reminderId.hashCode % 2147483647;
    await flutterLocalNotificationsPlugin.cancel(notificationId);
    print("Cancelled notification for reminder: $reminderId");
  }

  // Cancel all notifications (use with caution)
  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
    print("Cancelled all notifications");
  }

  // Re-schedule all active reminders (e.g., on app start or after updates)
  Future<void> rescheduleAllReminders(
    List<app_reminder.Reminder> reminders,
  ) async {
    await cancelAllNotifications(); // Clear existing schedules first
    for (final reminder in reminders) {
      if (reminder.isActive) {
        // TODO: Implement more complex frequency logic (e.g., weekdays) if needed
        // For now, assuming 'daily' or simple frequencies handled by daily schedule
        await scheduleDailyReminderNotification(reminder);
      }
    }
    print("Rescheduled all active reminders.");
  }
}
