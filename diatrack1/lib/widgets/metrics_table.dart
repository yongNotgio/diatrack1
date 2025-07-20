import 'package:flutter/material.dart';
import '../models/health_metric.dart';
import '../utils/date_formatter.dart';

class MetricsTable extends StatefulWidget {
  final List<HealthMetric> metrics;
  final String title;
  final String metricType;

  const MetricsTable({
    Key? key,
    required this.metrics,
    required this.title,
    required this.metricType,
  }) : super(key: key);

  @override
  State<MetricsTable> createState() => _MetricsTableState();
}

class _MetricsTableState extends State<MetricsTable> {
  final TextEditingController _searchController = TextEditingController();
  List<HealthMetric> _filteredMetrics = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _filteredMetrics = widget.metrics;
  }

  @override
  void didUpdateWidget(MetricsTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.metrics != widget.metrics) {
      _filterMetrics();
    }
  }

  void _filterMetrics() {
    if (_searchQuery.isEmpty) {
      setState(() {
        _filteredMetrics = widget.metrics;
      });
    } else {
      setState(() {
        _filteredMetrics =
            widget.metrics.where((metric) {
              final dateStr =
                  DateFormatter.formatDateTime(
                    metric.submissionDate,
                  ).toLowerCase();
              final entryId = metric.id.toLowerCase();

              switch (widget.metricType) {
                case 'glucose':
                  final glucose = metric.bloodGlucose?.toString() ?? '';
                  return dateStr.contains(_searchQuery.toLowerCase()) ||
                      entryId.contains(_searchQuery.toLowerCase()) ||
                      glucose.contains(_searchQuery);
                case 'pressure':
                  final systolic = metric.bpSystolic?.toString() ?? '';
                  final diastolic = metric.bpDiastolic?.toString() ?? '';
                  return dateStr.contains(_searchQuery.toLowerCase()) ||
                      entryId.contains(_searchQuery.toLowerCase()) ||
                      systolic.contains(_searchQuery) ||
                      diastolic.contains(_searchQuery);
                case 'risk':
                  final risk = metric.riskClassification.toLowerCase();
                  return dateStr.contains(_searchQuery.toLowerCase()) ||
                      entryId.contains(_searchQuery.toLowerCase()) ||
                      risk.contains(_searchQuery.toLowerCase());
                default:
                  return dateStr.contains(_searchQuery.toLowerCase()) ||
                      entryId.contains(_searchQuery.toLowerCase());
              }
            }).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
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
                  widget.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF069ADE),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                          _filteredMetrics = widget.metrics;
                        });
                      },
                    ),
                    const Text(
                      'Refresh',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Search Bar
            TextField(
              controller: _searchController,
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
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                _filterMetrics();
              },
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
            const SizedBox(height: 16),
            // Table Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF069ADE).withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Text(
                      'Entry ID',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Date and Time',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      _getMetricColumnTitle(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Table Body
            Container(
              constraints: const BoxConstraints(maxHeight: 400),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _filteredMetrics.length,
                itemBuilder: (context, index) {
                  final metric = _filteredMetrics[index];
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.withOpacity(0.2)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Text(
                            '#${metric.id.padLeft(4, '0')}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF069ADE),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            DateFormatter.formatDateTime(metric.submissionDate),
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            _getMetricValue(metric),
                            style: const TextStyle(fontWeight: FontWeight.w500),
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

  String _getMetricColumnTitle() {
    switch (widget.metricType) {
      case 'glucose':
        return 'Blood Glucose';
      case 'pressure':
        return 'Blood Pressure';
      case 'risk':
        return 'Risk Class';
      default:
        return 'Value';
    }
  }

  String _getMetricValue(HealthMetric metric) {
    switch (widget.metricType) {
      case 'glucose':
        return '${metric.bloodGlucose?.toStringAsFixed(0) ?? '-'} mg/dL';
      case 'pressure':
        return '${metric.bpSystolic ?? '-'}/${metric.bpDiastolic ?? '-'}';
      case 'risk':
        return metric.riskClassification;
      default:
        return '-';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
