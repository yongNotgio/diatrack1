// --- lib/models/patient.dart ---
import 'package:flutter/foundation.dart';

@immutable
class Patient {
  final String patientId;
  final String userId;
  final String firstName;
  final String lastName;
  final String? middleName;
  final int? age;
  final String? contactInfo;
  final String email;
  final String? preferredDoctorId;
  final String? riskLevel;
  final DateTime registrationDate;

  const Patient({
    required this.patientId,
    required this.userId,
    required this.firstName,
    required this.lastName,
    this.middleName,
    this.age,
    this.contactInfo,
    required this.email,
    this.preferredDoctorId,
    this.riskLevel,
    required this.registrationDate,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      patientId: json['patient_id'] as String,
      userId: json['user_id'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      middleName: json['middle_name'] as String?,
      age: json['age'] as int?,
      contactInfo: json['contact_info'] as String?,
      email: json['email'] as String,
      preferredDoctorId: json['preferred_doctor_id'] as String?,
      riskLevel: json['risk_level'] as String?,
      registrationDate: DateTime.parse(json['registration_date'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patient_id': patientId,
      'user_id': userId,
      'first_name': firstName,
      'last_name': lastName,
      'middle_name': middleName,
      'age': age,
      'contact_info': contactInfo,
      'email': email,
      'preferred_doctor_id': preferredDoctorId,
      'risk_level': riskLevel,
      'registration_date': registrationDate.toIso8601String(),
    };
  }

  // Helper method for creating a new patient record before ID is assigned
  Map<String, dynamic> toJsonForInsert(String authUserId) {
    return {
      'user_id': authUserId, // Use the auth user ID
      'first_name': firstName,
      'last_name': lastName,
      'middle_name': middleName,
      'age': age,
      'contact_info': contactInfo,
      'email': email,
      'preferred_doctor_id': preferredDoctorId,
      'risk_level': riskLevel,
      // registration_date has a default value in SQL
    };
  }
}
