import 'package:flutter/material.dart';
import '../models/health_metric.dart';
import '../services/supabase_service.dart';
import '../utils/date_formatter.dart';
import '../widgets/overview_cards.dart';
import '../widgets/blood_sugar_chart.dart';
import '../widgets/blood_pressure_chart.dart';
import '../widgets/wound_photos_section.dart';
import '../widgets/metrics_table.dart';

class HealthMetricsHistory extends StatefulWidget {
  final String patientId;

  const HealthMetricsHistory({Key? key, required this.patientId})
    : super(key: key);

  @override
  State<HealthMetricsHistory> createState() => _HealthMetricsHistoryState();
}

class _HealthMetricsHistoryState extends State<HealthMetricsHistory> {
  final SupabaseService _supabaseService = SupabaseService();
  late Future<List<HealthMetric>> _metricsFuture;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _metricsFuture = _loadMetrics();
  }

  Future<List<HealthMetric>> _loadMetrics() async {
    try {
      final rawMetrics = await _supabaseService.getHealthMetrics(
        widget.patientId,
      );
      return rawMetrics.map((m) => HealthMetric.fromMap(m)).toList();
    } catch (e) {
      throw Exception('Failed to load health metrics: $e');
    }
  }

  void _refreshData() {
    setState(() {
      _metricsFuture = _loadMetrics();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<HealthMetric>>(
        future: _metricsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFF069ADE)),
              ),
            );
          }

          if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refreshData,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.health_and_safety_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No health metrics found.',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refreshData,
                      child: const Text('Refresh'),
                    ),
                  ],
                ),
              ),
            );
          }

          final metrics = snapshot.data!;
          return _buildMainContent(metrics);
        },
      ),
    );
  }

  Widget _buildMainContent(List<HealthMetric> metrics) {
    // Calculate averages
    final avgGlucose = _calculateAverage(
      metrics.map((m) => m.bloodGlucose).where((v) => v != null).toList(),
    );
    final avgSystolic = _calculateAverage(
      metrics
          .map((m) => m.bpSystolic?.toDouble())
          .where((v) => v != null)
          .toList(),
    );
    final avgDiastolic = _calculateAverage(
      metrics
          .map((m) => m.bpDiastolic?.toDouble())
          .where((v) => v != null)
          .toList(),
    );
    final riskClassification = _getMostCommonRiskClassification(metrics);

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child:
                _currentTabIndex == 0
                    ? _buildOverviewTab(
                      metrics,
                      avgGlucose,
                      avgSystolic,
                      avgDiastolic,
                      riskClassification,
                    )
                    : _buildTableTab(metrics),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 40, left: 16, right: 16, bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
              Image.asset(
                'assets/images/diatrack_logo.png',
                height: 36,
                errorBuilder: (context, error, stackTrace) {
                  return const Text(
                    'DiaTrack',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF069ADE),
                    ),
                  );
                },
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              // TODO: Implement notifications
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(
    List<HealthMetric> metrics,
    double avgGlucose,
    double avgSystolic,
    double avgDiastolic,
    String riskClassification,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Health Metrics History',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Color(0xFF069ADE),
            ),
          ),
          const SizedBox(height: 24),

          // Overview Section
          const Text(
            'Overview',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 16),
          OverviewCards(
            avgGlucose: avgGlucose,
            avgSystolic: avgSystolic,
            avgDiastolic: avgDiastolic,
            riskClassification: riskClassification,
          ),
          const SizedBox(height: 24),

          // Visualizations Section
          const Text(
            'Visualizations',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 12),
          BloodSugarChart(metrics: metrics),
          const SizedBox(height: 12),
          BloodPressureChart(metrics: metrics),
          const SizedBox(height: 24),

          // Wound Photos Section
          const Text(
            'Wound Photos',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 12),
          WoundPhotosSection(metrics: metrics),
          const SizedBox(height: 24),

          // Health Metrics Submissions Section
          const Text(
            'Health Metrics Submissions',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 12),
          ...metrics
              .map((metric) => _buildMetricSubmissionCard(metric))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildTableTab(List<HealthMetric> metrics) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Health Metrics History',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Color(0xFF069ADE),
            ),
          ),
          const SizedBox(height: 24),

          // Search Bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Search',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF069ADE)),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Implement filter functionality
                  },
                  icon: const Icon(Icons.filter_list, size: 16),
                  label: const Text('Filter'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Implement export functionality
                  },
                  icon: const Icon(Icons.upload, size: 16),
                  label: const Text('Export'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Tables
          MetricsTable(
            metrics: metrics,
            title: 'Blood Glucose Table',
            metricType: 'glucose',
          ),
          const SizedBox(height: 24),
          MetricsTable(
            metrics: metrics,
            title: 'Blood Pressure Table',
            metricType: 'pressure',
          ),
          const SizedBox(height: 24),
          MetricsTable(
            metrics: metrics,
            title: 'Risk Class Table',
            metricType: 'risk',
          ),
        ],
      ),
    );
  }

  Widget _buildMetricSubmissionCard(HealthMetric metric) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormatter.formatDateTime(metric.submissionDate),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 16),
                      onPressed: () {
                        // TODO: Implement edit functionality
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 16),
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder:
                              (context) => AlertDialog(
                                title: const Text('Delete Metric'),
                                content: const Text(
                                  'Are you sure you want to delete this health metric?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed:
                                        () => Navigator.of(context).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed:
                                        () => Navigator.of(context).pop(true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                        );

                        if (confirmed == true) {
                          try {
                            await _supabaseService.deleteHealthMetric(
                              metric.id,
                            );
                            _refreshData();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Metric deleted successfully'),
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to delete metric: $e'),
                                ),
                              );
                            }
                          }
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Blood Glucose: ${metric.bloodGlucose?.toStringAsFixed(0) ?? '-'} mg/dL',
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        'Classification: ${metric.glucoseClassification}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Blood Pressure: ${metric.bpSystolic ?? '-'} / ${metric.bpDiastolic ?? '-'} mmHg',
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        'Risk: ${metric.riskClassification}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return BottomNavigationBar(
      currentIndex: _currentTabIndex,
      onTap: (index) {
        setState(() {
          _currentTabIndex = index;
        });
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF069ADE),
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Overview'),
        BottomNavigationBarItem(icon: Icon(Icons.table_chart), label: 'Tables'),
      ],
    );
  }

  double _calculateAverage(List<double?> values) {
    if (values.isEmpty) return 0;
    final validValues = values.where((v) => v != null).map((v) => v!).toList();
    if (validValues.isEmpty) return 0;
    return validValues.reduce((a, b) => a + b) / validValues.length;
  }

  String _getMostCommonRiskClassification(List<HealthMetric> metrics) {
    final classifications = metrics.map((m) => m.riskClassification).toList();
    final counts = <String, int>{};

    for (final classification in classifications) {
      counts[classification] = (counts[classification] ?? 0) + 1;
    }

    if (counts.isEmpty) return 'UNKNOWN';

    return counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }
}
