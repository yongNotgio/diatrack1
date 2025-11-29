import 'package:flutter/material.dart';

class SuccessScreen extends StatelessWidget {
  final Map<String, dynamic> patientData;

  const SuccessScreen({super.key, required this.patientData});

  @override
  Widget build(BuildContext context) {
    final primaryBlue = const Color(0xFF1DA1F2);

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.5, 1.0],
            colors: [Color(0xFFE8F7FF), Color(0xFF7DD3FC), Color(0xFF1DA1F2)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Logo - Centered
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Center(
                  child: Image.asset(
                    'assets/images/diatrack_logo.png',
                    height: 40,
                    errorBuilder: (context, error, stackTrace) {
                      return const Text(
                        'DiaTrack',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Poppins',
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // Doctor Image - Larger
              Expanded(
                flex: 10,
                child: Image.asset(
                  'assets/images/welcome.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset(
                      'assets/images/diatrack_doctor.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.person,
                            size: 150,
                            color: Colors.white,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              // Welcome Text
              const Text(
                'Welcome to\nDiaTrack!',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Poppins',
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Your account has been\ncompletely setup by your\nattending physician.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.85),
                  fontFamily: 'Poppins',
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 2),
              // Go to Dashboard Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(
                        context,
                        '/dashboard',
                        arguments: patientData,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Go to Dashboard',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}
