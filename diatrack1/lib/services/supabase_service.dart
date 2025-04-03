import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

// Get a reference to the Supabase client
final supabase = Supabase.instance.client;

class SupabaseService {
  final ImagePicker _picker = ImagePicker();

  // --- Authentication (Manual - INSECURE) ---

  /// Attempts to sign up a new patient.
  /// WARNING: Stores password in plain text. Highly insecure.
  Future<Map<String, dynamic>?> signUpPatient({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String? preferredDoctorId, // Make sure this ID exists in 'doctors'
    DateTime? dateOfBirth,
    String? contactInfo,
  }) async {
    try {
      final response =
          await supabase
              .from('patients')
              .insert({
                'first_name': firstName,
                'last_name': lastName,
                'email': email.trim().toLowerCase(),
                'password':
                    password, // Storing plain text password - VERY BAD PRACTICE
                'preferred_doctor_id': preferredDoctorId,
                'date_of_birth': dateOfBirth?.toIso8601String(),
                'contact_info': contactInfo,
              })
              .select() // Select the newly created record
              .single(); // Expect only one record

      print('Sign up successful: ${response}');
      return response; // Return patient data
    } on PostgrestException catch (error) {
      print('Supabase Sign Up Error: ${error.message}');
      // Handle specific errors like unique constraint violation (email exists)
      if (error.code == '23505') {
        // Unique violation code
        throw Exception('Email already exists.');
      }
      throw Exception('Sign up failed: ${error.message}');
    } catch (e) {
      print('General Sign Up Error: $e');
      throw Exception('An unexpected error occurred during sign up.');
    }
  }

  /// Attempts to log in a patient by checking email and plain text password.
  /// WARNING: Compares plain text passwords. Highly insecure.
  Future<Map<String, dynamic>?> loginPatient({
    required String email,
    required String password,
  }) async {
    try {
      final response =
          await supabase
              .from('patients')
              .select()
              .eq('email', email.trim().toLowerCase())
              .eq(
                'password',
                password,
              ) // Comparing plain text password - VERY BAD PRACTICE
              .single(); // Expect exactly one match

      print('Login successful for: ${response['email']}');
      return response; // Return patient data
    } on PostgrestException catch (error) {
      // Handle cases where no user is found or multiple users (shouldn't happen with unique email)
      if (error.code == 'PGRST116') {
        // PGRST116: JSON object requested, multiple (or no) rows returned
        print('Login Error: Invalid email or password.');
        throw Exception('Invalid email or password.');
      }
      print('Supabase Login Error: ${error.message}');
      throw Exception('Login failed: ${error.message}');
    } catch (e) {
      print('General Login Error: $e');
      throw Exception('An unexpected error occurred during login.');
    }
  }

  // --- Doctor Data ---

  /// Fetches all doctors for selection during signup.
  Future<List<Map<String, dynamic>>> getDoctors() async {
    try {
      final response = await supabase
          .from('doctors')
          .select('doctor_id, first_name, last_name, specialization');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching doctors: $e');
      return []; // Return empty list on error
    }
  }

  // --- Health Metrics ---

  /// Adds a new health metric record for a patient.
  Future<void> addHealthMetric({
    required String patientId,
    double? bloodGlucose,
    int? bpSystolic,
    int? bpDiastolic,
    int? pulseRate,
    String? woundPhotoUrl,
    String? foodPhotoUrl,
    String? notes,
  }) async {
    try {
      await supabase.from('health_metrics').insert({
        'patient_id': patientId,
        'blood_glucose': bloodGlucose,
        'bp_systolic': bpSystolic,
        'bp_diastolic': bpDiastolic,
        'pulse_rate': pulseRate,
        'wound_photo_url': woundPhotoUrl,
        'food_photo_url': foodPhotoUrl,
        'notes': notes,
        'submission_date':
            DateTime.now().toIso8601String(), // Record submission time
      });
      print('Health metric added successfully.');
    } catch (e) {
      print('Error adding health metric: $e');
      throw Exception('Failed to add health metric.');
    }
  }

  /// Fetches health metrics for a specific patient.
  Future<List<Map<String, dynamic>>> getHealthMetrics(String patientId) async {
    try {
      final response = await supabase
          .from('health_metrics')
          .select()
          .eq('patient_id', patientId)
          .order('submission_date', ascending: false); // Show newest first
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching health metrics: $e');
      return []; // Return empty list on error
    }
  }

  // --- Image Upload ---

  /// Picks an image from the gallery or camera.
  Future<XFile?> pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      return pickedFile;
    } catch (e) {
      print("Error picking image: $e");
      return null;
    }
  }

  /// Uploads an image file to Supabase Storage.
  /// Returns the public URL of the uploaded file.
  Future<String?> uploadImage(
    XFile imageFile,
    String bucketName,
    String patientId,
  ) async {
    try {
      final fileExt = imageFile.path.split('.').last;
      final fileName =
          '${patientId}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = '$patientId/$fileName'; // Organize files by patient ID

      // Upload the file
      await supabase.storage
          .from(bucketName)
          .upload(
            filePath,
            File(imageFile.path),
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: false,
            ), // Cache for 1 hour
          );

      // Get the public URL
      final imageUrlResponse = supabase.storage
          .from(bucketName)
          .getPublicUrl(filePath);

      print('Upload successful: $imageUrlResponse');
      return imageUrlResponse;
    } on StorageException catch (error) {
      print('Supabase Storage Error: ${error.message}');
      if (error.message.contains('Bucket not found')) {
        throw Exception(
          'Storage bucket "$bucketName" not found. Please create it in Supabase.',
        );
      }
      throw Exception('Failed to upload image: ${error.message}');
    } catch (e) {
      print('Error uploading image: $e');
      throw Exception('An unexpected error occurred during image upload.');
    }
  }
}
