// --- lib/providers/auth_provider.dart ---
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../models/patient.dart';

enum AuthStateEnum { unknown, authenticated, unauthenticated }

class AuthProvider with ChangeNotifier {
  final SupabaseService _supabaseService;
  StreamSubscription<AuthState>? _authStateSubscription;

  AuthStateEnum _authState = AuthStateEnum.unknown;
  AuthStateEnum get authState => _authState;

  User? _user;
  User? get user => _user;

  Patient? _patientProfile;
  Patient? get patientProfile => _patientProfile;
  bool _isLoadingProfile = false;
  bool get isLoadingProfile => _isLoadingProfile;

  // Constructor requires SupabaseService instance
  AuthProvider(this._supabaseService) {
    _initialize();
  }

  void _initialize() {
    _user = _supabaseService.getCurrentUser();
    if (_user != null) {
      _authState = AuthStateEnum.authenticated;
      _fetchPatientProfile(); // Fetch profile if already logged in
    } else {
      _authState = AuthStateEnum.unauthenticated;
    }
    notifyListeners(); // Notify initial state

    // Listen to auth state changes
    _authStateSubscription = _supabaseService.authStateChanges.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      _user = session?.user;

      if (event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.tokenRefreshed ||
          event == AuthChangeEvent.userUpdated) {
        if (_authState != AuthStateEnum.authenticated) {
          _authState = AuthStateEnum.authenticated;
          _fetchPatientProfile(); // Fetch profile on successful sign in
          notifyListeners();
        } else if (event == AuthChangeEvent.userUpdated) {
          _fetchPatientProfile(); // Re-fetch if user data might have changed
        }
      } else if (event == AuthChangeEvent.signedOut) {
        if (_authState != AuthStateEnum.unauthenticated) {
          _authState = AuthStateEnum.unauthenticated;
          _patientProfile = null; // Clear profile on sign out
          notifyListeners();
        }
      }
      // Handle other events like passwordRecovery if needed
    });
  }

  Future<void> _fetchPatientProfile() async {
    if (_user == null) return;
    _isLoadingProfile = true;
    notifyListeners();
    try {
      _patientProfile = await _supabaseService.getPatientProfile();
    } catch (e) {
      print("Error fetching profile in provider: $e");
      _patientProfile = null; // Ensure profile is null on error
    } finally {
      _isLoadingProfile = false;
      notifyListeners();
    }
  }

  Future<bool> signUp(
    String email,
    String password,
    String firstName,
    String lastName, {
    int? age,
    String? contactInfo,
  }) async {
    try {
      final authResponse = await _supabaseService.signUp(email, password);
      if (authResponse.user != null) {
        // Immediately try to create the patient profile
        // Use placeholder IDs initially, real IDs come from DB response
        final newPatientData = Patient(
          patientId: '', // Placeholder
          userId: authResponse.user!.id, // Use the actual user ID
          firstName: firstName,
          lastName: lastName,
          email: email,
          age: age,
          contactInfo: contactInfo,
          registrationDate: DateTime.now(), // Placeholder
        );
        // Create profile using the service method that handles insertion
        _patientProfile = await _supabaseService.createPatientProfile(
          newPatientData,
        );

        if (_patientProfile != null) {
          _authState = AuthStateEnum.authenticated;
          _user = authResponse.user; // Ensure user is set
          notifyListeners();
          return true;
        } else {
          // Handle case where profile creation failed after signup
          // Maybe sign out the user or show an error
          await signOut(); // Sign out if profile creation failed
          return false;
        }
      }
      return false; // Signup failed
    } catch (e) {
      print("Sign up error: $e");
      // Consider specific error handling (e.g., user already exists)
      return false;
    }
  }

  Future<bool> signIn(String email, String password) async {
    try {
      final authResponse = await _supabaseService.signIn(email, password);
      // Listener will handle state change and profile fetching
      return authResponse.user != null;
    } catch (e) {
      print("Sign in error: $e");
      return false;
    }
  }

  Future<void> signOut() async {
    await _supabaseService.signOut();
    // Listener will handle state change and clearing profile
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
}
