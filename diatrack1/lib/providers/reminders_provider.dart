// --- lib/providers/reminders_provider.dart ---
import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../services/notification_service.dart'; // Import NotificationService
import '../models/reminder.dart';
import 'auth_provider.dart'; // To get patientId

class RemindersProvider with ChangeNotifier {
  final SupabaseService _supabaseService;
  final NotificationService _notificationService; // Add NotificationService
  final AuthProvider _authProvider;

  List<Reminder> _reminders = [];
  List<Reminder> get reminders => _reminders;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // Constructor requires services and AuthProvider
  RemindersProvider(
    this._supabaseService,
    this._notificationService,
    this._authProvider,
  ) {
    _authProvider.addListener(_handleAuthChange);
    _handleAuthChange(); // Initial check
  }

  void _handleAuthChange() {
    if (_authProvider.authState == AuthStateEnum.authenticated &&
        _authProvider.patientProfile != null) {
      fetchReminders(); // Fetch reminders when user is authenticated and profile is loaded
    } else {
      _reminders = []; // Clear reminders if logged out or no profile
      _isLoading = false;
      _error = null;
      _notificationService
          .cancelAllNotifications(); // Cancel notifications on logout
      notifyListeners();
    }
  }

  Future<void> fetchReminders() async {
    final patientId = _authProvider.patientProfile?.patientId;
    if (patientId == null) {
      _error = "Patient profile not available.";
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _reminders = await _supabaseService.getReminders(patientId);
      // After fetching, reschedule notifications for active reminders
      await _notificationService.rescheduleAllReminders(_reminders);
    } catch (e) {
      _error = "Failed to fetch reminders: $e";
      _reminders = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addReminder({
    required String reminderType,
    required TimeOfDay reminderTime,
    String? frequency,
    String? message,
    bool isActive = true,
  }) async {
    final patientId = _authProvider.patientProfile?.patientId;
    if (patientId == null) {
      _error = "Cannot add reminder: Patient profile not available.";
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    final newReminderData = Reminder(
      reminderId: '', // Placeholder
      patientId: patientId,
      reminderType: reminderType,
      reminderTime: reminderTime,
      frequency: frequency,
      message: message,
      isActive: isActive,
      createdAt: DateTime.now(), // Placeholder
      updatedAt: DateTime.now(), // Placeholder
    );

    try {
      final addedReminder = await _supabaseService.addReminder(newReminderData);
      if (addedReminder != null) {
        _reminders.add(addedReminder);
        _reminders.sort(
          (a, b) => _compareTimeOfDay(a.reminderTime, b.reminderTime),
        ); // Keep sorted
        if (addedReminder.isActive) {
          await _notificationService.scheduleDailyReminderNotification(
            addedReminder,
          ); // Schedule notification
        }
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = "Failed to add reminder.";
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = "Error adding reminder: $e";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateReminder(Reminder updatedReminderData) async {
    final patientId = _authProvider.patientProfile?.patientId;
    if (patientId == null || updatedReminderData.patientId != patientId) {
      _error =
          "Cannot update reminder: Patient mismatch or profile unavailable.";
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedReminder = await _supabaseService.updateReminder(
        updatedReminderData,
      );
      if (updatedReminder != null) {
        final index = _reminders.indexWhere(
          (r) => r.reminderId == updatedReminder.reminderId,
        );
        if (index != -1) {
          _reminders[index] = updatedReminder;
          _reminders.sort(
            (a, b) => _compareTimeOfDay(a.reminderTime, b.reminderTime),
          ); // Keep sorted

          // Reschedule or cancel notification based on active status
          if (updatedReminder.isActive) {
            await _notificationService.scheduleDailyReminderNotification(
              updatedReminder,
            );
          } else {
            await _notificationService.cancelNotification(
              updatedReminder.reminderId,
            );
          }
        }
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = "Failed to update reminder.";
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = "Error updating reminder: $e";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleReminderActive(Reminder reminder) async {
    final updatedReminder = Reminder(
      reminderId: reminder.reminderId,
      patientId: reminder.patientId,
      reminderType: reminder.reminderType,
      reminderTime: reminder.reminderTime,
      frequency: reminder.frequency,
      message: reminder.message,
      isActive: !reminder.isActive, // Toggle the status
      createdAt: reminder.createdAt,
      updatedAt: DateTime.now(), // Will be updated by trigger anyway
    );
    return await updateReminder(updatedReminder);
  }

  Future<bool> deleteReminder(String reminderId) async {
    final patientId = _authProvider.patientProfile?.patientId;
    if (patientId == null) return false; // Or handle error

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _supabaseService.deleteReminder(reminderId);
      _reminders.removeWhere((r) => r.reminderId == reminderId);
      await _notificationService.cancelNotification(
        reminderId,
      ); // Cancel notification
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = "Error deleting reminder: $e";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Helper to compare TimeOfDay for sorting
  int _compareTimeOfDay(TimeOfDay a, TimeOfDay b) {
    if (a.hour != b.hour) {
      return a.hour.compareTo(b.hour);
    }
    return a.minute.compareTo(b.minute);
  }

  @override
  void dispose() {
    _authProvider.removeListener(_handleAuthChange); // Clean up listener
    super.dispose();
  }
}
