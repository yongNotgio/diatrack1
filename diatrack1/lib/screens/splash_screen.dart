// --- lib/screens/splash_screen.dart ---
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'auth_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use a Consumer or Watch to react to auth state changes
    final authState = context.watch<AuthProvider>().authState;

    // Determine the next screen based on the authentication state
    // Add a small delay or check for profile loading if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (authState == AuthStateEnum.authenticated) {
        // Optional: Check if profile is loaded before navigating
        final isLoadingProfile = context.read<AuthProvider>().isLoadingProfile;
        if (!isLoadingProfile) {
          Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
        }
        // If loading profile, stay on splash or show loading indicator
      } else if (authState == AuthStateEnum.unauthenticated) {
        Navigator.of(context).pushReplacementNamed(AuthScreen.routeName);
      }
    });

    // Show a loading indicator while determining the state
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text("Loading..."),
          ],
        ),
      ),
    );
  }
}
