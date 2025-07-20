class HealthMetric {
  final String id;
  final String patientId;
  final double? bloodGlucose;
  final int? bpSystolic;
  final int? bpDiastolic;
  final int? pulseRate;
  final String? woundPhotoUrl;
  final String? foodPhotoUrl;
  final String? notes;
  final DateTime submissionDate;
  final DateTime updatedAt;

  HealthMetric({
    required this.id,
    required this.patientId,
    this.bloodGlucose,
    this.bpSystolic,
    this.bpDiastolic,
    this.pulseRate,
    this.woundPhotoUrl,
    this.foodPhotoUrl,
    this.notes,
    required this.submissionDate,
    required this.updatedAt,
  });

  factory HealthMetric.fromMap(Map<String, dynamic> map) {
    return HealthMetric(
      id: map['id'] ?? '',
      patientId: map['patient_id'] ?? '',
      bloodGlucose: map['blood_glucose']?.toDouble(),
      bpSystolic: map['bp_systolic'],
      bpDiastolic: map['bp_diastolic'],
      pulseRate: map['pulse_rate'],
      woundPhotoUrl: map['wound_photo_url'],
      foodPhotoUrl: map['food_photo_url'],
      notes: map['notes'],
      submissionDate: DateTime.parse(map['submission_date']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patient_id': patientId,
      'blood_glucose': bloodGlucose,
      'bp_systolic': bpSystolic,
      'bp_diastolic': bpDiastolic,
      'pulse_rate': pulseRate,
      'wound_photo_url': woundPhotoUrl,
      'food_photo_url': foodPhotoUrl,
      'notes': notes,
      'submission_date': submissionDate.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get riskClassification {
    if (bpSystolic == null || bpDiastolic == null) return 'UNKNOWN';

    if (bpSystolic! < 130 && bpDiastolic! < 85) return 'LOW';
    if (bpSystolic! < 140 && bpDiastolic! < 90) return 'MEDIUM';
    return 'HIGH';
  }

  String get glucoseClassification {
    if (bloodGlucose == null) return 'UNKNOWN';

    if (bloodGlucose! < 100) return 'Normal';
    if (bloodGlucose! < 126) return 'Prediabetes';
    return 'Diabetes';
  }
}
