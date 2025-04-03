// --- lib/screens/add_reminder_screen.dart ---
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/reminders_provider.dart';
// import 'package:intl/intl.dart'; // If needed for time formatting display

class AddReminderScreen extends StatefulWidget {
  static const routeName = '/add-reminder';

  const AddReminderScreen({Key? key}) : super(key: key);

  @override
  State<AddReminderScreen> createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends State<AddReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Form values
  String? _selectedReminderType;
  TimeOfDay? _selectedTime;
  String? _frequency = 'daily'; // Default or allow selection
  final _messageController = TextEditingController();

  final List<String> _reminderTypes = [
    'glucose_fasting',
    'glucose_postprandial',
    'blood_pressure',
    'pulse_rate',
    'medication', // Add other relevant types
    'other',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _submitReminder() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || _selectedTime == null || _selectedReminderType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields (Type and Time).'),
        ),
      );
      return;
    }
    _formKey.currentState?.save();

    setState(() {
      _isLoading = true;
    });

    final remindersProvider = Provider.of<RemindersProvider>(
      context,
      listen: false,
    );

    final success = await remindersProvider.addReminder(
      reminderType: _selectedReminderType!,
      reminderTime: _selectedTime!,
      frequency: _frequency, // Pass selected frequency
      message: _messageController.text.isEmpty ? null : _messageController.text,
      isActive: true, // Default to active
    );

    setState(() {
      _isLoading = false;
    });

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reminder added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(); // Go back
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            remindersProvider.error ??
                'Failed to add reminder. Please try again.',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Reminder')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Reminder Type Dropdown
              DropdownButtonFormField<String>(
                value: _selectedReminderType,
                hint: const Text('Select Reminder Type *'),
                isExpanded: true,
                items:
                    _reminderTypes.map((String type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(
                          type.replaceAll('_', ' ').capitalizeFirst(),
                        ), // Format display text
                      );
                    }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedReminderType = newValue;
                  });
                },
                validator:
                    (value) => value == null ? 'Please select a type' : null,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Time Picker
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _selectedTime == null
                      ? 'Select Time *'
                      : 'Selected Time: ${_selectedTime!.format(context)}',
                ), // Display selected time
                trailing: const Icon(Icons.access_time),
                onTap: () => _selectTime(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  side: BorderSide(
                    color:
                        Theme.of(
                          context,
                        ).inputDecorationTheme.border?.borderSide.color ??
                        Colors.grey,
                  ),
                ),
              ),
              if (_selectedTime ==
                  null) // Show validation message manually if needed
                Padding(
                  padding: const EdgeInsets.only(left: 12.0, top: 8.0),
                  child: Text(
                    'Please select a time',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              // Frequency (Example: Simple Dropdown - could be more complex)
              DropdownButtonFormField<String>(
                value: _frequency, // Default to daily
                hint: const Text('Select Frequency'),
                isExpanded: true,
                items:
                    [
                          'daily',
                          'weekdays',
                          'weekends',
                        ] // Add more options as needed
                        .map(
                          (String freq) => DropdownMenuItem<String>(
                            value: freq,
                            child: Text(freq.capitalizeFirst()),
                          ),
                        )
                        .toList(),
                onChanged: (newValue) {
                  setState(() {
                    _frequency = newValue;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Frequency',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Optional Message
              TextFormField(
                controller: _messageController,
                decoration: InputDecoration(
                  labelText: 'Optional Message',
                  hintText: 'e.g., Take Metformin 500mg',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 30),

              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: _submitReminder,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: const Text('Save Reminder'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper extension for capitalizing strings
extension StringExtension on String {
  String capitalizeFirst() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
