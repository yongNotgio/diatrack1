// --- lib/screens/reminders_screen.dart (Corrected Imports) ---
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/reminders_provider.dart';
// **** Added Missing Model Import ****
import '../models/reminder.dart';
// **** Added Missing Widget Import ****
import '../widgets/reminder_card.dart';
// Corrected import path assuming reminders_screen.dart is in lib/screens/
import 'add_reminder_screen.dart';

class RemindersScreen extends StatelessWidget {
  static const routeName = '/reminders';

  const RemindersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use watch to rebuild when provider notifies listeners
    final remindersProvider = context.watch<RemindersProvider>();
    // No need to get reminders list here, pass the provider to _buildBody

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Reminders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_alarm),
            tooltip: 'Add Reminder',
            onPressed:
                () => Navigator.of(
                  context,
                ).pushNamed(AddReminderScreen.routeName),
          ),
        ],
      ),
      body: RefreshIndicator(
        // Use listen: false when calling methods in callbacks
        onRefresh:
            () =>
                Provider.of<RemindersProvider>(
                  context,
                  listen: false,
                ).fetchReminders(),
        child: _buildBody(context, remindersProvider), // Pass the provider
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        tooltip: 'Add Reminder',
        onPressed:
            () => Navigator.of(context).pushNamed(AddReminderScreen.routeName),
      ),
    );
  }

  // Corrected: Takes RemindersProvider
  Widget _buildBody(BuildContext context, RemindersProvider provider) {
    final reminders = provider.reminders; // Get reminders list from provider

    if (provider.isLoading && reminders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null && reminders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error loading reminders: ${provider.error}'),
            const SizedBox(height: 10),
            ElevatedButton(
              // Use listen: false when calling methods in callbacks
              onPressed:
                  () =>
                      Provider.of<RemindersProvider>(
                        context,
                        listen: false,
                      ).fetchReminders(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (reminders.isEmpty) {
      return const Center(
        child: Text(
          'No reminders set. Tap the + button to add one.',
          textAlign: TextAlign.center,
        ),
      );
    }

    // Display the list of reminders using ReminderCard
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: reminders.length,
      itemBuilder: (ctx, index) => ReminderCard(reminder: reminders[index]),
    );
  }
}
