import 'package:flutter/material.dart';
import '../models/health_metric.dart';
import '../services/supabase_service.dart';
import '../utils/date_formatter.dart';
import '../widgets/overview_cards.dart';
import '../widgets/blood_sugar_chart.dart';
import '../widgets/blood_pressure_chart.dart';
import '../widgets/wound_photos_section.dart';
import 'notifications_screen.dart';

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
    return FutureBuilder<List<HealthMetric>>(
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
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: {snapshot.error}',
                    style: TextStyle(fontFamily: 'Poppins'),
                  ),
                ],
              ),
            ),
          );
        }
        final metrics = snapshot.data!;
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
              _buildHeader(context),
              Expanded(
                child: _buildOverviewTab(
                  context,
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
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          NotificationsScreen(patientId: widget.patientId),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(
    BuildContext context,
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
          const Text(
            'Visualizations',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 25,
              color: Color(0xFF0D629E),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 12),
          BloodSugarChart(metrics: metrics),
          const SizedBox(height: 12),
          BloodPressureChart(metrics: metrics),
          const SizedBox(height: 24),
          const Text(
            'Wound Photos',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 25,
              color: Color(0xFF0D629E),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 12),
          WoundPhotosSection(metrics: metrics),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Health Metrics\nSubmissions',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 25,
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
        case 'MODERATE':
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
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          (metric.riskClassification ?? 'UNKNOWN')
                              .toUpperCase(),
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
                      // Diastolic and BP Classification
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
                      const SizedBox(height: 8),
                      // Pulse Rate
                      if (metric.pulseRate != null)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${metric.pulseRate}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF7BA5BB),
                                fontFamily: 'Poppins',
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Text(
                                'bpm',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.grey[600],
                                  fontFamily: 'Poppins',
                                ),
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
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => _TablesScreen(metrics: metrics)),
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

  /// Classifies blood pressure based on systolic and diastolic values.
  String classifyBloodPressure(int? systolic, int? diastolic) {
    if (systolic == null || diastolic == null) return '';

    if (systolic >= 140 || diastolic >= 90) return 'HIGH';
    if (systolic >= 130 || diastolic >= 80) return 'ELEVATED';
    return 'NORMAL';
  }
}

class _TablesScreen extends StatefulWidget {
  final List<HealthMetric> metrics;

  const _TablesScreen({Key? key, required this.metrics}) : super(key: key);

  @override
  State<_TablesScreen> createState() => _TablesScreenState();
}

class _TablesScreenState extends State<_TablesScreen> {
  String _searchQuery = '';
  String _currentFilter = 'General Summary'; // Default filter

