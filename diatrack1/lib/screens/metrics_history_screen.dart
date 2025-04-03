// --- lib/screens/metrics_history_screen.dart (Corrected Imports) ---
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/metrics_provider.dart';
// **** Added Missing Model Import ****
import '../models/health_metric.dart';
// **** Added Missing Widget Import ****
import '../widgets/metric_card.dart';

class MetricsHistoryScreen extends StatelessWidget {
  static const routeName = '/metrics-history';

  const MetricsHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use watch to rebuild when provider notifies listeners
    final metricsProvider = context.watch<MetricsProvider>();
    // No need to get metrics list here, pass the provider to _buildBody

    return Scaffold(
      appBar: AppBar(title: const Text('Metrics History')),
      body: RefreshIndicator(
        // Use listen: false when calling methods in callbacks
        onRefresh:
            () =>
                Provider.of<MetricsProvider>(
                  context,
                  listen: false,
                ).fetchMetrics(),
        child: _buildBody(context, metricsProvider), // Pass the provider
      ),
    );
  }

  // Corrected: Takes MetricsProvider
  Widget _buildBody(BuildContext context, MetricsProvider provider) {
    final metrics = provider.metrics; // Get metrics list from provider

    if (provider.isLoading && metrics.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null && metrics.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error loading metrics: ${provider.error}'),
            const SizedBox(height: 10),
            ElevatedButton(
              // Use listen: false when calling methods in callbacks
              onPressed:
                  () =>
                      Provider.of<MetricsProvider>(
                        context,
                        listen: false,
                      ).fetchMetrics(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (metrics.isEmpty) {
      return const Center(
        child: Text(
          'No metrics have been recorded yet.',
          textAlign: TextAlign.center,
        ),
      );
    }

    // Display the list of metrics using MetricCard
    return ListView.builder(
      itemCount: metrics.length,
      itemBuilder: (ctx, index) => MetricCard(metric: metrics[index]),
    );
  }
}
