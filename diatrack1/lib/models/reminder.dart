// --- lib/models/reminder.dart ---
import 'package:flutter/material.dart'; // For TimeOfDay
import 'package:intl/intl.dart'; // For date/time formatting

@immutable
class Reminder {
  final String reminderId;
  final String patientId;
  final String reminderType;
  final TimeOfDay reminderTime; // Store as TimeOfDay for easier UI handling
  final String? frequency;
  final String? message;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Reminder({
    required this.reminderId,
    required this.patientId,
    required this.reminderType,
    required this.reminderTime,
    this.frequency,
    this.message,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Reminder.fromJson(Map<String, dynamic> json) {
    // Parse time string 'HH:mm:ss' into TimeOfDay
    final timeParts = (json['reminder_time'] as String).split(':');
    final time = TimeOfDay(
      hour: int.parse(timeParts[0]),
      minute: int.parse(timeParts[1]),
    );

    return Reminder(
      reminderId: json['reminder_id'] as String,
      patientId: json['patient_id'] as String,
      reminderType: json['reminder_type'] as String,
      reminderTime: time,
      frequency: json['frequency'] as String?,
      message: json['message'] as String?,
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  // For inserting new data
  Map<String, dynamic> toJsonForInsert(String currentPatientId) {
    // Format TimeOfDay back to 'HH:mm:ss' string for Supabase TIME type
    final formattedTime =
        '${reminderTime.hour.toString().padLeft(2, '0')}:${reminderTime.minute.toString().padLeft(2, '0')}:00';

    return {
      'patient_id': currentPatientId,
      'reminder_type': reminderType,
      'reminder_time': formattedTime,
      'frequency': frequency,
      'message': message,
      'is_active': isActive,
      // created_at and updated_at have defaults in SQL
    };
  }

  // For updating existing data
  Map<String, dynamic> toJsonForUpdate() {
    // Format TimeOfDay back to 'HH:mm:ss' string for Supabase TIME type
    final formattedTime =
        '${reminderTime.hour.toString().padLeft(2, '0')}:${reminderTime.minute.toString().padLeft(2, '0')}:00';
    return {
      // Don't include patient_id or reminder_id in update payload usually
      'reminder_type': reminderType,
      'reminder_time': formattedTime,
      'frequency': frequency,
      'message': message,
      'is_active': isActive,
      // updated_at is handled by the trigger
    };
  }
}
