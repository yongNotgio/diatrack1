import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  late Future<Map<String, dynamic>?> _appointmentFuture;
  late String _patientId;

  @override
  void initState() {
    super.initState();
    _patientId = widget.patientData['patient_id'] as String;
    _loadMetrics();
    _loadAppointment();
  }

  void _loadMetrics() {
    setState(() {
      _metricsFuture = _supabaseService.getHealthMetrics(_patientId);
    });
  }

  void _loadAppointment() {
    setState(() {
      _appointmentFuture = _supabaseService.getUpcomingAppointment(_patientId);
    });
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  String _formatDate(String? isoString) {
    if (isoString == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(isoString).toLocal();
      return DateFormat('MMMM d, yyyy hh:mm a').format(dateTime);
    } catch (e) {
      return 'Invalid Date';
    }
  }

  Widget _buildFullWidthCard(
    String title,
    String value,
    String unit,
    String date,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    unit,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Taken last: $date',
                style: const TextStyle(
                  fontSize: 18,
                  color: Color.fromARGB(255, 63, 62, 62),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
        onRefresh: () async {
          _loadMetrics();
          _loadAppointment();
        },
        child: FutureBuilder<List<Map<String, dynamic>>>(
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
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'No health metrics recorded yet.\nTap the + button to add your first entry!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              );
            }

            final metric = snapshot.data!.first;
            final date = _formatDate(metric['submission_date'] as String?);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // UPCOMING APPOINTMENT CARD
                  FutureBuilder<Map<String, dynamic>?>(
                    future: _appointmentFuture,
                    builder: (context, apptSnapshot) {
                      String content;
                      if (apptSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        content = 'Loading upcoming appointments...';
                      } else if (apptSnapshot.hasError) {
                        content = 'Error loading appointments.';
                      } else if (!apptSnapshot.hasData ||
                          apptSnapshot.data == null) {
                        content = 'No upcoming appointments.';
                      } else {
                        final appt = apptSnapshot.data!;
                        content =
                            'Next Appointment:\n${_formatDate(appt['appointment_datetime'])}\nwith Dr. ${appt['doctor_name']}';
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Text(
                              content,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // MEDICATION CARD (fixed fallback)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Current Medications',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              (widget.patientData['medication'] as String?)
                                          ?.isNotEmpty ==
                                      true
                                  ? widget.patientData['medication'] as String
                                  : 'No current medications.',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  if (metric['blood_glucose'] != null)
                    _buildFullWidthCard(
                      'Blood Glucose (Fasting Blood Sugar - FBS)',
                      metric['blood_glucose'].toString(),
                      'mmol/L',
                      date,
                    ),

                  if (metric['bp_systolic'] != null &&
                      metric['bp_diastolic'] != null)
                    _buildFullWidthCard(
                      'Blood Pressure (Systolic / Diastolic)',
                      '${metric['bp_systolic']} / ${metric['bp_diastolic']}',
                      'mmHg',
                      date,
                    ),

                  if (metric['pulse_rate'] != null)
                    _buildFullWidthCard(
                      'Pulse Rate',
                      metric['pulse_rate'].toString(),
                      'bpm',
                      date,
                    ),

                  if (metric['notes'] != null &&
                      (metric['notes'] as String).isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Patient Notes',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                metric['notes'],
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  if (metric['wound_photo_url'] != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: Text(
                                'Wound Photo',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                            Image.network(
                              metric['wound_photo_url']!,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ],
                        ),
                      ),
                    ),

                  if (metric['food_photo_url'] != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: Text(
                                'Meal Photo',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                            Image.network(
                              metric['food_photo_url']!,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
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
