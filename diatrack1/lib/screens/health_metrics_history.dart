import 'package:flutter/material.dart';
import '../models/health_metric.dart';
import '../services/supabase_service.dart';
import '../utils/date_formatter.dart';
import '../widgets/overview_cards.dart';
import '../widgets/blood_sugar_chart.dart';
import '../widgets/blood_pressure_chart.dart';
import '../widgets/wound_photos_section.dart';

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
              // TODO: Implement notifications
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
    if (systolic > 180 || diastolic > 120) return 'CRISIS';
    if (systolic >= 140 || diastolic >= 90) return 'HIGH';
    if (systolic >= 130 || diastolic >= 80) return 'ELEVATED';
    if (systolic >= 120 && diastolic < 80) return 'ELEVATED';
    if (systolic < 120 && diastolic < 80) return 'NORMAL';
    return '';
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
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showFilterDialog();
                    },
                    icon: const Icon(Icons.filter_list, size: 18),
                    label: Text(
                      _currentFilter == 'General Summary'
                          ? 'Filter'
                          : _currentFilter,
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0D629E),
                      side: const BorderSide(color: Color(0xFF0D629E)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('Export'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0D629E),
                      side: const BorderSide(color: Color(0xFF0D629E)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Current Filter Label
          if (_currentFilter != 'General Summary')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFFF2FBFF),
              child: Text(
                _currentFilter,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0D629E),
                  fontSize: 16,
                ),
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
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E5E5)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFFF2FBFF),
                borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: Row(
                children: [
                  const Text(
                    'Table',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                      fontSize: 14,
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

            // Table Headers
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE5E5E5))),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Text(
                      'Entry ID',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Date and Time',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      'Blood Glucose',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      'Blood Pressure',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      'Risk Classification',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Table Content
            Expanded(
              child: ListView.builder(
                itemCount: widget.metrics.length,
                itemBuilder: (context, index) {
                  final metric = widget.metrics[index];
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color:
                              index == widget.metrics.length - 1
                                  ? Colors.transparent
                                  : const Color(0xFFE5E5E5),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Text(
                            '#${1000 + index}',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            DateFormatter.formatDateTime(metric.submissionDate),
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            '${metric.bloodGlucose?.toStringAsFixed(0) ?? '--'} mg/dL',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            '${metric.bpSystolic ?? '--'}/${metric.bpDiastolic ?? '--'}',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            (metric.riskClassification ?? 'UNKNOWN')
                                .toUpperCase(),
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: getRiskColor(
                                metric.riskClassification ?? 'UNKNOWN',
                              ),
                            ),
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
    );
  }

  Widget _buildSpecificTable(String metricType) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E5E5)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFFF2FBFF),
                borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: Row(
                children: [
                  const Text(
                    'Table',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                      fontSize: 14,
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

            // Table Headers
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE5E5E5))),
              ),
              child: _buildTableHeaders(metricType),
            ),

            // Table Content
            Expanded(
              child: ListView.builder(
                itemCount: widget.metrics.length,
                itemBuilder: (context, index) {
                  final metric = widget.metrics[index];
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color:
                              index == widget.metrics.length - 1
                                  ? Colors.transparent
                                  : const Color(0xFFE5E5E5),
                        ),
                      ),
                    ),
                    child: _buildTableRow(metric, index, metricType),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeaders(String metricType) {
    switch (metricType) {
      case 'glucose':
        return Row(
          children: [
            Expanded(
              flex: 1,
              child: Text(
                'Entry ID',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                'Date and Time',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                'Blood Glucose',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ],
        );
      case 'pressure':
        return Row(
          children: [
            Expanded(
              flex: 1,
              child: Text(
                'Entry ID',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                'Date and Time',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                'Blood Pressure',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                'BP Class',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ],
        );
      case 'risk':
        return Row(
          children: [
            Expanded(
              flex: 1,
              child: Text(
                'Entry ID',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                'Date and Time',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                'Risk Class',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTableRow(HealthMetric metric, int index, String metricType) {
    switch (metricType) {
      case 'glucose':
        return Row(
          children: [
            Expanded(
              flex: 1,
              child: Text(
                '#${1000 + index}',
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 12),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                DateFormatter.formatDateTime(metric.submissionDate),
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 12),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                '${metric.bloodGlucose?.toStringAsFixed(0) ?? '--'} mg/dL',
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 12),
              ),
            ),
          ],
        );
      case 'pressure':
        return Row(
          children: [
            Expanded(
              flex: 1,
              child: Text(
                '#${1000 + index}',
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 12),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                DateFormatter.formatDateTime(metric.submissionDate),
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 12),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                '${metric.bpSystolic ?? '--'}/${metric.bpDiastolic ?? '--'}',
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 12),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                (metric.bpClassification ?? '').toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color:
                      {
                        'NORMAL': Color(0xFF19AC4A),
                        'ELEVATED': Color(0xFF199DAC),
                        'HIGH': Color(0xFFAC191F),
                        'CRISIS': Colors.red,
                      }[metric.bpClassification?.toUpperCase() ?? ''] ??
                      Colors.grey,
                ),
              ),
            ),
          ],
        );
      case 'risk':
        return Row(
          children: [
            Expanded(
              flex: 1,
              child: Text(
                '#${1000 + index}',
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 12),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                DateFormatter.formatDateTime(metric.submissionDate),
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 12),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                (metric.riskClassification ?? 'UNKNOWN').toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: getRiskColor(metric.riskClassification ?? 'UNKNOWN'),
                ),
              ),
            ),
          ],
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
}
