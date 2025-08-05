import 'package:flutter/material.dart';

class OverviewCards extends StatelessWidget {
  final double avgGlucose;
  final double avgSystolic;
  final double avgDiastolic;
  final String riskClassification;

  const OverviewCards({
    Key? key,
    required this.avgGlucose,
    required this.avgSystolic,
    required this.avgDiastolic,
    required this.riskClassification,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.25,
      children: [
        _OverviewCard(
          title: 'Blood Glucose',
          value: avgGlucose.toStringAsFixed(1),
          unit: 'mg/dL',
          color: const Color(0xFFE53E3E), // Strong red
          backgroundColor: const Color(0xFFFFF5F5), // Light red background
          label: 'AVG',
        ),
        _OverviewCard(
          title: 'BP Systolic',
          value: avgSystolic.toStringAsFixed(1),
          unit: 'mmHg',
          color: const Color(0xFF38A169), // Strong green
          backgroundColor: const Color(0xFFF0FFF4), // Light green background
          label: 'AVG',
        ),
        _OverviewCard(
          title: 'BP Diastolic',
          value: avgDiastolic.toStringAsFixed(1),
          unit: 'mmHg',
          color: const Color(0xFF3182CE), // Strong blue
          backgroundColor: const Color(0xFFF7FAFC), // Light blue background
          label: 'AVG',
        ),
        _OverviewCard(
          title: 'Risk Classification',
          value: riskClassification,
          unit: 'Surgical Risk',
          color: const Color(0xFF805AD5), // Strong purple
          backgroundColor: const Color(0xFFFAF5FF), // Light purple background
          label: 'MODE',
        ),
      ],
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final Color color;
  final Color? backgroundColor;
  final String? label;

  const _OverviewCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.color,
    this.backgroundColor,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: backgroundColor ?? Colors.white,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (label != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    label!,
                    style: TextStyle(
                      fontSize: 10,
                      color: color,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: color.withOpacity(0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 11,
                  color: color.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
