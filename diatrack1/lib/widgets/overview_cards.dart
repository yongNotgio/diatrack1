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
          color: const Color(0xFFE57373), // Reddish
          label: 'AVG',
        ),
        _OverviewCard(
          title: 'BP Systolic',
          value: avgSystolic.toStringAsFixed(1),
          unit: 'mmHg',
          color: const Color(0xFF81C784), // Light Blue
          label: 'AVG',
        ),
        _OverviewCard(
          title: 'BP Diastolic',
          value: avgDiastolic.toStringAsFixed(1),
          unit: 'mmHg',
          color: const Color(0xFFA5D6A7), // Light Green
          label: 'AVG',
        ),
        _OverviewCard(
          title: 'Risk Classification',
          value: riskClassification,
          unit: 'Surgical Risk',
          color: const Color(0xFFCE93D8), // Light Purple
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
  final String? label;

  const _OverviewCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.color,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (label != null)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  label!,
                  style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              unit,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
