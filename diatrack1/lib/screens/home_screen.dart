import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/supabase_service.dart';
import 'add_metrics_screen.dart';
import 'login_screen.dart';
import './medication.dart';
import './health_metrics_history.dart';

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

  void _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Logout'),
            content: const Text('Are you sure you want to log out?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
    );
    if (shouldLogout == true) {
      _logout();
    }
  }

  String _formatDate(String? isoString) {
    if (isoString == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(isoString);
      return DateFormat('MMMM d, yyyy hh:mm a').format(dateTime);
    } catch (e) {
      return 'Invalid Date';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Define text styles with Poppins font
    const textTheme = TextTheme(
      bodyLarge: TextStyle(fontFamily: 'Poppins'),
      bodyMedium: TextStyle(fontFamily: 'Poppins'),
      titleLarge: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold),
      titleMedium: TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w600,
      ),
      labelLarge: TextStyle(fontFamily: 'Poppins'),
    );

    final String patientName =
        "${widget.patientData['first_name'] ?? ''} ${widget.patientData['last_name'] ?? ''}";
    final String diagnosis =
        widget.patientData['diagnosis'] ?? 'Type II - Diabetes';
    final String surgeryStatus = widget.patientData['phase'] ?? 'Not Found';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Color(0xFF1DA1F2)),
          onPressed: () {},
        ),
        title: Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Image.asset(
            'assets/images/diatrack_logo.png',
            height: 32,
            fit: BoxFit.contain,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF1DA1F2)),
            tooltip: 'Refresh',
            onPressed: () {
              _loadMetrics();
              _loadAppointment();
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.notifications_none,
              color: Color(0xFF1DA1F2),
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Logout',
            onPressed: _confirmLogout,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _metricsFuture,
        builder: (context, snapshot) {
          final metric =
              (snapshot.hasData && snapshot.data!.isNotEmpty)
                  ? snapshot.data!.first
                  : null;
          final date =
              metric != null
                  ? _formatDate(metric['submission_date'] as String?)
                  : DateFormat('MMMM d, yyyy').format(DateTime.now());

          return RefreshIndicator(
            onRefresh: () async {
              _loadMetrics();
              _loadAppointment();
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Welcome & Profile
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Welcome',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  color: Colors.grey,
                                  fontSize: 18,
                                ),
                              ),
                              Text(
                                patientName,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  color: Color(0xFF1DA1F2),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 28,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFE2E2),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      diagnosis.toUpperCase(),
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        color: Color(0xFFD32F2F),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFE2E2),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      surgeryStatus.toUpperCase(),
                                      style: const TextStyle(
                                        color: Color(0xFFD32F2F),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        CircleAvatar(
                          radius: 28,
                          backgroundImage: AssetImage(
                            'assets/images/avatar.png',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Attending Physician Card
                  FutureBuilder<Map<String, dynamic>?>(
                    future: _appointmentFuture,
                    builder: (context, snapshot) {
                      String nextCheckup = 'No upcoming appointment';
                      String nextCheckupTime = '';
                      String doctorLastName = '';
                      String doctorFirstName = '';

                      // Parse doctor name to split into first and last name
                      String fullDoctorName =
                          widget.patientData['doctor_name'] ??
                          'Doctor Not Found';
                      List<String> nameParts = fullDoctorName.split(' ');
                      if (nameParts.length >= 2) {
                        doctorFirstName = nameParts[0];
                        doctorLastName = nameParts.sublist(1).join(' ');
                      } else {
                        doctorLastName = fullDoctorName;
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        nextCheckup = 'Loading...';
                      } else if (snapshot.hasData && snapshot.data != null) {
                        final appt = snapshot.data!;
                        if (appt['appointment_datetime'] != null) {
                          final dt = DateTime.parse(
                            appt['appointment_datetime'],
                          );
                          nextCheckup =
                              DateFormat(
                                'MMMM d, yyyy',
                              ).format(dt).toUpperCase();
                          nextCheckupTime =
                              DateFormat('h a').format(dt).toUpperCase();
                        }
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFB300),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/images/doctor.png',
                                height: 180,
                                width: 120,
                                fit: BoxFit.cover,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Attending Physician',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      doctorLastName.toUpperCase(),
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 32,
                                        height: 1.0,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '$doctorFirstName ${doctorFirstName.isNotEmpty ? "M.D." : ""}',
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 20,
                                        height: 1.2,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Next Checkup',
                                                style: TextStyle(
                                                  fontFamily: 'Poppins',
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 8,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withOpacity(0.95),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  nextCheckup,
                                                  style: const TextStyle(
                                                    fontFamily: 'Poppins',
                                                    color: Color(0xFFFFB300),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Time',
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 8,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(
                                                  0.95,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                nextCheckupTime.isNotEmpty
                                                    ? nextCheckupTime
                                                    : '-',
                                                style: const TextStyle(
                                                  fontFamily: 'Poppins',
                                                  color: Color(0xFFFFB300),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Add a record card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4FC3F7), Color(0xFF1DA1F2)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    _tag('BP'),
                                    const SizedBox(width: 4),
                                    _tag('GLUCOSE'),
                                    const SizedBox(width: 4),
                                    _tag('PHOTO'),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  DateFormat('MMMM d').format(DateTime.now()),
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 32,
                                  ),
                                ),
                                Text(
                                  '${DateFormat('yyyy').format(DateTime.now())} | ${DateFormat('EEEE').format(DateTime.now())} | ${DateFormat('h:mm a').format(DateTime.now())}',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Ink(
                            decoration: const ShapeDecoration(
                              color: Colors.white,
                              shape: CircleBorder(),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.add,
                                color: Color.fromARGB(255, 255, 255, 255),
                                size: 32,
                              ),
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => AddMetricsScreen(
                                          patientId: _patientId,
                                          phase:
                                              widget
                                                  .patientData['phase'], // Pass phase here
                                        ),
                                  ),
                                );
                                if (result == true) {
                                  _loadMetrics();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Main Menu
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Main Menu',
                          style: TextStyle(
                            color: Color(0xFF1DA1F2),
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _menuIcon(
                              'Medicine',
                              'assets/images/medicine.png',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => MedicationScreen(
                                          patientId: _patientId,
                                        ),
                                  ),
                                );
                              },
                            ),
                            _menuIcon(
                              'History',
                              'assets/images/history.png',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => HealthMetricsHistory(
                                          patientId:
                                              widget.patientData['patient_id'],
                                        ),
                                  ),
                                );
                              },
                            ),
                            _menuIcon(
                              'Reminders',
                              'assets/images/reminder.png',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Latest Health Metric
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Latest Health Metric',
                          style: TextStyle(
                            color: Color(0xFF1DA1F2),
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (metric != null) ...[
                          _metricCard(
                            title: 'Blood Glucose',
                            value: metric['blood_glucose']?.toString() ?? '--',
                            unit: 'mg/dL',
                            tag: 'MOD',
                            icon: Icons.bloodtype,
                            taken: date,
                          ),
                          _miniMetricCard(
                            title: 'Blood Pressure',
                            value: '${metric['bp_systolic'] ?? '--'}',
                            value2: '${metric['bp_diastolic'] ?? '--'}',
                            unit: 'mmHg',
                            taken: date,
                            status: 'LOW',
                          ),
                          _miniMetricCard(
                            title: 'Risk for Surgery',
                            value: '',
                            value2: '',
                            unit: '',
                            taken: date,
                            status:
                                widget.patientData['risk_classification']
                                    ?.toString()
                                    .toUpperCase() ??
                                'N/A',
                            isRisk: true,
                          ),
                        ] else
                          const Text(
                            'No metrics recorded yet.',
                            style: TextStyle(color: Colors.grey),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ...existing code...
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _tag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _menuIcon(String label, String asset, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: Image.asset(asset, height: 40),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF1DA1F2),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricCard({
    required String title,
    required String value,
    required String unit,
    required String tag,
    required IconData icon,
    required String taken,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF1DA1F2)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1DA1F2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                unit,
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Taken last: $taken',
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _miniMetricCard({
    required String title,
    required String value,
    required String value2,
    required String unit,
    required String taken,
    required String status,
    bool isRisk = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isRisk ? Icons.warning_amber_rounded : Icons.favorite,
                color: isRisk ? Colors.green : const Color(0xFF1DA1F2),
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (!isRisk)
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1DA1F2),
                  ),
                ),
                const Text(
                  '/',
                  style: TextStyle(fontSize: 24, color: Colors.grey),
                ),
                Text(
                  value2,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1DA1F2),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  unit,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isRisk ? 'Classified last: $taken' : 'Taken last: $taken',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
