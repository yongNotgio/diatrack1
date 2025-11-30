import 'dart:io';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

final supabase = Supabase.instance.client;

class SupabaseService {
  /// Classifies blood pressure based on systolic and diastolic values.
  String classifyBloodPressure(int systolic, int diastolic) {
    if (systolic > 180 || diastolic > 120) return 'CRISIS';
    if (systolic >= 140 || diastolic >= 90) return 'HIGH';
    if (systolic >= 130 || diastolic >= 80) return 'ELEVATED';
    if (systolic < 120 && diastolic < 80) return 'NORMAL';
    return 'ELEVATED';
  }

  final ImagePicker _picker = ImagePicker();

  Future<Map<String, dynamic>?> signUpPatient({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String? preferredDoctorId,
    DateTime? dateOfBirth,
    String? contactInfo,
    required String? surgicalStatus,
  }) async {
    try {
      final response =
          await supabase
              .from('patients')
              .insert({
                'first_name': firstName,
                'last_name': lastName,
                'email': email.trim().toLowerCase(),
                'password': password,
                'preferred_doctor_id': preferredDoctorId,
                'date_of_birth': dateOfBirth?.toIso8601String(),
                'contact_info': contactInfo,
                'phase': surgicalStatus,
              })
              .select()
              .single();
      return response;
    } on PostgrestException catch (error) {
      if (error.code == '23505') {
        throw Exception('Email already exists.');
      }
      throw Exception('Sign up failed: ${error.message}');
    } catch (e) {
      throw Exception('An unexpected error occurred during sign up.');
    }
  }

  Future<Map<String, dynamic>?> loginPatient({
    required String email,
    required String password,
  }) async {
    try {
      final response =
          await supabase
              .from('patients')
              .select('''
            *,
            doctor:preferred_doctor_id (
              first_name,
              last_name
            )
          ''')
              .eq('email', email.trim().toLowerCase())
              .eq('password', password)
              .single();

      // Add doctor name to patient data
      if (response != null && response['doctor'] != null) {
        response['doctor_name'] =
            '${response['doctor']['first_name']} ${response['doctor']['last_name']}';
      }

      return response;
    } on PostgrestException catch (error) {
      if (error.code == 'PGRST116') {
        throw Exception('Invalid email or password.');
      }
      throw Exception('Login failed: ${error.message}');
    } catch (e) {
      throw Exception('An unexpected error occurred during login.');
    }
  }

