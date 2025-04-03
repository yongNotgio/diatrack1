// --- lib/widgets/metric_card.dart ---
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import '../models/health_metric.dart';

class MetricCard extends StatelessWidget {
  final HealthMetric metric;

  const MetricCard({Key? key, required this.metric}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat.yMd().add_jm().format(
      metric.submissionDate.toLocal(),
    );

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recorded: $formattedDate',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Wrap(
              // Use Wrap for better layout on different screen sizes
              spacing: 16.0, // Horizontal space between items
              runSpacing: 8.0, // Vertical space between lines
              children: [
                if (metric.glucoseFasting != null)
                  _buildMetricItem(
                    'Glucose (Fasting)',
                    '${metric.glucoseFasting} mg/dL',
                  ), // Add units
                if (metric.glucosePostprandial != null)
                  _buildMetricItem(
                    'Glucose (Postprandial)',
                    '${metric.glucosePostprandial} mg/dL',
                  ),
                if (metric.bloodPressureSystolic != null &&
                    metric.bloodPressureDiastolic != null)
                  _buildMetricItem(
                    'Blood Pressure',
                    '${metric.bloodPressureSystolic}/${metric.bloodPressureDiastolic} mmHg',
                  ),
                if (metric.pulseRate != null)
                  _buildMetricItem('Pulse Rate', '${metric.pulseRate} bpm'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min, // Prevent column from taking max width
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        Text(value, style: const TextStyle(fontSize: 16)),
      ],
    );
  }
}
