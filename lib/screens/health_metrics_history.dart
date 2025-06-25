import 'package:flutter/material.dart';

class HealthMetricsHistory extends StatelessWidget {
  const HealthMetricsHistory({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Health Metrics History')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overview Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _overviewCard('Blood Sugar', '156', 'mg/dL', Colors.red),
                  _overviewCard('BP Systolic', '145.8', 'mmHg', Colors.teal),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _overviewCard('BP Diastolic', '90.3', 'mmHg', Colors.green),
                  _overviewCard(
                    'Classification',
                    'LOW',
                    'Surgical Risk',
                    Colors.purple,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Visualizations Section (Placeholder)
              const Text(
                'Visualizations',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 12),
              _visualizationPlaceholder('Blood Sugar'),
              const SizedBox(height: 12),
              _visualizationPlaceholder('Blood Pressure'),
              const SizedBox(height: 24),
              // Wound Photos Section (Placeholder)
              const Text(
                'Wound Photos',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _woundPhotoPlaceholder('June 7, 2025'),
                  const SizedBox(width: 12),
                  _woundPhotoPlaceholder('June 10, 2025'),
                ],
              ),
              const SizedBox(height: 24),
              // Health Metrics Submissions Section (Placeholder)
              const Text(
                'Health Metrics Submissions',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 12),
              _metricsSubmissionCard(
                'June 7, 2025 | 8:31 AM',
                '165',
                '120',
                '80',
                'Low',
              ),
              _metricsSubmissionCard(
                'June 6, 2025 | 8:31 AM',
                '165',
                '146',
                '110',
                'Low',
              ),
              _metricsSubmissionCard(
                'June 5, 2025 | 8:31 AM',
                '165',
                '129',
                '95',
                'Low',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _overviewCard(String title, String value, String unit, Color color) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 12, color: color)),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(unit, style: TextStyle(fontSize: 12, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _visualizationPlaceholder(String title) {
    return Container(
      height: 80,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.blueGrey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          '$title Chart Placeholder',
          style: TextStyle(color: Colors.blueGrey),
        ),
      ),
    );
  }

  Widget _woundPhotoPlaceholder(String date) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.image, size: 32, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(date, style: const TextStyle(fontSize: 10)),
      ],
    );
  }

  Widget _metricsSubmissionCard(
    String date,
    String sugar,
    String sys,
    String dia,
    String classification,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(date, style: const TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: [
                Text(
                  'Blood Glucose: $sugar',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 16),
                Text(
                  'Blood Pressure: $sys/$dia',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            Text(
              'Classification: $classification',
              style: const TextStyle(fontSize: 12, color: Colors.blue),
            ),
          ],
        ),
      ),
    );
  }
}
