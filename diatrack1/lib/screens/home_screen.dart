import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import '../services/supabase_service.dart';
import 'add_metrics_screen.dart';
import 'login_screen.dart'; // For logout

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> patientData; // Pass patient data from login

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
      (Route<dynamic> route) => false, // Remove all previous routes
    );
  }

  // Helper to format date/time nicely
  String _formatDateTime(String? isoString) {
    if (isoString == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(
        isoString,
      ).toUtc().subtract(Duration(hours: 8));
      return DateFormat('MMM d, yyyy - hh:mm a').format(dateTime);
    } catch (e) {
      return 'Invalid Date';
    }
  }

  // Function to handle delete photo
  void _deletePhoto(String photoUrl) {
    // Implement delete photo logic
    setState(() {
      // You would call the service to delete the photo from your storage here
      print('Deleting photo: $photoUrl');
    });
  }

  // Function to handle edit photo
  void _editPhoto(String photoUrl) {
    // Implement edit photo logic
    setState(() {
      // You would navigate to an image edit screen or upload a new image here
      print('Editing photo: $photoUrl');
    });
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
                child: Text(
                  'No health metrics recorded yet.\nTap the + button to add your first entry!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              );
            }

            final metrics = snapshot.data!;

            return ListView.builder(
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
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16.0),
                    title: Text(
                      'Log Entry - ${_formatDateTime(metric['submission_date'] as String?)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (metric['blood_glucose'] != null)
                            Text(
                              'Blood Glucose: ${metric['blood_glucose']} mg/dL',
                            ),
                          if (metric['bp_systolic'] != null &&
                              metric['bp_diastolic'] != null)
                            Text(
                              'Blood Pressure: ${metric['bp_systolic']} / ${metric['bp_diastolic']} mmHg',
                            ),
                          if (metric['pulse_rate'] != null)
                            Text('Pulse Rate: ${metric['pulse_rate']} bpm'),
                          if (metric['notes'] != null &&
                              (metric['notes'] as String).isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text('Notes: ${metric['notes']}'),
                            ),
                          // Display actual photos with options to delete or edit
                          if (metric['wound_photo_url'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Image.network(
                                    metric['wound_photo_url']!,
                                    height: 100,
                                    width: 100,
                                    fit: BoxFit.cover,
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          Icons.edit,
                                          size: 20,
                                          color: Colors.blue,
                                        ),
                                        onPressed:
                                            () => _editPhoto(
                                              metric['wound_photo_url']!,
                                            ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.delete,
                                          size: 20,
                                          color: Colors.red,
                                        ),
                                        onPressed:
                                            () => _deletePhoto(
                                              metric['wound_photo_url']!,
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          if (metric['food_photo_url'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Image.network(
                                    metric['food_photo_url']!,
                                    height: 100,
                                    width: 100,
                                    fit: BoxFit.cover,
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          Icons.edit,
                                          size: 20,
                                          color: Colors.blue,
                                        ),
                                        onPressed:
                                            () => _editPhoto(
                                              metric['food_photo_url']!,
                                            ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.delete,
                                          size: 20,
                                          color: Colors.red,
                                        ),
                                        onPressed:
                                            () => _deletePhoto(
                                              metric['food_photo_url']!,
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
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
