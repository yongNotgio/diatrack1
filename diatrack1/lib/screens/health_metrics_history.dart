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
                      style: const TextStyle(
                        fontSize: 16,
                        fontFamily: 'Poppins',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refreshData,
                      child: const Text(
                        'Retry',
                        style: TextStyle(fontFamily: 'Poppins'),
                      ),
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
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refreshData,
                      child: const Text(
                        'Refresh',
                        style: TextStyle(fontFamily: 'Poppins'),
                      ),
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
            child: _buildOverviewTab(
              metrics,
              avgGlucose,
              avgSystolic,
              avgDiastolic,
              riskClassification,
            ),
          ),
        ],
      ),
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
                      fontFamily: 'Poppins',
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
          const Center(
            child: Text(
              'Health Metrics\nHistory',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0D629E),
                fontFamily: 'Poppins',
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Overview Section
          const Text(
            'Overview',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 25,
              color: Color(0xFF0D629E),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 4),
          OverviewCards(
            avgGlucose: avgGlucose,
            avgSystolic: avgSystolic,
            avgDiastolic: avgDiastolic,
            riskClassification: riskClassification,
          ),
          const SizedBox(height: 22),

          // Visualizations Section
          const Text(
            'Visualizations',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: Color(0xFF0D629E),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 12),
          BloodSugarChart(metrics: metrics),
          const SizedBox(height: 12),
          BloodPressureChart(metrics: metrics),
          const SizedBox(height: 24),

          // Wound Photos Section
          const Text(
            'Wound Photos',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: Color(0xFF0D629E),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 12),
          WoundPhotosSection(metrics: metrics),
          const SizedBox(height: 24),

          // Health Metrics Submissions Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Health Metrics Submissions',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: Color(0xFF0D629E),
                  fontFamily: 'Poppins',
                ),
              ),
              TextButton(
                onPressed: () {
                  _showTablesBottomSheet(context, metrics);
                },
                child: const Text(
                  'View Tables',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF0D629E),
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...metrics
              .map((metric) => _buildMetricSubmissionCard(metric))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildMetricSubmissionCard(HealthMetric metric) {
    // Get risk color based on classification
    Color getRiskColor(String risk) {
      switch (risk.toUpperCase()) {
        case 'LOW':
          return const Color(0xFF19AC4A); // Green
        case 'HIGH':
          return const Color(0xFFAC191F); // Red
        case 'MEDIUM':
          return const Color(0xFFF59E0B); // Orange/Yellow
        default:
          return const Color(0xFF6B7280); // Gray
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF2FBFF),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with date and actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormatter.formatDateTime(metric.submissionDate),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0D629E),
                    fontFamily: 'Poppins',
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Image.asset(
                        'assets/images/edit.png',
                        width: 18,
                        height: 18,
                      ),
                      onPressed: () {
                        // TODO: Implement edit functionality
                      },
                    ),
                    IconButton(
                      icon: Image.asset(
                        'assets/images/delete.png',
                        width: 18,
                        height: 18,
                      ),
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder:
                              (context) => AlertDialog(
                                title: const Text(
                                  'Delete Metric',
                                  style: TextStyle(fontFamily: 'Poppins'),
                                ),
                                content: const Text(
                                  'Are you sure you want to delete this health metric?',
                                  style: TextStyle(fontFamily: 'Poppins'),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed:
                                        () => Navigator.of(context).pop(false),
                                    child: const Text(
                                      'Cancel',
                                      style: TextStyle(fontFamily: 'Poppins'),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed:
                                        () => Navigator.of(context).pop(true),
                                    child: const Text(
                                      'Delete',
                                      style: TextStyle(fontFamily: 'Poppins'),
                                    ),
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
                                  content: Text(
                                    'Metric deleted successfully',
                                    style: TextStyle(fontFamily: 'Poppins'),
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Failed to delete metric: $e',
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
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
            const SizedBox(height: 16),

            // Two-column layout for Blood Glucose and Blood Pressure
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column - Blood Glucose and Classification
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Blood Glucose',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF0D629E),
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${metric.bloodGlucose?.toStringAsFixed(0) ?? '-'}',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0D629E),
                          fontFamily: 'Poppins',
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Classification section
                      const Text(
                        'Classification',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF0D629E),
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        (metric.riskClassification ?? 'UNKNOWN').toUpperCase(),
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w500,
                          color: getRiskColor(
                            metric.riskClassification ?? 'UNKNOWN',
                          ),
                          fontFamily: 'Poppins',
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),

                // Right Column - Blood Pressure
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Blood Pressure',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF0D629E),
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Systolic
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${metric.bpSystolic ?? '-'}',
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0D629E),
                              fontFamily: 'Poppins',
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'SYS',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF0D629E),
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                Text(
                                  'mmHg',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.grey[600],
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Diastolic
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${metric.bpDiastolic ?? '-'}',
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0D629E),
                              fontFamily: 'Poppins',
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'DIA',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF0D629E),
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                Text(
                                  'mmHg',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.grey[600],
                                    fontFamily: 'Poppins',
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
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showTablesBottomSheet(
    BuildContext context,
    List<HealthMetric> metrics,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.9,
            maxChildSize: 0.95,
            minChildSize: 0.5,
            builder:
                (context, scrollController) => Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Health Metrics Tables',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0D629E),
                                fontFamily: 'Poppins',
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          controller: scrollController,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
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
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  double _calculateAverage(List<double?> values) {
    if (values.isEmpty) return 0;
    final validValues = values.where((v) => v != null).map((v) => v!).toList();
    if (validValues.isEmpty) return 0;
    return validValues.reduce((a, b) => a + b) / validValues.length;
  }

  String _getMostCommonRiskClassification(List<HealthMetric> metrics) {
    final classifications =
        metrics
            .map((m) => m.riskClassification)
            .where((classification) => classification != null)
            .cast<String>()
            .toList();
    final counts = <String, int>{};

    for (final classification in classifications) {
      counts[classification] = (counts[classification] ?? 0) + 1;
    }

    if (counts.isEmpty) return 'UNKNOWN';

    return counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }
}
