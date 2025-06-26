import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Medication {
  final String id;
  final String name;
  final String dosage;
  final String timeOfDay;
  final bool taken;

  Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.timeOfDay,
    required this.taken,
  });

  factory Medication.fromRow(Map<String, dynamic> row) {
    return Medication(
      id: row['id'].toString(),
      name: row['name'] ?? '',
      dosage: row['dosage'] ?? '',
      timeOfDay: row['time_of_day'] ?? '',
      taken: row['taken'] ?? false,
    );
  }
}

class MedicationScreen extends StatefulWidget {
  final String patientId;
  const MedicationScreen({Key? key, required this.patientId}) : super(key: key);

  @override
  State<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends State<MedicationScreen> {
  final supabase = Supabase.instance.client;
  final today = DateTime.now();
  bool loading = true;
  Map<String, List<Medication>> grouped = {
    'morning': [],
    'noon': [],
    'dinner': [],
  };

  @override
  void initState() {
    super.initState();
    _loadMeds();
  }

  Future<void> _loadMeds() async {
    setState(() => loading = true);
    final patientId = widget.patientId;
    final todayStr =
        "${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
    // 1. Query all active medications for today
    final freqRows = await supabase
        .from('medication_frequencies')
        .select('time_of_day,medication_id,medications(name,dosage,user_id)')
        .eq('medications.user_id', patientId)
        .lte('start_date', todayStr);
    // 2. Ensure medication_schedules entries exist for today
    for (final row in freqRows) {
      final medId = row['medication_id'];
      final times =
          row['time_of_day'] is List
              ? row['time_of_day']
              : [row['time_of_day']];
      for (final time in times) {
        final existsList = await supabase
            .from('medication_schedules')
            .select('id')
            .eq('medication_id', medId)
            .eq('date', todayStr)
            .eq('time_of_day', time);
        final exists = existsList.isNotEmpty ? existsList.first : null;
        if (exists == null) {
          await supabase.from('medication_schedules').insert({
            'medication_id': medId,
            'date': todayStr,
            'time_of_day': time,
            'taken': false,
          });
        }
      }
    }
    // 3. Query all meds to display (flat join, not nested)
    final rows = await supabase
        .from('medication_schedules')
        .select('id,time_of_day,taken,medications(name,dosage,user_id)')
        .eq('medications.user_id', patientId)
        .eq('date', todayStr)
        .order('time_of_day');
    final Map<String, List<Medication>> newGrouped = {
      'morning': [],
      'noon': [],
      'dinner': [],
    };
    for (final row in rows) {
      if (row['medications'] == null)
        continue; // Defensive: skip if join failed
      final med = Medication(
        id: row['id'].toString(),
        name: row['medications']['name'] ?? '',
        dosage: row['medications']['dosage'] ?? '',
        timeOfDay: row['time_of_day'] ?? '',
        taken: row['taken'] ?? false,
      );
      if (newGrouped.containsKey(med.timeOfDay)) {
        newGrouped[med.timeOfDay]!.add(med);
      }
    }
    setState(() {
      grouped = newGrouped;
      loading = false;
    });
  }

  Future<void> _markTaken(String scheduleId) async {
    await supabase
        .from('medication_schedules')
        .update({'taken': true})
        .eq('id', scheduleId);
    _loadMeds();
  }

  @override
  Widget build(BuildContext context) {
    final List<String> times = ['morning', 'noon', 'dinner'];
    final List<String> timeLabels = ['Morning', 'Noon', 'Dinner'];
    final todayStr =
        "${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
    final dateDisplay =
        "${today.year}, ${_monthName(today.month)} ${today.day}, ${today.year}";
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Image.asset('assets/images/diatrack_logo.png', height: 32),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Medications',
                  style: TextStyle(
                    color: Color(0xFF1DA1F2),
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                SizedBox(height: 2),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_none,
              color: Color(0xFF1DA1F2),
            ),
            onPressed: () {},
          ),
        ],
        iconTheme: const IconThemeData(color: Color(0xFF1DA1F2)),
      ),
      body:
          loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Please tick on the check marks to indicate you have taken the medicine',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        _dateHeader(today),
                        style: const TextStyle(
                          color: Color(0xFF1DA1F2),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (int idx = 0; idx < times.length; idx++) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 8,
                        ),
                        child: Text(
                          timeLabels[idx],
                          style: const TextStyle(
                            color: Color(0xFF1DA1F2),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      ..._buildMedCards(grouped[times[idx]] ?? []),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
    );
  }

  List<Widget> _buildMedCards(List<Medication> meds) {
    return meds.map((med) {
      final isTaken = med.taken;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Container(
          decoration: BoxDecoration(
            color: isTaken ? const Color(0xFFB3E5FC) : const Color(0xFF1DA1F2),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 8,
            ),
            leading: IconButton(
              icon: Icon(
                Icons.check_circle,
                color: isTaken ? Colors.white : Colors.white,
                size: 28,
              ),
              onPressed: isTaken ? null : () => _markTaken(med.id),
            ),
            title: Text(
              med.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              med.dosage,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color:
                    isTaken
                        ? Colors.white.withOpacity(0.2)
                        : Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isTaken ? 'Done Taking' : 'Not Taken',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  String _monthName(int month) {
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month];
  }

  String _dateHeader(DateTime date) {
    return "${_monthName(date.month)} ${date.day}, ${date.year}";
  }
}
