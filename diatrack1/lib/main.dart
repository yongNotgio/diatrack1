import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart'; // Assuming login screen is the entry point

// --- IMPORTANT: Replace with your Supabase details ---
const String supabaseUrl = 'https://wvpjwsectrwohraolniu.supabase.co';
const String supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind2cGp3c2VjdHJ3b2hyYW9sbml1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDM2MDgzNjQsImV4cCI6MjA1OTE4NDM2NH0.4DAp0jYwzqdPkjeGbvCl-KkhvQh_wBKKU_RvjQY0urU';
// ----------------------------------------------------

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Required for Supabase init

  // Initialize Supabase
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    // You can configure other options like auth persistence, realtime, etc.
    // storageRetryAttempts: 2, // Example: configure storage options
  );

  runApp(const MyApp());
}

// Get a reference to the Supabase client throughout the app
final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Patient Health Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true, // Optional: Use Material 3 design
        inputDecorationTheme: InputDecorationTheme(
          // Consistent styling
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
          filled: true,
          fillColor: Colors.grey[100],
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          // Consistent button style
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            padding: const EdgeInsets.symmetric(
              vertical: 12.0,
              horizontal: 20.0,
            ),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false, // Hide debug banner
      home: const LoginScreen(), // Start with the Login Screen
    );
  }
}
