import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../services/supabase_service.dart';
import '../widgets/appointment_dialog.dart';
import '../widgets/create_appointment_dialog.dart';
import 'add_metrics_screen.dart';
import 'login_screen.dart';
import './medication.dart';
import './health_metrics_history.dart';
import './notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> patientData;

  const HomeScreen({super.key, required this.patientData});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// Classifies blood pressure values into categories
  String classifyBloodPressure(int? systolic, int? diastolic) {
    if (systolic == null || diastolic == null) return '';

    if (systolic >= 140 || diastolic >= 90) return 'HIGH';
    if (systolic >= 130 || diastolic >= 80) return 'ELEVATED';
    return 'NORMAL';
  }

  final SupabaseService _supabaseService = SupabaseService();
  late Future<List<Map<String, dynamic>>> _metricsFuture;
  late Future<Map<String, dynamic>?> _appointmentFuture;
  late String _patientId;
  int _unreadNotificationCount = 0;

  @override
  void initState() {
    super.initState();
    _patientId = widget.patientData['patient_id'] as String;
    _loadMetrics();
    _loadAppointment();
    _loadUnreadNotificationCount();
  }

  void _loadUnreadNotificationCount() async {
    final count = await _supabaseService.getUnreadNotificationCount(_patientId);
    if (mounted) {
      setState(() {
        _unreadNotificationCount = count;
      });
    }
  }

  void _loadMetrics() {
    setState(() {
      _metricsFuture = _supabaseService.getHealthMetrics(_patientId);
    });
  }

  void _loadAppointment() {
    setState(() {
      _appointmentFuture = _supabaseService.getUpcomingAppointmentWithDetails(
        _patientId,
      );
    });
  }

  String _getPatientFullName() {
    return "${widget.patientData['first_name'] ?? ''} ${widget.patientData['last_name'] ?? ''}";
  }

  void _showAppointmentDialog(Map<String, dynamic> appointment) {
    final appointmentId = appointment['appointment_id']?.toString();
    if (appointmentId == null || appointment['appointment_datetime'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to load appointment details.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final appointmentDateTime = DateTime.parse(
      appointment['appointment_datetime'],
    );
    final doctor = appointment['doctor'];
    final secretary = appointment['secretary'];

    String doctorName = 'Unknown';
    String? doctorId;
    if (doctor != null) {
      doctorName =
          '${doctor['first_name'] ?? ''} ${doctor['last_name'] ?? ''}'.trim();
      doctorId = doctor['doctor_id']?.toString();
    }

    String? secretaryId;
    if (secretary != null && secretary['secretary_id'] != null) {
      secretaryId = secretary['secretary_id']?.toString();
    }

    final originalDateTimeStr = DateFormat(
      'MMM d, yyyy \'at\' h:mm a',
    ).format(appointmentDateTime);

    showDialog(
      context: context,
      builder:
          (dialogContext) => AppointmentDialog(
            appointmentId: appointmentId,
            currentDateTime: appointmentDateTime,
            doctorName: doctorName,
            onCancel: () async {
              try {
                await _supabaseService.cancelAppointment(
                  appointmentId: appointmentId,
                  patientId: _patientId,
                  patientName: _getPatientFullName(),
                  secretaryId: secretaryId,
                  originalDateTime: originalDateTimeStr,
                );
                _loadAppointment();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Appointment cancelled successfully. The secretary has been notified.',
                        style: TextStyle(fontFamily: 'Poppins'),
                      ),
                      backgroundColor: Color(0xFF4CAF50),
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Failed to cancel appointment: $e',
                        style: const TextStyle(fontFamily: 'Poppins'),
                      ),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            },
            onReschedule: (newDateTime) async {
              try {
                await _supabaseService.rescheduleAppointment(
                  appointmentId: appointmentId,
                  patientId: _patientId,
                  patientName: _getPatientFullName(),
                  newDateTime: newDateTime,
                  doctorId:
                      doctorId ??
                      widget.patientData['preferred_doctor_id'] ??
                      '',
                  secretaryId: secretaryId,
                  originalDateTime: originalDateTimeStr,
                );
                Navigator.pop(dialogContext); // Close dialog only on success
                _loadAppointment();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Appointment rescheduled to ${DateFormat('MMM d, yyyy \'at\' h:mm a').format(newDateTime)}. The secretary has been notified.',
                        style: const TextStyle(fontFamily: 'Poppins'),
                      ),
                      backgroundColor: const Color(0xFF4CAF50),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              } catch (e) {
                // Show alert dialog for time slot conflicts
                showDialog(
                  context: dialogContext,
                  builder:
                      (alertContext) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: const Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.redAccent,
                              size: 28,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Time Slot Unavailable',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0D629E),
                              ),
                            ),
                          ],
                        ),
                        content: Text(
                          e.toString().contains('already taken')
                              ? 'This time slot is already taken. Please choose a different date or time.'
                              : 'Failed to reschedule appointment. Please try again.',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        actions: [
                          ElevatedButton(
                            onPressed: () => Navigator.pop(alertContext),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1DA1F2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'OK',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                );
              }
            },
          ),
    );
  }

  void _showCreateAppointmentDialog() {
    final doctorName = widget.patientData['doctor_name'] ?? 'Your Doctor';
    final doctorId = widget.patientData['preferred_doctor_id']?.toString();

    if (doctorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No preferred doctor assigned. Please contact your clinic.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder:
          (dialogContext) => CreateAppointmentDialog(
            doctorName: doctorName,
            onCreate: (dateTime) async {
              try {
                await _supabaseService.createAppointment(
                  patientId: _patientId,
                  patientName: _getPatientFullName(),
                  doctorId: doctorId,
                  appointmentDateTime: dateTime,
                );
                Navigator.pop(dialogContext); // Close dialog only on success
                _loadAppointment();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Appointment scheduled for ${DateFormat('MMM d, yyyy \'at\' h:mm a').format(dateTime)}. The secretary has been notified.',
                        style: const TextStyle(fontFamily: 'Poppins'),
                      ),
                      backgroundColor: const Color(0xFF4CAF50),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              } catch (e) {
                // Show alert dialog for errors
                showDialog(
                  context: dialogContext,
                  builder:
                      (alertContext) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: const Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.redAccent,
                              size: 28,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Time Slot Unavailable',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0D629E),
                              ),
                            ),
                          ],
                        ),
                        content: Text(
                          e.toString().contains('already taken')
                              ? 'This time slot is already taken. Please choose a different date or time.'
                              : 'Failed to create appointment. Please try again.',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        actions: [
                          ElevatedButton(
                            onPressed: () => Navigator.pop(alertContext),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1DA1F2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'OK',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                );
              }
            },
          ),
    );
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

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        _confirmLogout();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFF),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: Builder(
            builder:
                (context) => IconButton(
                  icon: const Icon(Icons.menu, color: Color(0xFF1DA1F2)),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                ),
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
                _loadUnreadNotificationCount();
              },
            ),
            Stack(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.notifications_none,
                    color: Color(0xFF1DA1F2),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                NotificationsScreen(patientId: _patientId),
                      ),
                    ).then((_) => _loadUnreadNotificationCount());
                  },
                ),
                if (_unreadNotificationCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 8,
                        minHeight: 8,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        drawer: _buildDrawer(context, patientName),
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
                            backgroundColor: const Color(0xFFE6F3FF),
                            backgroundImage:
                                widget.patientData['patient_picture'] != null &&
                                        (widget.patientData['patient_picture']
                                                as String)
                                            .isNotEmpty
                                    ? NetworkImage(
                                      widget.patientData['patient_picture']
                                          as String,
                                    )
                                    : null,
                            child:
                                widget.patientData['patient_picture'] == null ||
                                        (widget.patientData['patient_picture']
                                                as String)
                                            .isEmpty
                                    ? Image.asset(
                                      'assets/images/avatar.png',
                                      fit: BoxFit.cover,
                                    )
                                    : null,
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
                        bool hasAppointment = false;
                        Map<String, dynamic>? appointmentData;

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

                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          nextCheckup = 'Loading...';
                        } else if (snapshot.hasData && snapshot.data != null) {
                          final appt = snapshot.data!;
                          appointmentData = appt;
                          if (appt['appointment_datetime'] != null) {
                            final dt = DateTime.parse(
                              appt['appointment_datetime'],
                            );
                            nextCheckup =
                                DateFormat(
                                  'MMM d, yyyy',
                                ).format(dt).toUpperCase();
                            nextCheckupTime =
                                DateFormat('h a').format(dt).toUpperCase();
                            hasAppointment = true;
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                                GestureDetector(
                                                  onTap: () {
                                                    if (hasAppointment &&
                                                        appointmentData !=
                                                            null) {
                                                      _showAppointmentDialog(
                                                        appointmentData!,
                                                      );
                                                    } else {
                                                      _showCreateAppointmentDialog();
                                                    }
                                                  },
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 16,
                                                          vertical: 8,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white
                                                          .withOpacity(0.95),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                      border: Border.all(
                                                        color: Colors.white,
                                                        width: 2,
                                                      ),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        if (!hasAppointment)
                                                          const Icon(
                                                            Icons.add,
                                                            color: Color(
                                                              0xFFFFB300,
                                                            ),
                                                            size: 14,
                                                          ),
                                                        Flexible(
                                                          child: Text(
                                                            hasAppointment
                                                                ? nextCheckup
                                                                : 'Schedule Appointment',
                                                            style:
                                                                const TextStyle(
                                                                  fontFamily:
                                                                      'Poppins',
                                                                  color: Color(
                                                                    0xFFFFB300,
                                                                  ),
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 13,
                                                                ),
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          if (hasAppointment)
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
                                                GestureDetector(
                                                  onTap:
                                                      () =>
                                                          _showAppointmentDialog(
                                                            appointmentData!,
                                                          ),
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 16,
                                                          vertical: 8,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white
                                                          .withOpacity(0.95),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                      border: Border.all(
                                                        color: Colors.white,
                                                        width: 2,
                                                      ),
                                                    ),
                                                    child: Text(
                                                      nextCheckupTime.isNotEmpty
                                                          ? nextCheckupTime
                                                          : '-',
                                                      style: const TextStyle(
                                                        fontFamily: 'Poppins',
                                                        color: Color(
                                                          0xFFFFB300,
                                                        ),
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 13,
                                                      ),
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
                      child: GestureDetector(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => AddMetricsScreen(
                                    patientId: _patientId,
                                    phase: widget.patientData['phase'],
                                  ),
                            ),
                          );
                          if (result == true) {
                            _loadMetrics();
                          }
                        },
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
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text(
                                          'Add a record?',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(width: 3),
                                        Image.asset(
                                          'assets/images/card2.png',
                                          height: 14,
                                          fit: BoxFit.contain,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      DateFormat(
                                        'MMMM d',
                                      ).format(DateTime.now()),
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 40,
                                        height: 1.0,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
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
                              const SizedBox(width: 12),
                              Image.asset(
                                'assets/images/add.png',
                                height: 60,
                                width: 60,
                                fit: BoxFit.contain,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Main Menu
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'Main Menu',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: Color(0xFF0D629E),
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
                                                widget
                                                    .patientData['patient_id'],
                                          ),
                                    ),
                                  );
                                },
                              ),
                              _menuIcon(
                                'Reminders',
                                'assets/images/reminder.png',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => NotificationsScreen(
                                            patientId: _patientId,
                                          ),
                                    ),
                                  );
                                },
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
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'Latest Health Metric',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: Color(0xFF0D629E),
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (metric != null) ...[
                            _metricCard(
                              title: 'Blood Glucose',
                              value:
                                  metric['blood_glucose']?.toString() ?? '--',
                              unit: 'mg/dL',
                              tag: 'MOD',
                              icon: Icons.bloodtype,
                              taken: date,
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: _miniMetricCard(
                                    title: 'Blood Pressure',
                                    value: '${metric['bp_systolic'] ?? '--'}',
                                    value2: '${metric['bp_diastolic'] ?? '--'}',
                                    unit: 'mmHg',
                                    taken: date,
                                    status: classifyBloodPressure(
                                      metric['bp_systolic'] as int?,
                                      metric['bp_diastolic'] as int?,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _miniMetricCard(
                                    title: 'Risk for Surgery',
                                    value: '',
                                    value2: '',
                                    unit: '',
                                    taken: date,
                                    status:
                                        metric['risk_classification']
                                            ?.toString()
                                            .toUpperCase() ??
                                        'N/A',
                                    isRisk: true,
                                  ),
                                ),
                              ],
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
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, String patientName) {
    final String? profilePicture =
        widget.patientData['patient_picture'] as String?;

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // Drawer Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0D629E), Color(0xFF1DA1F2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile Picture
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  backgroundImage:
                      profilePicture != null && profilePicture.isNotEmpty
                          ? NetworkImage(profilePicture)
                          : null,
                  child:
                      profilePicture == null || profilePicture.isEmpty
                          ? const Icon(
                            Icons.person,
                            size: 50,
                            color: Color(0xFF1DA1F2),
                          )
                          : null,
                ),
                const SizedBox(height: 16),
                Text(
                  patientName,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt,
                    color: Color(0xFF1DA1F2),
                  ),
                  title: const Text(
                    'Update Profile Picture',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      color: Color(0xFF0D629E),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    _updateProfilePicture();
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: const Text(
                    'Logout',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      color: Colors.redAccent,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    _confirmLogout();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateProfilePicture() async {
    try {
      // Show image source selection dialog
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text(
                'Select Image Source',
                style: TextStyle(fontFamily: 'Poppins'),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.camera_alt,
                      color: Color(0xFF1DA1F2),
                    ),
                    title: const Text(
                      'Camera',
                      style: TextStyle(fontFamily: 'Poppins'),
                    ),
                    onTap: () => Navigator.pop(context, ImageSource.camera),
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.photo_library,
                      color: Color(0xFF1DA1F2),
                    ),
                    title: const Text(
                      'Gallery',
                      style: TextStyle(fontFamily: 'Poppins'),
                    ),
                    onTap: () => Navigator.pop(context, ImageSource.gallery),
                  ),
                ],
              ),
            ),
      );

      if (source == null) return;

      // Pick image
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image == null) return;

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => const Center(
              child: CircularProgressIndicator(color: Color(0xFF1DA1F2)),
            ),
      );

      // Upload image and update patient record
      final String newImageUrl = await _supabaseService
          .updatePatientProfilePicture(patientId: _patientId, imageFile: image);

      // Update local patient data
      setState(() {
        widget.patientData['patient_picture'] = newImageUrl;
      });

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Profile picture updated successfully!',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
            backgroundColor: Color(0xFF19AC4A),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if open
      if (mounted) Navigator.pop(context);

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update profile picture: $e',
              style: const TextStyle(fontFamily: 'Poppins'),
            ),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
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
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                asset,
                height: 80,
                width: 80,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              color: Color(0xFF1DA1F2),
              fontWeight: FontWeight.w600,
              fontSize: 15,
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
        color: const Color(0xFFE2F6FF),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                  color: Color(0xFF0D629E),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8A50D),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Image.asset('assets/images/image 18.png', height: 50, width: 50),
              const SizedBox(width: 4),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 80,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF45B6E8),
                  height: 0.9,
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF45B6E8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'fbs',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    unit,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: Color(0xFF45B6E8),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Taken last: $taken',
            style: const TextStyle(
              fontFamily: 'Poppins',
              color: Color(0xFF45B6E8),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
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
        color: const Color(0xFFE2F6FF),
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
      child:
          isRisk
              ? _buildRiskCard(status, taken)
              : _buildBloodPressureCard(value, value2, unit, status, taken),
    );
  }

  Widget _buildBloodPressureCard(
    String sys,
    String dia,
    String unit,
    String status,
    String taken,
  ) {
    // Determine BP badge color based on status
    Color badgeColor;
    switch (status.toUpperCase()) {
      case 'NORMAL':
        badgeColor = const Color(0xFF4CAF50); // green
        break;
      case 'ELEVATED':
        badgeColor = const Color(0xFFFFC107); // amber/yellow
        break;
      case 'HIGH':
      case 'CRISIS':
        badgeColor = const Color(0xFFF44336); // red
        break;
      default:
        badgeColor = const Color(0xFF6B7280); // gray
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Blood\nPressure',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
                fontSize: 16,
                color: Color(0xFF0D629E),
                height: 1.2,
              ),
            ),
            const SizedBox(width: 8),
            Image.asset('assets/images/bp.png', width: 28, height: 28),
          ],
        ),
        const SizedBox(height: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SYS section
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Image.asset(
                    'assets/images/sys.png',
                    width: 24,
                    height: 24,
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    sys,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 52,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF45B6E8),
                      height: 0.9,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // DIA section
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Image.asset(
                    'assets/images/dia.png',
                    width: 24,
                    height: 24,
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    dia,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 52,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF45B6E8),
                      height: 0.9,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Taken last:\n$taken',
          style: const TextStyle(
            fontFamily: 'Poppins',
            color: Color(0xFF45B6E8),
            fontSize: 10,
            height: 1.2,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildRiskCard(String status, String taken) {
    // Determine risk level color and icon
    Color riskColor;
    String riskIcon;

    if (status.toUpperCase() == 'LOW') {
      riskColor = const Color(0xFF4CAF50);
      riskIcon = 'assets/images/low_risk.png';
    } else if (status.toUpperCase() == 'MODERATE') {
      riskColor = const Color(0xFFFFA726);
      riskIcon = 'assets/images/medium_risk.png';
    } else {
      riskColor = const Color(0xFFEF5350);
      riskIcon = 'assets/images/high_risk.png';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Risk for\nSurgery',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
                fontSize: 16,
                color: Color(0xFF0D629E),
                height: 1.2,
              ),
            ),
            const SizedBox(width: 8),
            Image.asset('assets/images/risk.png', width: 28, height: 28),
          ],
        ),
        const SizedBox(height: 12),
        Center(child: Image.asset(riskIcon, width: 100, height: 100)),
        const SizedBox(height: 12),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: riskColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status.toUpperCase(),
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Classified last:\n$taken',
          textAlign: TextAlign.left,
          style: const TextStyle(
            fontFamily: 'Poppins',
            color: Color(0xFF45B6E8),
            fontSize: 10,
            height: 1.2,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
