import 'package:flutter/material.dart';

class RiskAssessmentScreen extends StatelessWidget {
  final Map<String, dynamic> riskData;

  const RiskAssessmentScreen({Key? key, required this.riskData})
    : super(key: key);

  Color _getRiskColor() {
    final colorString = riskData['risk_category']?['color'] as String?;
    switch (colorString?.toLowerCase()) {
      case 'green':
        return const Color(0xFF19AC4A);
      case 'orange':
        return const Color(0xFFF39C12);
      case 'red':
        return const Color(0xFFE74C3C);
      default:
        return const Color(0xFF95A5A6);
    }
  }

  String _getRiskLevel() {
    final level = riskData['risk_category']?['level'] as String?;
    return level ?? 'Unknown Risk';
  }

  double _getRiskScore() {
    final score = riskData['risk_score'];
    if (score is num) {
      return score.toDouble();
    }
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final riskColor = _getRiskColor();
    final riskLevel = _getRiskLevel();
    final riskScore = _getRiskScore();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: SafeArea(
        child: Column(
          children: [
            // Header with close button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Color(0xFF2C3E50),
                      size: 28,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Main content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // AI Risk Classification Header
                    const Text(
                      'AI Risk',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C3E50),
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const Text(
                      'Classification',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C3E50),
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const Text(
                      'Done',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C3E50),
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Subtitle
                    const Text(
                      'Our AI model evaluated your',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF7F8C8D),
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const Text(
                      'health metrics submission. Your',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF7F8C8D),
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const Text(
                      'risk for surgery is:',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF7F8C8D),
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Risk gauge/indicator
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [riskColor.withOpacity(0.3), riskColor],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: riskColor.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 110,
                          height: 110,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: Center(
                            child: Icon(
                              Icons.speed,
                              size: 50,
                              color: riskColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Risk Level Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: riskColor,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: riskColor.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        riskLevel.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontFamily: 'Poppins',
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Risk Score
                    Text(
                      'Risk Score: ${riskScore.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: riskColor,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Confirm Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1DA1F2),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          'Confirm',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
