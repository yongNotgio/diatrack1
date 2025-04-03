// --- lib/services/supabase_service.dart ---
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/patient.dart';
import '../models/health_metric.dart';
import '../models/reminder.dart';
import '../config/supabase_config.dart'; // Import config

class SupabaseService {
  final SupabaseClient _client;

  // Private constructor
  SupabaseService._(this._client);

  // Static instance variable
  static SupabaseService? _instance;

  // Static method to get the instance
  static Future<SupabaseService> getInstance() async {
    if (_instance == null) {
      // Initialize Supabase if it hasn't been initialized yet
      // This check might be redundant if initialization is guaranteed in main.dart
      if (Supabase.instance.client == null) {
        await Supabase.initialize(
          url: SUPABASE_URL,
          anonKey: SUPABASE_ANON_KEY,
        );
      }
      _instance = SupabaseService._(Supabase.instance.client);
    }
    return _instance!;
  }

  // Expose the Supabase client if needed elsewhere (e.g., for auth state changes)
  SupabaseClient get client => _client;

  // --- Authentication ---

  Future<AuthResponse> signUp(String email, String password) async {
    return await _client.auth.signUp(email: email, password: password);
  }

  Future<AuthResponse> signIn(String email, String password) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  User? getCurrentUser() {
    return _client.auth.currentUser;
  }

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // --- Patient ---

  // Fetch patient data based on the logged-in user's ID
  Future<Patient?> getPatientProfile() async {
    final user = getCurrentUser();
    if (user == null) return null;

    try {
      final response =
          await _client
              .from('patients')
              .select()
              .eq('user_id', user.id)
              .single(); // Expecting only one patient record per user

      return Patient.fromJson(response);
    } catch (e) {
      print('Error fetching patient profile: $e');
      // Handle potential errors, like PostgrestException if no record found
      // or multiple records found (though 'unique' constraint should prevent this)
      return null;
    }
  }

  // Create a new patient record after signup
  Future<Patient?> createPatientProfile(Patient patientData) async {
    final user = getCurrentUser();
    if (user == null) throw Exception("User not logged in");

    try {
      final response =
          await _client
              .from('patients')
              .insert(patientData.toJsonForInsert(user.id))
              .select() // Return the created record
              .single();
      return Patient.fromJson(response);
    } catch (e) {
      print('Error creating patient profile: $e');
      return null;
    }
  }

  // --- Health Metrics ---

  Future<List<HealthMetric>> getHealthMetrics(String patientId) async {
    try {
      final response = await _client
          .from('health_metrics')
          .select()
          .eq('patient_id', patientId)
          .order('submission_date', ascending: false); // Show newest first

      return response.map((json) => HealthMetric.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching health metrics: $e');
      return []; // Return empty list on error
    }
  }

  Future<HealthMetric?> addHealthMetric(HealthMetric metricData) async {
    // We need the patient_id associated with the current user
    // This assumes the patient profile is already fetched and available
    // In a real app, you'd likely get this from your AuthProvider/PatientProvider
    // For now, let's assume it's passed correctly in metricData.patientId

    try {
      final response =
          await _client
              .from('health_metrics')
              .insert(
                metricData.toJsonForInsert(metricData.patientId),
              ) // Pass patientId here
              .select()
              .single();
      return HealthMetric.fromJson(response);
    } catch (e) {
      print('Error adding health metric: $e');
      return null;
    }
  }

  // --- Reminders ---

  Future<List<Reminder>> getReminders(String patientId) async {
    try {
      final response = await _client
          .from('reminders')
          .select()
          .eq('patient_id', patientId)
          .order('reminder_time', ascending: true); // Order by time

      return response.map((json) => Reminder.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching reminders: $e');
      return [];
    }
  }

  Future<Reminder?> addReminder(Reminder reminderData) async {
    // Similar to addHealthMetric, ensure reminderData.patientId is set correctly
    try {
      final response =
          await _client
              .from('reminders')
              .insert(reminderData.toJsonForInsert(reminderData.patientId))
              .select()
              .single();
      return Reminder.fromJson(response);
    } catch (e) {
      print('Error adding reminder: $e');
      return null;
    }
  }

  Future<Reminder?> updateReminder(Reminder reminderData) async {
    try {
      final response =
          await _client
              .from('reminders')
              .update(reminderData.toJsonForUpdate())
              .eq(
                'reminder_id',
                reminderData.reminderId,
              ) // Match the specific reminder
              .select()
              .single();
      return Reminder.fromJson(response);
    } catch (e) {
      print('Error updating reminder: $e');
      return null;
    }
  }

  Future<void> deleteReminder(String reminderId) async {
    try {
      await _client.from('reminders').delete().eq('reminder_id', reminderId);
    } catch (e) {
      print('Error deleting reminder: $e');
    }
  }
}
