// lib/main.dart (Corrected Provider Setup)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'services/supabase_service.dart';
import 'services/notification_service.dart';
import 'providers/auth_provider.dart';
import 'providers/metrics_provider.dart';
import 'providers/reminders_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/add_metric_screen.dart';
import 'screens/metrics_history_screen.dart';
import 'screens/add_reminder_screen.dart';
import 'screens/reminders_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(url: SUPABASE_URL, anonKey: SUPABASE_ANON_KEY);

  await NotificationService().initialize();

  final supabaseService = await SupabaseService.getInstance();
  final notificationService = NotificationService();

  runApp(
    MyApp(
      supabaseService: supabaseService,
      notificationService: notificationService,
    ),
  );
}

class MyApp extends StatelessWidget {
  final SupabaseService supabaseService;
  final NotificationService notificationService;

  const MyApp({
    Key? key,
    required this.supabaseService,
    required this.notificationService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(supabaseService),
        ),
        // Corrected ChangeNotifierProxyProvider setup:
        // 'create' only needs context. Dependencies are passed in 'update'.
        // We provide an initial instance in 'create' that will be immediately
        // updated by 'update' once AuthProvider is available.
        ChangeNotifierProxyProvider<AuthProvider, MetricsProvider>(
          // Create an initial instance. It will be updated immediately.
          create:
              (context) => MetricsProvider(
                supabaseService,
                Provider.of<AuthProvider>(
                  context,
                  listen: false,
                ), // Get initial auth state
              ),
          // Update gets the AuthProvider instance and the previous MetricsProvider state
          update:
              (context, auth, previousMetrics) =>
                  MetricsProvider(supabaseService, auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, RemindersProvider>(
          // Create an initial instance.
          create:
              (context) => RemindersProvider(
                supabaseService,
                notificationService,
                Provider.of<AuthProvider>(
                  context,
                  listen: false,
                ), // Get initial auth state
              ),
          // Update gets AuthProvider and previous RemindersProvider state
          update:
              (context, auth, previousReminders) =>
                  RemindersProvider(supabaseService, notificationService, auth),
        ),
      ],
      child: MaterialApp(
        title: 'Patient Health Tracker',
        theme: ThemeData(
          primarySwatch: Colors.teal,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: Colors.teal.shade300, width: 2.0),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ),
        home: const SplashScreen(),
        routes: {
          AuthScreen.routeName: (ctx) => const AuthScreen(),
          HomeScreen.routeName: (ctx) => const HomeScreen(),
          // Ensure these screens exist and define routeName
          AddMetricScreen.routeName: (ctx) => const AddMetricScreen(),
          MetricsHistoryScreen.routeName: (ctx) => const MetricsHistoryScreen(),
          AddReminderScreen.routeName: (ctx) => const AddReminderScreen(),
          RemindersScreen.routeName: (ctx) => const RemindersScreen(),
        },
      ),
    );
  }
}
