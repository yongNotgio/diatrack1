import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

final supabase = Supabase.instance.client;

class SupabaseService {
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

  Future<void> addHealthMetric({
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
        'pulse_rate': pulseRate,
        'wound_photo_url': woundPhotoUrl,
        'food_photo_url': foodPhotoUrl,
        'notes': notes,
        'updated_at': now,
      };

      if (metricId == null) {
        // For new entries, set both submission_date and updated_at to current time
        data['submission_date'] = now;
        await supabase.from('health_metrics').insert(data);
      } else {
        // For updates, only update the fields and updated_at timestamp
        await supabase.from('health_metrics').update(data).eq('id', metricId);
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
}
