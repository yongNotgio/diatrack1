import 'package:flutter/material.dart';
import '../models/health_metric.dart';
import '../utils/date_formatter.dart';

class WoundDetailScreen extends StatelessWidget {
  final HealthMetric metric;

  const WoundDetailScreen({Key? key, required this.metric}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool hasAnnotations =
        metric.woundDiagnosis != null ||
        (metric.woundCare != null && metric.woundCare!.isNotEmpty) ||
        (metric.woundDressing != null && metric.woundDressing!.isNotEmpty) ||
        (metric.woundMedication != null &&
            metric.woundMedication!.isNotEmpty) ||
        (metric.woundFollowUp != null && metric.woundFollowUp!.isNotEmpty) ||
        metric.woundImportantNotes != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1DA1F2)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Wound Details',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: Color(0xFF0D629E),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Wound Image
            Container(
              width: double.infinity,
              height: 400,
              color: Colors.black,
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: Image.network(
                    metric.woundPhotoUrl!,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_not_supported,
                                color: Colors.grey,
                                size: 64,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Image not available',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // Submission Info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Submitted on ${DateFormatter.formatDate(metric.submissionDate)}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0D629E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${DateFormatter.getDayName(metric.submissionDate)} | ${DateFormatter.formatDateTime(metric.submissionDate).split(' | ')[1]}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Doctor Annotations Section
            if (hasAnnotations) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0D629E), Color(0xFF1DA1F2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.medical_services,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Doctor Annotations',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Diagnosis
              if (metric.woundDiagnosis != null)
                _buildAnnotationCard(
                  icon: Icons.assignment,
                  title: 'Diagnosis',
                  content: metric.woundDiagnosis!,
                ),

              // Wound Care
              if (metric.woundCare != null && metric.woundCare!.isNotEmpty)
                _buildListAnnotationCard(
                  icon: Icons.healing,
                  title: 'Wound Care Instructions',
                  items: metric.woundCare!,
                  isNumbered: true,
                ),

              // Wound Dressing
              if (metric.woundDressing != null &&
                  metric.woundDressing!.isNotEmpty)
                _buildListAnnotationCard(
                  icon: Icons.local_hospital,
                  title: 'Dressing Instructions',
                  items: metric.woundDressing!,
                  isNumbered: true,
                ),

              // Wound Medication
              if (metric.woundMedication != null &&
                  metric.woundMedication!.isNotEmpty)
                _buildListAnnotationCard(
                  icon: Icons.medication,
                  title: 'Medications',
                  items: metric.woundMedication!,
                  isNumbered: false,
                ),

              // Follow-up
              if (metric.woundFollowUp != null &&
                  metric.woundFollowUp!.isNotEmpty)
                _buildListAnnotationCard(
                  icon: Icons.calendar_today,
                  title: 'Follow-up Instructions',
                  items: metric.woundFollowUp!,
                  isNumbered: true,
                ),

              // Important Notes
              if (metric.woundImportantNotes != null)
                _buildAnnotationCard(
                  icon: Icons.warning_amber_rounded,
                  title: 'Important Notes',
                  content: metric.woundImportantNotes!,
                  isWarning: true,
                ),
            ] else ...[
              // No annotations message
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No Doctor Annotations Yet',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your doctor has not provided annotations for this wound photo yet.',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnotationCard({
    required IconData icon,
    required String title,
    required String content,
    bool isWarning = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isWarning ? const Color(0xFFFFA726) : const Color(0xFFDCF4FF),
            width: 2,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        isWarning
                            ? const Color(0xFFFFF3E0)
                            : const Color(0xFFDCF4FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color:
                        isWarning
                            ? const Color(0xFFFFA726)
                            : const Color(0xFF1DA1F2),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0D629E),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: Color(0xFF333333),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListAnnotationCard({
    required IconData icon,
    required String title,
    required List<String> items,
    required bool isNumbered,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFDCF4FF), width: 2),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCF4FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: const Color(0xFF1DA1F2), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0D629E),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 24,
                      child: Text(
                        isNumbered ? '${index + 1}.' : '•',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: isNumbered ? 14 : 18,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1DA1F2),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          color: Color(0xFF333333),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
