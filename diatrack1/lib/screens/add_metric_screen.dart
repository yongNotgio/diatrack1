// --- lib/screens/add_metric_screen.dart ---
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For input formatters
import 'package:provider/provider.dart';
import '../providers/metrics_provider.dart';

class AddMetricScreen extends StatefulWidget {
  static const routeName = '/add-metric';

  const AddMetricScreen({Key? key}) : super(key: key);

  @override
  State<AddMetricScreen> createState() => _AddMetricScreenState();
}

class _AddMetricScreenState extends State<AddMetricScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controllers for metric inputs
  final _glucoseFastingController = TextEditingController();
  final _glucosePostprandialController = TextEditingController();
  final _bpSystolicController = TextEditingController();
  final _bpDiastolicController = TextEditingController();
  final _pulseRateController = TextEditingController();

  @override
  void dispose() {
    _glucoseFastingController.dispose();
    _glucosePostprandialController.dispose();
    _bpSystolicController.dispose();
    _bpDiastolicController.dispose();
    _pulseRateController.dispose();
    super.dispose();
  }

  Future<void> _submitMetric() async {
    // Basic validation: Ensure at least one field is filled
    if (_glucoseFastingController.text.isEmpty &&
        _glucosePostprandialController.text.isEmpty &&
        _bpSystolicController.text.isEmpty &&
        _bpDiastolicController.text.isEmpty &&
        _pulseRateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter at least one metric value.'),
        ),
      );
      return;
    }

    // Validate the form (if you add more complex validators)
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }
    _formKey.currentState?.save();

    setState(() {
      _isLoading = true;
    });

    final metricsProvider = Provider.of<MetricsProvider>(
      context,
      listen: false,
    );

    // Parse values safely
    double? glucoseFasting = double.tryParse(_glucoseFastingController.text);
    double? glucosePostprandial = double.tryParse(
      _glucosePostprandialController.text,
    );
    int? bpSystolic = int.tryParse(_bpSystolicController.text);
    int? bpDiastolic = int.tryParse(_bpDiastolicController.text);
    int? pulseRate = int.tryParse(_pulseRateController.text);

    // Additional validation for BP
    if ((bpSystolic != null && bpDiastolic == null) ||
        (bpSystolic == null && bpDiastolic != null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter both Systolic and Diastolic Blood Pressure.',
          ),
        ),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final success = await metricsProvider.addMetric(
      glucoseFasting: glucoseFasting,
      glucosePostprandial: glucosePostprandial,
      bloodPressureSystolic: bpSystolic,
      bloodPressureDiastolic: bpDiastolic,
      pulseRate: pulseRate,
    );

    setState(() {
      _isLoading = false;
    });

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Metric added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(); // Go back to the previous screen
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            metricsProvider.error ?? 'Failed to add metric. Please try again.',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Health Metric')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(
                controller: _glucoseFastingController,
                labelText: 'Glucose - Fasting (mg/dL)',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
              ),
              const SizedBox(height: 15),
              _buildTextField(
                controller: _glucosePostprandialController,
                labelText: 'Glucose - Postprandial (mg/dL)',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
              ),
              const SizedBox(height: 15),
              _buildTextField(
                controller: _bpSystolicController,
                labelText: 'Blood Pressure - Systolic (mmHg)',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 15),
              _buildTextField(
                controller: _bpDiastolicController,
                labelText: 'Blood Pressure - Diastolic (mmHg)',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                // Add validator if needed (e.g., diastolic < systolic)
              ),
              const SizedBox(height: 15),
              _buildTextField(
                controller: _pulseRateController,
                labelText: 'Pulse Rate (bpm)',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 30),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: _submitMetric,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: const Text('Save Metric'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
    );
  }
}
