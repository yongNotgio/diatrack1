// --- lib/screens/home_screen.dart (Corrected Imports and Types) ---
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/metrics_provider.dart';
import '../providers/reminders_provider.dart';
// Corrected relative paths assuming home_screen.dart is in lib/screens/
import 'add_metric_screen.dart'; // Corrected import
import 'metrics_history_screen.dart'; // Corrected import
import 'add_reminder_screen.dart'; // Corrected import
import 'reminders_screen.dart'; // Corrected import
// **** Added Missing Model Imports ****
import '../models/health_metric.dart';
import '../models/reminder.dart';
// **** Added Missing Widget Imports ****
import '../widgets/metric_card.dart';
import '../widgets/reminder_card.dart';

class HomeScreen extends StatelessWidget {
  static const routeName = '/home';

  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final patientName = authProvider.patientProfile?.firstName ?? 'User';

    // Watch providers to rebuild if data changes
    final metricsProvider = context.watch<MetricsProvider>();
    final remindersProvider = context.watch<RemindersProvider>();
    final latestMetrics = metricsProvider.metrics;
    final latestReminders = remindersProvider.reminders;

    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, $patientName'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await Provider.of<AuthProvider>(context, listen: false).signOut();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            // Use listen: false when calling methods inside callbacks/onRefresh
            Provider.of<MetricsProvider>(context, listen: false).fetchMetrics(),
            Provider.of<RemindersProvider>(
              context,
              listen: false,
            ).fetchReminders(),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildSectionTitle(context, 'Quick Actions'),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  context,
                  icon: Icons.add_chart,
                  label: 'Add Metric',
                  // Use the imported screen class correctly
                  onPressed:
                      () => Navigator.of(
                        context,
                      ).pushNamed(AddMetricScreen.routeName),
                ),
                _buildActionButton(
                  context,
                  icon: Icons.alarm_add,
                  label: 'Add Reminder',
                  onPressed:
                      () => Navigator.of(
                        context,
                      ).pushNamed(AddReminderScreen.routeName),
                ),
              ],
            ),
            const SizedBox(height: 24),

            _buildSectionTitle(
              context,
              'Recent Health Metrics',
              action: TextButton(
                child: const Text('View All'),
                onPressed:
                    () => Navigator.of(
                      context,
                    ).pushNamed(MetricsHistoryScreen.routeName),
              ),
            ),
            const SizedBox(height: 10),
            // Pass the provider itself for loading state check
            _buildMetricsSummary(context, metricsProvider),
            const SizedBox(height: 24),

            _buildSectionTitle(
              context,
              'Your Reminders',
              action: TextButton(
                child: const Text('Manage'),
                onPressed:
                    () => Navigator.of(
                      context,
                    ).pushNamed(RemindersScreen.routeName),
              ),
            ),
            const SizedBox(height: 10),
            // Pass the provider itself for loading state check
            _buildRemindersSummary(context, remindersProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(
    BuildContext context,
    String title, {
    Widget? action,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        if (action != null) action,
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon),
      label: Text(label),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: const TextStyle(fontSize: 14),
      ),
    );
  }

  // Corrected: Takes MetricsProvider to check loading state and get metrics
  Widget _buildMetricsSummary(
    BuildContext context,
    MetricsProvider metricsProvider,
  ) {
    final metrics = metricsProvider.metrics; // Get metrics list

    if (metricsProvider.isLoading && metrics.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (metricsProvider.error != null && metrics.isEmpty) {
      return Center(child: Text('Error: ${metricsProvider.error}'));
    }
    if (metrics.isEmpty) {
      return const Center(child: Text('No recent metrics recorded.'));
    }
    // Show the latest 1-3 metrics
    final displayMetrics = metrics.take(3).toList();
    // Explicitly type the list for the Column children
    return Column(
      children:
          displayMetrics
              .map<Widget>(
                (metric) => MetricCard(metric: metric),
              ) // Specify <Widget> type argument
              .toList(),
    );
  }

  // Corrected: Takes RemindersProvider
  Widget _buildRemindersSummary(
    BuildContext context,
    RemindersProvider remindersProvider,
  ) {
    final reminders = remindersProvider.reminders; // Get reminders list

    if (remindersProvider.isLoading && reminders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (remindersProvider.error != null && reminders.isEmpty) {
      return Center(child: Text('Error: ${remindersProvider.error}'));
    }
    if (reminders.isEmpty) {
      return const Center(child: Text('You have no reminders set.'));
    }
    // Show the first few reminders
    final displayReminders = reminders.take(3).toList();
    // Explicitly type the list for the Column children
    return Column(
      children:
          displayReminders
              .map<Widget>(
                (reminder) => ReminderCard(reminder: reminder),
              ) // Specify <Widget> type argument
              .toList(),
    );
  }
}
