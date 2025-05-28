import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart';
import 'screens/success_screen.dart';
import 'screens/home_screen.dart';

const String supabaseUrl = 'https://wvpjwsectrwohraolniu.supabase.co';
const String supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind2cGp3c2VjdHJ3b2hyYW9sbml1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDM2MDgzNjQsImV4cCI6MjA1OTE4NDM2NH0.4DAp0jYwzqdPkjeGbvCl-KkhvQh_wBKKU_RvjQY0urU';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  runApp(const MyApp());
}

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
      initialRoute: '/',
      routes: {'/': (context) => const LoginScreen()},
      onGenerateRoute: (settings) {
        if (settings.name == '/success') {
          final patientData = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => SuccessScreen(patientData: patientData),
          );
        } else if (settings.name == '/dashboard') {
          final patientData = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => HomeScreen(patientData: patientData),
          );
        }
        return null;
      },
    );
  }
}
