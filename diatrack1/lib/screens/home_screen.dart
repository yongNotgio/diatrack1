import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';
import 'add_metrics_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> patientData;

  const HomeScreen({super.key, required this.patientData});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  late Future<List<Map<String, dynamic>>> _metricsFuture;
  late String _patientId;

  @override
  void initState() {
    super.initState();
    _patientId = widget.patientData['patient_id'] as String;
    _loadMetrics();
  }

  void _loadMetrics() {
    setState(() {
      _metricsFuture = _supabaseService.getHealthMetrics(_patientId);
    });
  }

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  String _formatDateTime(String? isoString) {
    if (isoString == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(isoString).toLocal();
      return DateFormat('MMM d, yyyy - hh:mm a').format(dateTime);
    } catch (e) {
      return 'Invalid Date';
    }
  }

  Future<void> _editLog(Map<String, dynamic> metric) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                AddMetricsScreen(patientId: _patientId, existingMetric: metric),
      ),
    );

    if (result == true) {
      _loadMetrics();
    }
  }

  @override
  Widget build(BuildContext context) {
    final String patientName =
        "${widget.patientData['first_name'] ?? ''} ${widget.patientData['last_name'] ?? ''}";

    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, $patientName'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadMetrics(),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Medications Card - Added at the top
              if (widget.patientData['medication'] != null &&
                  (widget.patientData['medication'] as String).isNotEmpty)
                Card(
                  margin: const EdgeInsets.all(8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Medications',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.patientData['medication'] as String,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),

              // Metrics List
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _metricsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error loading metrics: ${snapshot.error}'),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text(
                        'No health metrics recorded yet.\nTap the + button to add your first entry!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    );
                  }

                  final metrics = snapshot.data!;

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(8.0),
                    itemCount: metrics.length,
                    itemBuilder: (context, index) {
                      final metric = metrics[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        elevation: 2.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Log Entry - ${_formatDateTime(metric['submission_date'] as String?)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 20),
                                        color: Colors.blue,
                                        onPressed: () => _editLog(metric),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (metric['blood_glucose'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4.0),
                                  child: Text(
                                    'Blood Glucose: ${metric['blood_glucose']} mg/dL',
                                  ),
                                ),
                              if (metric['bp_systolic'] != null &&
                                  metric['bp_diastolic'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4.0),
                                  child: Text(
                                    'Blood Pressure: ${metric['bp_systolic']} / ${metric['bp_diastolic']} mmHg',
                                  ),
                                ),
                              if (metric['pulse_rate'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4.0),
                                  child: Text(
                                    'Pulse Rate: ${metric['pulse_rate']} bpm',
                                  ),
                                ),
                              if (metric['notes'] != null &&
                                  (metric['notes'] as String).isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 4.0,
                                    bottom: 4.0,
                                  ),
                                  child: Text('Notes: ${metric['notes']}'),
                                ),
                              if (metric['wound_photo_url'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Image.network(
                                    metric['wound_photo_url']!,
                                    height: 100,
                                    width: 100,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              if (metric['food_photo_url'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Image.network(
                                    metric['food_photo_url']!,
                                    height: 100,
                                    width: 100,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddMetricsScreen(patientId: _patientId),
            ),
          );
          if (result == true) {
            _loadMetrics();
          }
        },
        tooltip: 'Add New Metric Log',
        child: const Icon(Icons.add),
      ),
    );
  }
}
