import 'package:flutter/material.dart';

class MedicationScreen extends StatelessWidget {
  const MedicationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<String> dates = [
      'SAT',
      'SUN',
      'MON',
      'TUE',
      'WED',
      'THU',
      'FRI',
    ];
    final List<String> dateNumbers = ['14', '15', '16', '17', '18', '19', '20'];
    // Example medication data
    final List<Map<String, dynamic>> meds = [
      {
        'time': 'Morning',
        'items': [
          {'name': 'Sultamicillin', 'dose': '1 tab | 750mg', 'taken': true},
          {'name': 'Clindamycin', 'dose': '1 cap | 300mg', 'taken': false},
          {
            'name': 'Telmisartan/HCTZ',
            'dose': '1 tab | 80/12.5 mg',
            'taken': false,
          },
          {
            'name': 'Amlodipine',
            'dose': '1/2 tab | 80/12.5 mg',
            'taken': false,
          },
        ],
      },
      {
        'time': 'Noon',
        'items': [
          {'name': 'Sultamicillin', 'dose': '1 tab | 750mg', 'taken': true},
          {'name': 'Clindamycin', 'dose': '1 cap | 300mg', 'taken': false},
          {
            'name': 'Telmisartan/HCTZ',
            'dose': '1 tab | 80/12.5 mg',
            'taken': false,
          },
          {
            'name': 'Amlodipine',
            'dose': '1/2 tab | 80/12.5 mg',
            'taken': false,
          },
        ],
      },
      {
        'time': 'Dinner',
        'items': [
          {'name': 'Sultamicillin', 'dose': '1 tab | 750mg', 'taken': true},
          {'name': 'Clindamycin', 'dose': '1 cap | 300mg', 'taken': false},
          {
            'name': 'Telmisartan/HCTZ',
            'dose': '1 tab | 80/12.5 mg',
            'taken': false,
          },
          {
            'name': 'Amlodipine',
            'dose': '1/2 tab | 80/12.5 mg',
            'taken': false,
          },
        ],
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Image.asset('assets/images/diatrack_logo.png', height: 32),
            const SizedBox(width: 8),
            const Text(
              'Medications',
              style: TextStyle(
                color: Color(0xFF1DA1F2),
                fontWeight: FontWeight.bold,
              ),
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reminders/Date selector
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(dates.length, (i) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      children: [
                        Text(
                          dates[i],
                          style: const TextStyle(
                            color: Color(0xFFB0B0B0),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          decoration: BoxDecoration(
                            color:
                                i == 1 ? const Color(0xFF1DA1F2) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF1DA1F2)),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: Text(
                            dateNumbers[i],
                            style: TextStyle(
                              color:
                                  i == 1
                                      ? Colors.white
                                      : const Color(0xFF1DA1F2),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Medication sections
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: meds.length,
              itemBuilder: (context, idx) {
                final section = meds[idx];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        section['time'],
                        style: const TextStyle(
                          color: Color(0xFF1DA1F2),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    ...List.generate(section['items'].length, (i) {
                      final med = section['items'][i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color:
                              med['taken']
                                  ? const Color(0xFFB3E5FC)
                                  : const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          leading: Icon(
                            Icons.check_circle,
                            color:
                                med['taken']
                                    ? const Color(0xFF1DA1F2)
                                    : Colors.grey,
                          ),
                          title: Text(
                            med['name'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(med['dose']),
                          trailing: Text(
                            med['taken'] ? 'Done Taking' : 'Not Taken',
                            style: TextStyle(
                              color:
                                  med['taken']
                                      ? const Color(0xFF1DA1F2)
                                      : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