  Future<List<Map<String, dynamic>>> getDoctors() async {
    try {
      final response = await supabase
          .from('doctors')
          .select('doctor_id, first_name, last_name, specialization');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<String?> addHealthMetric({
    required String patientId,
    double? bloodGlucose,
    int? bpSystolic,
    int? bpDiastolic,
    int? pulseRate,
    String? woundPhotoUrl,
    String? foodPhotoUrl,
    String? notes,
    String? metricId,
  }) async {
    try {
      final now = DateTime.now().toIso8601String();
      final data = {
        'patient_id': patientId,
        'blood_glucose': bloodGlucose,
        'bp_systolic': bpSystolic,
        'bp_diastolic': bpDiastolic,
        'bp_classification':
            bpSystolic != null && bpDiastolic != null
                ? classifyBloodPressure(bpSystolic, bpDiastolic)
                : null,
        'pulse_rate': pulseRate,
        'wound_photo_url': woundPhotoUrl,
        'food_photo_url': foodPhotoUrl,
        'notes': notes,
        'updated_at': now,
      };

      if (metricId == null) {
        // For new entries, set both submission_date and updated_at to current time
        data['submission_date'] = now;
        final response =
            await supabase
                .from('health_metrics')
                .insert(data)
                .select('metric_id')
                .single();
        return response['metric_id'] as String?;
      } else {
        // For updates, only update the fields and updated_at timestamp
        await supabase
            .from('health_metrics')
            .update(data)
            .eq('metric_id', metricId);
        return metricId;
      }
    } catch (e) {
      throw Exception('Failed to save health metric: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getHealthMetrics(String patientId) async {
    try {
      final response = await supabase
          .from('health_metrics')
          .select()
          .eq('patient_id', patientId)
          .order('submission_date', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch health metrics: $e');
    }
  }

  Future<void> deleteHealthMetric(String metricId) async {
    try {
      await supabase.from('health_metrics').delete().eq('metric_id', metricId);
    } on PostgrestException catch (e) {
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to delete health metric: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> updateHealthMetric({
    required String metricId,
    double? bloodGlucose,
    int? bpSystolic,
    int? bpDiastolic,
    int? pulseRate,
    String? woundPhotoUrl,
    String? foodPhotoUrl,
    String? notes,
  }) async {
    try {
      final now = DateTime.now().toIso8601String();
      final data = {
        'blood_glucose': bloodGlucose,
        'bp_systolic': bpSystolic,
        'bp_diastolic': bpDiastolic,
        'bp_classification':
            bpSystolic != null && bpDiastolic != null
                ? classifyBloodPressure(bpSystolic, bpDiastolic)
                : null,
        'pulse_rate': pulseRate,
        'wound_photo_url': woundPhotoUrl,
        'food_photo_url': foodPhotoUrl,
        'notes': notes,
        'updated_at': now,
      };

      final response =
          await supabase
              .from('health_metrics')
              .update(data)
              .eq('metric_id', metricId)
              .select()
              .single();

      return response;
    } catch (e) {
      throw Exception('Failed to update health metric: $e');
    }
  }

  // Future<void> deleteHealthMetric(String metricId) async {
  //   try {
  //     final response =
  //         await supabase
  //             .from('health_metrics')
  //             .delete()
  //             .eq('id', metricId)
  //             .select();

  //     if (response.isEmpty) {
  //       throw Exception('No record found with ID: $metricId');
  //     }
  //   } on PostgrestException catch (e) {
  //     throw Exception('Database error: ${e.message}');
  //   } catch (e) {
  //     throw Exception('Failed to delete health metric: ${e.toString()}');
  //   }
  // }
  Future<Map<String, dynamic>?> getUpcomingAppointment(String patientId) async {
    final response =
        await supabase
            .from('appointments')
            .select(
              'appointment_datetime, doctor:doctor_id(first_name, last_name)',
            )
            .eq('patient_id', patientId)
            .gte('appointment_datetime', DateTime.now().toIso8601String())
            .order('appointment_datetime', ascending: true)
            .limit(1)
            .maybeSingle();

    if (response == null || response.isEmpty) {
      return null;
    }

    final appointmentDatetime = response['appointment_datetime'];
    final doctor = response['doctor'];

    String doctorName = 'Unknown Doctor';
    if (doctor != null &&
        doctor['first_name'] != null &&
        doctor['last_name'] != null) {
      doctorName = '${doctor['first_name']} ${doctor['last_name']}';
    }

    return {
      'appointment_datetime': appointmentDatetime,
      'doctor_name': doctorName,
    };
  }

  Future<XFile?> pickImage(ImageSource source) async {
    try {
      return await _picker.pickImage(source: source);
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }

  Future<String?> uploadImage(
    XFile imageFile,
    String bucketName,
    String patientId,
  ) async {
    try {
      final fileExt = imageFile.path.split('.').last;
      final fileName =
          '${patientId}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = '$patientId/$fileName';

      await supabase.storage
          .from(bucketName)
          .upload(
            filePath,
            File(imageFile.path),
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      return supabase.storage.from(bucketName).getPublicUrl(filePath);
    } on StorageException catch (error) {
      if (error.message.contains('Bucket not found')) {
        throw Exception('Storage bucket "$bucketName" not found.');
      }
      throw Exception('Failed to upload image: ${error.message}');
    } catch (e) {
      throw Exception('Image upload failed: $e');
    }
  }

  Future<void> deleteImage(String photoUrl) async {
    try {
      final uri = Uri.parse(photoUrl);
      final pathSegments = uri.pathSegments;
      final bucket = pathSegments[1];
      final path = pathSegments.sublist(2).join('/');

      await supabase.storage.from(bucket).remove([path]);
    } catch (e) {
      throw Exception('Failed to delete image: $e');
    }
  }

  /// Upload patient profile picture to Supabase storage and update the patient record
  Future<String> updatePatientProfilePicture({
    required String patientId,
    required XFile imageFile,
  }) async {
    try {
      // Upload image to patient-profile bucket
      final imageUrl = await uploadImage(
        imageFile,
        'patient-profile',
        patientId,
      );

      if (imageUrl == null) {
        throw Exception('Failed to upload image - received null URL');
      }

      // Update patient record with the new image URL
      await supabase
          .from('patients')
          .update({'patient_picture': imageUrl})
          .eq('patient_id', patientId);

      return imageUrl;
    } catch (e) {
      throw Exception('Failed to update profile picture: $e');
    }
  }

  /// Fetch notifications for a specific user
  Future<List<Map<String, dynamic>>> getNotifications(String userId) async {
    try {
      final response = await supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch notifications: $e');
    }
  }

  /// Mark a notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('notification_id', notificationId);
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  /// Mark all notifications as read for a user
  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      await supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  /// Get unread notification count for a user
  Future<int> getUnreadNotificationCount(String userId) async {
    try {
      final response = await supabase
          .from('notifications')
          .select('notification_id')
          .eq('user_id', userId)
          .eq('is_read', false);
      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  /// Get upcoming appointment with full details including secretary
  Future<Map<String, dynamic>?> getUpcomingAppointmentWithDetails(
    String patientId,
  ) async {
    final response =
        await supabase
            .from('appointments')
            .select('''
              appointment_id,
              appointment_datetime,
              notes,
              appointment_state,
              doctor:doctor_id(doctor_id, first_name, last_name),
              secretary:secretary_id(secretary_id, first_name, last_name)
            ''')
            .eq('patient_id', patientId)
            .gte('appointment_datetime', DateTime.now().toIso8601String())
            .neq('appointment_state', 'cancelled')
            .order('appointment_datetime', ascending: true)
            .limit(1)
            .maybeSingle();

    if (response == null || response.isEmpty) {
      return null;
    }

    return response;
  }

  /// Check if a time slot is available for a doctor
  /// Returns true if the slot is available, false if it's taken
  Future<bool> isTimeSlotAvailable({
    required String doctorId,
    required DateTime dateTime,
    String? excludeAppointmentId,
  }) async {
    try {
      // Check for appointments within 1 hour of the requested time
      final startTime = dateTime.subtract(const Duration(hours: 1));
      final endTime = dateTime.add(const Duration(hours: 1));

      var query = supabase
          .from('appointments')
          .select('appointment_id')
          .eq('doctor_id', doctorId)
          .neq('appointment_state', 'cancelled')
          .gte('appointment_datetime', startTime.toIso8601String())
          .lte('appointment_datetime', endTime.toIso8601String());

      // Exclude current appointment if rescheduling
      if (excludeAppointmentId != null) {
        query = query.neq('appointment_id', excludeAppointmentId);
      }

      final response = await query;
      return response.isEmpty;
    } catch (e) {
      throw Exception('Failed to check time slot availability: $e');
    }
  }

  /// Create a new appointment
  Future<void> createAppointment({
    required String patientId,
    required String patientName,
    required String doctorId,
    required DateTime appointmentDateTime,
    String? secretaryId,
    String? notes,
  }) async {
    try {
      // First check if the time slot is available
      final isAvailable = await isTimeSlotAvailable(
        doctorId: doctorId,
        dateTime: appointmentDateTime,
      );

      if (!isAvailable) {
        throw Exception(
          'This time slot is already taken. Please choose a different time.',
        );
      }

      // Get secretary linked to this doctor if not provided
      String? effectiveSecretaryId = secretaryId;
      if (effectiveSecretaryId == null) {
        final secretaryLink =
            await supabase
                .from('secretary_doctor_links')
                .select('secretary_id')
                .eq('doctor_id', doctorId)
                .limit(1)
                .maybeSingle();

        if (secretaryLink != null) {
          effectiveSecretaryId = secretaryLink['secretary_id']?.toString();
        }
      }

      // Create the appointment
      final response =
          await supabase
              .from('appointments')
              .insert({
                'patient_id': patientId,
                'doctor_id': doctorId,
                'secretary_id': effectiveSecretaryId,
                'appointment_datetime': appointmentDateTime.toIso8601String(),
                'date_set': DateTime.now().toIso8601String(),
                'appointment_state': 'scheduled',
                'notes': notes,
              })
              .select('appointment_id')
              .single();

      final appointmentId = response['appointment_id'];

      // Notify secretary if available
      if (effectiveSecretaryId != null) {
        await supabase.from('notifications').insert({
          'user_id': effectiveSecretaryId,
          'user_role': 'secretary',
          'title': 'New Appointment Scheduled',
          'message':
              '$patientName has scheduled an appointment for ${_formatDateTimeForNotification(appointmentDateTime)}.',
          'type': 'appointment',
          'reference_id': appointmentId,
          'is_read': false,
        });
      }

      // Log the creation in audit_logs
      await supabase.from('audit_logs').insert({
        'actor_type': 'patient',
        'actor_id': patientId,
        'actor_name': patientName,
        'module': 'appointments',
        'action_type': 'schedule',
        'new_value': appointmentDateTime.toIso8601String(),
        'source_page': 'home_screen',
      });
    } catch (e) {
      if (e.toString().contains('already taken')) {
        rethrow;
      }
      throw Exception('Failed to create appointment: $e');
    }
  }

  /// Cancel an appointment and notify secretary
  Future<void> cancelAppointment({
    required String appointmentId,
    required String patientId,
    required String patientName,
    String? secretaryId,
    String? originalDateTime,
  }) async {
    try {
      // Update appointment state to cancelled
      await supabase
          .from('appointments')
          .update({'appointment_state': 'cancelled'})
          .eq('appointment_id', appointmentId);

      // Create notification for secretary if secretary_id is available
      if (secretaryId != null) {
        await supabase.from('notifications').insert({
          'user_id': secretaryId,
          'user_role': 'secretary',
          'title': 'Appointment Cancelled',
          'message':
              '$patientName has cancelled their appointment scheduled for $originalDateTime.',
          'type': 'appointment',
          'reference_id': appointmentId,
          'is_read': false,
        });
      }

      // Log the cancellation in audit_logs
      await supabase.from('audit_logs').insert({
        'actor_type': 'patient',
        'actor_id': patientId,
        'actor_name': patientName,
        'module': 'appointments',
        'action_type': 'cancel',
        'old_value': originalDateTime,
        'new_value': 'cancelled',
        'source_page': 'home_screen',
      });
    } catch (e) {
      throw Exception('Failed to cancel appointment: $e');
    }
  }

  /// Reschedule an appointment and notify secretary
  Future<void> rescheduleAppointment({
    required String appointmentId,
    required String patientId,
    required String patientName,
    required DateTime newDateTime,
    required String doctorId,
    String? secretaryId,
    String? originalDateTime,
  }) async {
    try {
      // First check if the new time slot is available
      final isAvailable = await isTimeSlotAvailable(
        doctorId: doctorId,
        dateTime: newDateTime,
        excludeAppointmentId: appointmentId,
      );

      if (!isAvailable) {
        throw Exception(
          'This time slot is already taken. Please choose a different time.',
        );
      }

      // Update appointment with new datetime
      await supabase
          .from('appointments')
          .update({
            'appointment_datetime': newDateTime.toIso8601String(),
            'appointment_state': 'rescheduled',
          })
          .eq('appointment_id', appointmentId);

      // Create notification for secretary if secretary_id is available
      if (secretaryId != null) {
        await supabase.from('notifications').insert({
          'user_id': secretaryId,
          'user_role': 'secretary',
          'title': 'Appointment Rescheduled',
          'message':
              '$patientName has rescheduled their appointment from $originalDateTime to ${_formatDateTimeForNotification(newDateTime)}.',
          'type': 'appointment',
          'reference_id': appointmentId,
          'is_read': false,
        });
      }

      // Log the reschedule in audit_logs
      await supabase.from('audit_logs').insert({
        'actor_type': 'patient',
        'actor_id': patientId,
        'actor_name': patientName,
        'module': 'appointments',
        'action_type': 'reschedule',
        'old_value': originalDateTime,
        'new_value': newDateTime.toIso8601String(),
        'source_page': 'home_screen',
      });
    } catch (e) {
      if (e.toString().contains('already taken')) {
        rethrow;
      }
      throw Exception('Failed to reschedule appointment: $e');
    }
  }

  String _formatDateTimeForNotification(DateTime dt) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} at $hour:${dt.minute.toString().padLeft(2, '0')} $amPm';
  }

  /// Assess surgical risk for a patient
  Future<Map<String, dynamic>> assessSurgicalRisk({
    required String patientId,
    String? metricId,
  }) async {
    try {
      // Fetch patient data to get age, comorbidities, and BMI
      final patientResponse =
          await supabase
              .from('patients')
              .select('date_of_birth, complication_history, BMI')
              .eq('patient_id', patientId)
              .single();

      // Fetch health metrics - either specific metric or latest one
      Map<String, dynamic> metricsResponse;
      if (metricId != null) {
        metricsResponse =
            await supabase
                .from('health_metrics')
                .select('metric_id, blood_glucose, bp_systolic')
                .eq('metric_id', metricId)
                .single();
      } else {
        metricsResponse =
            await supabase
                .from('health_metrics')
                .select('metric_id, blood_glucose, bp_systolic')
                .eq('patient_id', patientId)
                .order('submission_date', ascending: false)
                .limit(1)
                .single();
      }

      // Calculate age
      final dateOfBirth = DateTime.parse(patientResponse['date_of_birth']);
      final age = DateTime.now().difference(dateOfBirth).inDays ~/ 365;

      // Get glucose in mmol/L (convert from mg/dL)
      final glucoseMgDl = metricsResponse['blood_glucose'];
      final glucoseMmol =
          glucoseMgDl != null
              ? (glucoseMgDl is num ? glucoseMgDl.toDouble() / 18 : null)
              : null;

      // Get systolic BP
      final systolicBpRaw = metricsResponse['bp_systolic'];
      final systolicBp = systolicBpRaw is num ? systolicBpRaw.toInt() : null;

      // Get BMI from patients table
      final bmiRaw = patientResponse['BMI'];
      final bmi = bmiRaw is num ? bmiRaw.toDouble() : null;

      // Count comorbidities
      final complicationHistoryRaw = patientResponse['complication_history'];
      final targetComorbidities = [
        'Stroke',
        'Hypertensive',
        'Family Diabetes',
        'Family Hypertension',
        'Cardiovascular',
      ];
      int comorbiditiesCount = 0;

      if (complicationHistoryRaw != null) {
        List<dynamic> complicationHistory;

        // Handle if it's a String (JSON) or already a List
        if (complicationHistoryRaw is String) {
          try {
            complicationHistory =
                json.decode(complicationHistoryRaw) as List<dynamic>;
          } catch (e) {
            complicationHistory = [];
          }
        } else if (complicationHistoryRaw is List) {
          complicationHistory = complicationHistoryRaw;
        } else {
          complicationHistory = [];
        }

        for (var complication in complicationHistory) {
          if (targetComorbidities.contains(complication)) {
            comorbiditiesCount++;
          }
        }
      }

      // Prepare API request - ensure all values are proper types
      final requestBody = {
        'age': age,
        'glucose': glucoseMmol?.toDouble() ?? 0.0,
        'systolic_bp': systolicBp ?? 0,
        'bmi': bmi ?? 0.0,
        'comorbidities': comorbiditiesCount,
      };

      // Call the risk assessment API via ngrok
      final apiResponse = await http.post(
        Uri.parse(
          'https://faultily-flighty-joellen.ngrok-free.dev/api/v1/assess-risk',
        ),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: json.encode(requestBody),
      );

      if (apiResponse.statusCode == 200) {
        final riskData = json.decode(apiResponse.body) as Map<String, dynamic>;

        // Save risk classification to health_metrics table
        final riskLevel = riskData['risk_category']?['level'] as String?;
        if (riskLevel != null) {
          try {
            // Extract just the risk level without "Risk" text
            String riskClassification;
            if (riskLevel.toLowerCase().contains('high')) {
              riskClassification = 'high';
            } else if (riskLevel.toLowerCase().contains('moderate')) {
              riskClassification = 'moderate';
            } else if (riskLevel.toLowerCase().contains('low')) {
              riskClassification = 'low';
            } else {
              riskClassification = 'moderate'; // default
            }

            // Get the risk score from the response
            final riskScoreValue = riskData['risk_score'];
            double? riskScoreDouble;
            if (riskScoreValue is num) {
              riskScoreDouble = riskScoreValue.toDouble();
            }

            await supabase
                .from('health_metrics')
                .update({
                  'risk_classification': riskClassification,
                  'risk_score': riskScoreDouble,
                })
                .eq('metric_id', metricsResponse['metric_id']);
          } catch (e) {
            // Don't fail the entire request if saving fails
            print('Failed to save risk classification: $e');
          }
        }

        return riskData;
      } else {
        throw Exception(
          'Risk assessment failed: ${apiResponse.statusCode} - ${apiResponse.body}',
        );
      }
    } catch (e) {
      throw Exception('Failed to assess surgical risk: $e');
    }
  }

  /// Check if a patient email exists and return patient data
  Future<Map<String, dynamic>?> getPatientByEmail(String email) async {
    try {
      final response =
          await supabase
              .from('patients')
              .select(
                'patient_id, first_name, last_name, email, preferred_doctor_id',
              )
              .eq('email', email.toLowerCase().trim())
              .maybeSingle();
      return response;
    } catch (e) {
      return null;
    }
  }

  /// Reset patient password
  Future<bool> resetPatientPassword({
    required String patientId,
    required String newPassword,
  }) async {
    try {
      await supabase
          .from('patients')
          .update({'password': newPassword})
          .eq('patient_id', patientId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get secretary for a patient's preferred doctor
  Future<Map<String, dynamic>?> getSecretaryForDoctor(String doctorId) async {
    try {
      final response =
          await supabase
              .from('secretary_doctor_links')
              .select(
                'secretary:secretary_id(secretary_id, first_name, last_name)',
              )
              .eq('doctor_id', doctorId)
              .limit(1)
              .maybeSingle();

      if (response != null && response['secretary'] != null) {
        return response['secretary'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Notify secretary about patient password reset
  Future<void> notifySecretaryPasswordReset({
    required String secretaryId,
    required String patientName,
    required String patientId,
  }) async {
    try {
      await supabase.from('notifications').insert({
        'user_id': secretaryId,
        'user_role': 'secretary',
        'title': 'Patient Password Reset',
        'message': '$patientName has reset their password.',
        'type': 'patient',
        'reference_id': patientId,
        'is_read': false,
      });

      // Log to audit
      await supabase.from('audit_logs').insert({
        'actor_type': 'patient',
        'actor_id': patientId,
        'actor_name': patientName,
        'user_id': patientId,
        'module': 'credentials',
        'action_type': 'reset',
        'new_value': 'Password reset by patient',
        'source_page': 'forgot_password_screen',
      });
    } catch (e) {
      // Silent fail for notification
    }
  }
}