  final List<String> _filterOptions = [
    'General Summary',
    'Blood Glucose Table',
    'Blood Pressure Table',
    'Risk Class Table',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0D629E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Health Metrics History',
          style: TextStyle(
            color: Color(0xFF0D629E),
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF1DA1F2)),
            onPressed: () {
              setState(() {});
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF0D629E), width: 1.5),
              ),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search',
                  hintStyle: const TextStyle(
                    fontFamily: 'Poppins',
                    color: Color(0xFF999999),
                    fontSize: 14,
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Image.asset(
                      'assets/images/search.png',
                      width: 20,
                      height: 20,
                      color: const Color(0xFF0D629E),
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                ),
              ),
            ),
          ),

          // Filter and Export buttons
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _showFilterDialog();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0D629E),
                      side: const BorderSide(color: Color(0xFF0D629E)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/filter.png',
                          width: 18,
                          height: 18,
                          color: const Color(0xFF0D629E),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _currentFilter == 'General Summary'
                              ? 'Filter'
                              : _currentFilter,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0D629E),
                      side: const BorderSide(color: Color(0xFF0D629E)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/export.png',
                          width: 18,
                          height: 18,
                          color: const Color(0xFF0D629E),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Export',
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content Area
          Expanded(child: _buildCurrentView()),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text(
              'Filter Tables',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  _filterOptions
                      .map(
                        (option) => ListTile(
                          title: Text(
                            option,
                            style: const TextStyle(fontFamily: 'Poppins'),
                          ),
                          leading: Radio<String>(
                            value: option,
                            groupValue: _currentFilter,
                            onChanged: (value) {
                              setState(() {
                                _currentFilter = value!;
                              });
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),
    );
  }

  Widget _buildCurrentView() {
    switch (_currentFilter) {
      case 'General Summary':
        return _buildGeneralSummaryView();
      case 'Blood Glucose Table':
        return _buildSpecificTable('glucose');
      case 'Blood Pressure Table':
        return _buildSpecificTable('pressure');
      case 'Risk Class Table':
        return _buildSpecificTable('risk');
      default:
        return _buildGeneralSummaryView();
    }
  }

  Widget _buildGeneralSummaryView() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'General Summary',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
                fontSize: 16,
                color: Color(0xFF0D629E),
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF2FBFF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF0D629E), width: 1.5),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFFDCF4FF),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(10),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          'Table',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            color: Color(0xFF0D629E),
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            setState(() {});
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.refresh,
                                size: 16,
                                color: Color(0xFF0D629E),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Refresh',
                                style: TextStyle(
                                  color: Color(0xFF0D629E),
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Scrollable card entries
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: widget.metrics.length,
                      itemBuilder: (context, index) {
                        final totalMetrics = widget.metrics.length;
                        final metric =
                            widget
                                .metrics[index]; // Newest first (descending order)
                        final entryNumber =
                            totalMetrics -
                            index; // Keep original numbering: oldest=1, newest=highest
                        final entryId =
                            '#${entryNumber.toString().padLeft(4, '0')}';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2FBFF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF0D629E),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Entry ID Header
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFDCF4FF),
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(7),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Text(
                                      'Entry ID',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Poppins',
                                        fontSize: 11,
                                        color: Color(0xFF1B6CA4),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      entryId,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Poppins',
                                        fontSize: 11,
                                        color: Color(0xFF1B6CA4),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Content in 2-column layout
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  children: [
                                    // Date and Time
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Expanded(
                                          flex: 2,
                                          child: Text(
                                            'Date and Time',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Poppins',
                                              fontSize: 10,
                                              color: Color(0xFF1B6CA4),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 3,
                                          child: Text(
                                            DateFormatter.formatDateTime(
                                              metric.submissionDate,
                                            ),
                                            style: const TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 10,
                                              color: Color(0xFF1B6CA4),
                                            ),
                                            textAlign: TextAlign.right,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),

                                    // Blood Glucose
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Expanded(
                                          flex: 2,
                                          child: Text(
                                            'Blood Glucose',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Poppins',
                                              fontSize: 10,
                                              color: Color(0xFF1B6CA4),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 3,
                                          child: Text(
                                            '${metric.bloodGlucose?.toStringAsFixed(0) ?? '--'} mg/dL',
                                            style: const TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 10,
                                              color: Color(0xFF1B6CA4),
                                            ),
                                            textAlign: TextAlign.right,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),

                                    // Blood Pressure
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Expanded(
                                          flex: 2,
                                          child: Text(
                                            'Blood Pressure',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Poppins',
                                              fontSize: 10,
                                              color: Color(0xFF1B6CA4),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 3,
                                          child: Text(
                                            '${metric.bpSystolic ?? '--'}/${metric.bpDiastolic ?? '--'}',
                                            style: const TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 10,
                                              color: Color(0xFF1B6CA4),
                                            ),
                                            textAlign: TextAlign.right,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),

                                    // Pulse Rate
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Expanded(
                                          flex: 2,
                                          child: Text(
                                            'Pulse Rate',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Poppins',
                                              fontSize: 10,
                                              color: Color(0xFF1B6CA4),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 3,
                                          child: Text(
                                            '${metric.pulseRate ?? '--'} bpm',
                                            style: const TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 10,
                                              color: Color(0xFF1B6CA4),
                                            ),
                                            textAlign: TextAlign.right,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),

                                    // Risk Classification
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Expanded(
                                          flex: 2,
                                          child: Text(
                                            'Risk Classification',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Poppins',
                                              fontSize: 10,
                                              color: Color(0xFF1B6CA4),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 3,
                                          child: Text(
                                            (metric.riskClassification ??
                                                    'UNKNOWN')
                                                .toUpperCase(),
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: getRiskColor(
                                                metric.riskClassification ??
                                                    'UNKNOWN',
                                              ),
                                            ),
                                            textAlign: TextAlign.right,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecificTable(String metricType) {
    String tableLabel = '';
    switch (metricType) {
      case 'glucose':
        tableLabel = 'Blood Glucose Table';
        break;
      case 'pressure':
        tableLabel = 'Blood Pressure Table';
        break;
      case 'risk':
        tableLabel = 'Risk Class Table';
        break;
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              tableLabel,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
                fontSize: 16,
                color: Color(0xFF0D629E),
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF2FBFF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF0D629E), width: 1.5),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFFDCF4FF),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(10),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          'Table',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            color: Color(0xFF0D629E),
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            setState(() {});
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.refresh,
                                size: 16,
                                color: Color(0xFF0D629E),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Refresh',
                                style: TextStyle(
                                  color: Color(0xFF0D629E),
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Table Content - Custom implementation with sticky header
                  // Sticky Table Header
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFDCF4FF),
                      border: Border(
                        bottom: BorderSide(color: Color(0xFF0D629E), width: 1),
                      ),
                    ),
                    child: _buildTableHeaderRow(metricType),
                  ),
                  // Scrollable Table Rows
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(children: _buildTableRows(metricType)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeaderRow(String metricType) {
    switch (metricType) {
      case 'glucose':
        return IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: const Text(
                    'Entry ID',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: Color(0xFF1B6CA4),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: const Text(
                    'Date and Time',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: Color(0xFF1B6CA4),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: const Text(
                    'Blood Glucose',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: Color(0xFF1B6CA4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      case 'pressure':
        return IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                  child: const Text(
                    'Entry ID',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      color: Color(0xFF1B6CA4),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                  child: const Text(
                    'Date and Time',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      color: Color(0xFF1B6CA4),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 12,
                  ),
                  child: const Text(
                    'BP',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      color: Color(0xFF1B6CA4),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 12,
                  ),
                  child: const Text(
                    'Pulse',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      color: Color(0xFF1B6CA4),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 12,
                  ),
                  child: const Text(
                    'Class',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      color: Color(0xFF1B6CA4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      case 'risk':
        return IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: const Text(
                    'Entry ID',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: Color(0xFF1B6CA4),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: const Text(
                    'Date and Time',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: Color(0xFF1B6CA4),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: const Text(
                    'Risk Class',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: Color(0xFF1B6CA4),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: const Text(
                    'Risk Score',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: Color(0xFF1B6CA4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  List<Widget> _buildTableRows(String metricType) {
    final totalMetrics = widget.metrics.length;
    return List<Widget>.generate(totalMetrics, (index) {
      final metric = widget.metrics[index]; // Newest first (descending order)
      final entryNumber =
          totalMetrics -
          index; // Keep original numbering: oldest=1, newest=highest
      final isLastRow = index == totalMetrics - 1;

      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF2FBFF),
          border: Border(
            bottom: BorderSide(
              color: isLastRow ? Colors.transparent : const Color(0xFF0D629E),
              width: 1,
            ),
          ),
        ),
        child: _buildTableDataRow(metric, entryNumber, metricType),
      );
    });
  }

  Widget _buildTableDataRow(
    HealthMetric metric,
    int entryNumber,
    String metricType,
  ) {
    final entryId = '#${entryNumber.toString().padLeft(4, '0')}';

    switch (metricType) {
      case 'glucose':
        return IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: Text(
                    entryId,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: Color(0xFF1B6CA4),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormatter.formatDateOnly(metric.submissionDate),
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: Color(0xFF1B6CA4),
                        ),
                      ),
                      Text(
                        DateFormatter.formatTimeOnly(metric.submissionDate),
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          color: Color(0xFF1B6CA4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: Text(
                    '${metric.bloodGlucose?.toStringAsFixed(0) ?? '--'} mg/dL',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: Color(0xFF1B6CA4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      case 'pressure':
        return IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                  child: Text(
                    entryId,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      color: Color(0xFF1B6CA4),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormatter.formatDateOnly(metric.submissionDate),
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          color: Color(0xFF1B6CA4),
                        ),
                      ),
                      Text(
                        DateFormatter.formatTimeOnly(metric.submissionDate),
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 9,
                          color: Color(0xFF1B6CA4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 12,
                  ),
                  child: Text(
                    '${metric.bpSystolic ?? '--'}/${metric.bpDiastolic ?? '--'}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      color: Color(0xFF1B6CA4),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 12,
                  ),
                  child: Text(
                    '${metric.pulseRate ?? '--'}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      color: Color(0xFF1B6CA4),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 12,
                  ),
                  child: Text(
                    classifyBloodPressure(
                      metric.bpSystolic,
                      metric.bpDiastolic,
                    ).toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color:
                          {
                            'NORMAL': Color(0xFF19AC4A),
                            'ELEVATED': Color(0xFF199DAC),
                            'HIGH': Color(0xFFAC191F),
                          }[classifyBloodPressure(
                            metric.bpSystolic,
                            metric.bpDiastolic,
                          ).toUpperCase()] ??
                          Colors.grey,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      case 'risk':
        return IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: Text(
                    entryId,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: Color(0xFF1B6CA4),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormatter.formatDateOnly(metric.submissionDate),
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: Color(0xFF1B6CA4),
                        ),
                      ),
                      Text(
                        DateFormatter.formatTimeOnly(metric.submissionDate),
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          color: Color(0xFF1B6CA4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: Text(
                    (metric.riskClassification ?? 'UNKNOWN').toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: getRiskColor(
                        metric.riskClassification ?? 'UNKNOWN',
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: Text(
                    metric.riskScore != null
                        ? '${metric.riskScore!.toStringAsFixed(1)}%'
                        : '--',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: getRiskColor(
                        metric.riskClassification ?? 'UNKNOWN',
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Color getRiskColor(String risk) {
    switch (risk.toLowerCase()) {
      case 'low':
        return const Color(0xFF19AC4A);
      case 'medium':
        return const Color(0xFF199DAC);
      case 'high':
        return const Color(0xFFAC191F);
      default:
        return Colors.grey;
    }
  }

  /// Classifies blood pressure based on systolic and diastolic values.
  String classifyBloodPressure(int? systolic, int? diastolic) {
    if (systolic == null || diastolic == null) return '';

    if (systolic >= 140 || diastolic >= 90) return 'HIGH';
    if (systolic >= 130 || diastolic >= 80) return 'ELEVATED';
    return 'NORMAL';
  }
}
