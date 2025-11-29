import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/success_screen.dart';
import 'screens/home_screen.dart';

// Supabase configuration will be loaded from .env file

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Get Supabase configuration from environment variables
  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw Exception(
      'Supabase configuration not found in environment variables',
    );
  }

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  // Check for saved user
  final prefs = await SharedPreferences.getInstance();
  final patientId = prefs.getString('patient_id');
  final firstName = prefs.getString('first_name');
  final lastName = prefs.getString('last_name');
  final phase = prefs.getString('phase');
  final doctorName = prefs.getString('doctor_name');
  // Add any other fields you saved

  runApp(
    MyApp(
      initialRoute: (patientId != null) ? '/dashboard' : '/',
      patientData:
          (patientId != null)
              ? {
                'patient_id': patientId,
                'first_name': firstName,
                'last_name': lastName,
                'phase': phase,
                'doctor_name': doctorName,
                // Add any other fields
              }
              : null,
    ),
  );
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  final String initialRoute;
  final Map<String, dynamic>? patientData;

  const MyApp({super.key, required this.initialRoute, this.patientData});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Patient Health Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
          filled: true,
          fillColor: Colors.grey[100],
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
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
      debugShowCheckedModeBanner: false,
      initialRoute: initialRoute,
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        // Only include dashboard route if patientData is not null
        if (patientData != null)
          '/dashboard': (context) => HomeScreen(patientData: patientData!),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/success') {
          final patientData = settings.arguments as Map<String, dynamic>?;
          if (patientData != null) {
            return MaterialPageRoute(
              builder: (context) => SuccessScreen(patientData: patientData),
            );
          }
        } else if (settings.name == '/dashboard') {
          final patientData = settings.arguments as Map<String, dynamic>?;
          if (patientData != null) {
            return MaterialPageRoute(
              builder: (context) => HomeScreen(patientData: patientData),
            );
          }
        }

        // Fallback to login screen if patientData is null for dashboard route
        if (settings.name == '/dashboard' && patientData == null) {
          return MaterialPageRoute(builder: (context) => const LoginScreen());
        }

        return null;
      },
    );
  }
}
