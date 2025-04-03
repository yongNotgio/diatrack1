// --- lib/models/health_metric.dart ---
import 'package:flutter/foundation.dart';

@immutable
class HealthMetric {
  final String metricId;
  final String patientId;
  final double? glucoseFasting;
  final double? glucosePostprandial;
  final int? bloodPressureSystolic;
  final int? bloodPressureDiastolic;
  final int? pulseRate;
  final DateTime submissionDate;

  const HealthMetric({
    required this.metricId,
    required this.patientId,
    this.glucoseFasting,
    this.glucosePostprandial,
    this.bloodPressureSystolic,
    this.bloodPressureDiastolic,
    this.pulseRate,
    required this.submissionDate,
  });

  factory HealthMetric.fromJson(Map<String, dynamic> json) {
    return HealthMetric(
      metricId: json['metric_id'] as String,
      patientId: json['patient_id'] as String,
      // Use double.tryParse for numeric fields from Supabase
      glucoseFasting: (json['glucose_fasting'] as num?)?.toDouble(),
      glucosePostprandial: (json['glucose_postprandial'] as num?)?.toDouble(),
      bloodPressureSystolic: json['blood_pressure_systolic'] as int?,
      bloodPressureDiastolic: json['blood_pressure_diastolic'] as int?,
      pulseRate: json['pulse_rate'] as int?,
      submissionDate: DateTime.parse(json['submission_date'] as String),
    );
  }

  // For inserting new data
  Map<String, dynamic> toJsonForInsert(String currentPatientId) {
    return {
      'patient_id': currentPatientId,
      'glucose_fasting': glucoseFasting,
      'glucose_postprandial': glucosePostprandial,
      'blood_pressure_systolic': bloodPressureSystolic,
      'blood_pressure_diastolic': bloodPressureDiastolic,
      'pulse_rate': pulseRate,
      // submission_date has default in SQL
    };
  }
}
