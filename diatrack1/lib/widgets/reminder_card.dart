// --- lib/widgets/reminder_card.dart ---
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/reminder.dart';
import '../providers/reminders_provider.dart'; // To call delete/toggle
import 'package:provider/provider.dart'; // To access provider

class ReminderCard extends StatelessWidget {
  final Reminder reminder;

  const ReminderCard({Key? key, required this.reminder}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat.jm(); // Format like '8:00 AM'
    final formattedTime = timeFormat.format(
      DateTime(
        2023,
        1,
        1,
        reminder.reminderTime.hour,
        reminder.reminderTime.minute,
      ), // Need a dummy date for format
    );

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          vertical: 8.0,
          horizontal: 16.0,
        ),
        title: Text(
          reminder.reminderType,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Time: $formattedTime'),
            if (reminder.frequency != null && reminder.frequency!.isNotEmpty)
              Text('Frequency: ${reminder.frequency}'),
            if (reminder.message != null && reminder.message!.isNotEmpty)
              Text('Message: ${reminder.message}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: reminder.isActive,
              onChanged: (bool value) {
                // Call provider method to toggle status
                Provider.of<RemindersProvider>(
                  context,
                  listen: false,
                ).toggleReminderActive(reminder);
              },
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red[300]),
              onPressed: () async {
                // Optional: Show confirmation dialog
                final confirm = await showDialog<bool>(
                  context: context,
                  builder:
                      (ctx) => AlertDialog(
                        title: const Text('Delete Reminder?'),
                        content: const Text(
                          'Are you sure you want to delete this reminder?',
                        ),
                        actions: [
                          TextButton(
                            child: const Text('Cancel'),
                            onPressed: () => Navigator.of(ctx).pop(false),
                          ),
                          TextButton(
                            child: const Text('Delete'),
                            onPressed: () => Navigator.of(ctx).pop(true),
                          ),
                        ],
                      ),
                );
                if (confirm == true) {
                  Provider.of<RemindersProvider>(
                    context,
                    listen: false,
                  ).deleteReminder(reminder.reminderId);
                }
              },
            ),
          ],
        ),
        isThreeLine:
            (reminder.frequency != null && reminder.frequency!.isNotEmpty) ||
            (reminder.message != null && reminder.message!.isNotEmpty),
      ),
    );
  }
}
