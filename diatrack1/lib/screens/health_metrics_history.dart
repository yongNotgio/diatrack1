import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../services/supabase_service.dart';

class HealthMetricsHistory extends StatefulWidget {
  final String patientId;
  const HealthMetricsHistory({Key? key, required this.patientId})
    : super(key: key);

  @override
  State<HealthMetricsHistory> createState() => _HealthMetricsHistoryState();
}

class _HealthMetricsHistoryState extends State<HealthMetricsHistory> {
  final SupabaseService _supabaseService = SupabaseService();
  late Future<List<Map<String, dynamic>>> _metricsFuture;

  @override
  void initState() {
    super.initState();
    _metricsFuture = _supabaseService.getHealthMetrics(widget.patientId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Health Metrics History')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _metricsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No health metrics found.'));
          }
          final metrics = snapshot.data!;
          // Sort by submission_date descending
          metrics.sort(
            (a, b) => b['submission_date'].compareTo(a['submission_date']),
          );
          final latest = metrics.first;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overview Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _overviewCard(
                        'Blood Sugar',
                        latest['blood_glucose']?.toString() ?? '-',
                        'mg/dL',
                        Colors.red,
                      ),
                      _overviewCard(
                        'BP Systolic',
                        latest['bp_systolic']?.toString() ?? '-',
                        'mmHg',
                        Colors.teal,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _overviewCard(
                        'BP Diastolic',
                        latest['bp_diastolic']?.toString() ?? '-',
                        'mmHg',
                        Colors.green,
                      ),
                      _overviewCard(
                        'Classification',
                        _getClassification(latest),
                        'Surgical Risk',
                        Colors.purple,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Visualizations Section
                  const Text(
                    'Visualizations',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  _bloodSugarChart(metrics),
                  const SizedBox(height: 12),
                  _bloodPressureChart(metrics),
                  const SizedBox(height: 24),
                  // Wound Photos Section
                  const Text(
                    'Wound Photos',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  _woundPhotos(metrics),
                  const SizedBox(height: 24),
                  // Health Metrics Submissions Section
                  const Text(
                    'Health Metrics Submissions',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  ...metrics.map((m) => _metricsSubmissionCard(m)).toList(),
                ],
              ),
            ),
          );
        },
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

  String _getClassification(Map<String, dynamic> metric) {
    // Example: classify based on blood pressure or glucose
    final sys = metric['bp_systolic'] ?? 0;
    final dia = metric['bp_diastolic'] ?? 0;
    if (sys < 130 && dia < 85) return 'LOW';
    if (sys < 140 && dia < 90) return 'MEDIUM';
    return 'HIGH';
  }

  Widget _bloodSugarChart(List<Map<String, dynamic>> metrics) {
    final spots = <FlSpot>[];
    for (int i = 0; i < metrics.length; i++) {
      final val = metrics[i]['blood_glucose'];
      if (val != null) {
        spots.add(FlSpot(i.toDouble(), val.toDouble()));
      }
    }
    return SizedBox(
      height: 120,
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.blue,
              barWidth: 3,
              dotData: FlDotData(show: false),
            ),
          ],
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  Widget _bloodPressureChart(List<Map<String, dynamic>> metrics) {
    final sysSpots = <FlSpot>[];
    final diaSpots = <FlSpot>[];
    for (int i = 0; i < metrics.length; i++) {
      final sys = metrics[i]['bp_systolic'];
      final dia = metrics[i]['bp_diastolic'];
      if (sys != null) sysSpots.add(FlSpot(i.toDouble(), sys.toDouble()));
      if (dia != null) diaSpots.add(FlSpot(i.toDouble(), dia.toDouble()));
    }
    return SizedBox(
      height: 120,
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: sysSpots,
              isCurved: true,
              color: Colors.red,
              barWidth: 3,
              dotData: FlDotData(show: false),
            ),
            LineChartBarData(
              spots: diaSpots,
              isCurved: true,
              color: Colors.green,
              barWidth: 3,
              dotData: FlDotData(show: false),
            ),
          ],
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  Widget _woundPhotos(List<Map<String, dynamic>> metrics) {
    final photos =
        metrics
            .where(
              (m) =>
                  m['wound_photo_url'] != null &&
                  m['wound_photo_url'].toString().isNotEmpty,
            )
            .toList();
    if (photos.isEmpty) {
      return const Text('No wound photos available.');
    }
    return Row(
      children:
          photos.take(2).map((m) {
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      m['wound_photo_url'],
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(m['submission_date']),
                    style: const TextStyle(fontSize: 10),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  Widget _metricsSubmissionCard(Map<String, dynamic> m) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _formatDateTime(m['submission_date']),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Text(
                  'Blood Glucose: ${m['blood_glucose'] ?? '-'}',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 16),
                Text(
                  'Blood Pressure: ${m['bp_systolic'] ?? '-'} / ${m['bp_diastolic'] ?? '-'}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            Text(
              'Classification: ${_getClassification(m)}',
              style: const TextStyle(fontSize: 12, color: Colors.blue),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? date) {
    if (date == null) return '-';
    final dt = DateTime.tryParse(date);
    if (dt == null) return '-';
    return '${dt.month}/${dt.day}/${dt.year}';
  }

  String _formatDateTime(String? date) {
    if (date == null) return '-';
    final dt = DateTime.tryParse(date);
    if (dt == null) return '-';
    return '${dt.month}/${dt.day}/${dt.year} | ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
