import 'dart:io'; // Required for File type
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For input formatters
import 'package:image_picker/image_picker.dart';
import '../services/supabase_service.dart';

class AddMetricsScreen extends StatefulWidget {
  final String patientId;

  const AddMetricsScreen({super.key, required this.patientId});

  @override
  State<AddMetricsScreen> createState() => _AddMetricsScreenState();
}

class _AddMetricsScreenState extends State<AddMetricsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabaseService = SupabaseService();

  // Controllers for form fields
  final _glucoseController = TextEditingController();
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();
  final _pulseController = TextEditingController();
  final _notesController = TextEditingController();

  XFile? _woundImageFile;
  XFile? _foodImageFile;
  bool _isUploading = false;
  String? _uploadError;

  @override
  void dispose() {
    _glucoseController.dispose();
    _systolicController.dispose();
    _diastolicController.dispose();
    _pulseController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source, bool isWoundPhoto) async {
    final XFile? pickedFile = await _supabaseService.pickImage(source);
    if (pickedFile != null) {
      setState(() {
        if (isWoundPhoto) {
          _woundImageFile = pickedFile;
        } else {
          _foodImageFile = pickedFile;
        }
      });
    }
  }

  void _showImagePickerOptions(bool isWoundPhoto) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Photo Library'),
                onTap: () {
                  _pickImage(ImageSource.gallery, isWoundPhoto);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () {
                  _pickImage(ImageSource.camera, isWoundPhoto);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitMetrics() async {
    if (!_formKey.currentState!.validate()) {
      return; // Don't submit if form is invalid
    }
    if (_isUploading) return; // Prevent double submission

    setState(() {
      _isUploading = true;
      _uploadError = null;
    });

    String? woundPhotoUrl;
    String? foodPhotoUrl;

    try {
      // 1. Upload Wound Photo (if selected)
      if (_woundImageFile != null) {
        // Use 'wound_photos' bucket - MAKE SURE THIS BUCKET EXISTS AND IS PUBLIC (or handle signed URLs)
        woundPhotoUrl = await _supabaseService.uploadImage(
          _woundImageFile!,
          'wound-photos', // Supabase Storage Bucket Name
          widget.patientId,
        );
        if (woundPhotoUrl == null)
          throw Exception("Wound photo upload failed.");
      }

      // 2. Upload Food Photo (if selected)
      if (_foodImageFile != null) {
        // Use 'food_photos' bucket - MAKE SURE THIS BUCKET EXISTS AND IS PUBLIC (or handle signed URLs)
        foodPhotoUrl = await _supabaseService.uploadImage(
          _foodImageFile!,
          'food-photos', // Supabase Storage Bucket Name
          widget.patientId,
        );
        if (foodPhotoUrl == null) throw Exception("Food photo upload failed.");
      }

      // 3. Submit metric data along with photo URLs
      await _supabaseService.addHealthMetric(
        patientId: widget.patientId,
        bloodGlucose: double.tryParse(_glucoseController.text),
        bpSystolic: int.tryParse(_systolicController.text),
        bpDiastolic: int.tryParse(_diastolicController.text),
        pulseRate: int.tryParse(_pulseController.text),
        woundPhotoUrl: woundPhotoUrl, // Pass the URL obtained after upload
        foodPhotoUrl: foodPhotoUrl, // Pass the URL obtained after upload
        notes: _notesController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Metrics submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Pop screen and indicate success
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _uploadError =
              "Submission failed: ${e.toString().replaceFirst('Exception: ', '')}";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_uploadError!),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Health Log')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                'Enter Current Readings',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Blood Glucose
              TextFormField(
                controller: _glucoseController,
                decoration: const InputDecoration(
                  labelText: 'Blood Glucose (mg/dL)',
                  prefixIcon: Icon(Icons.opacity), // Droplet icon
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
                ], // Allow numbers and one decimal
                // validator: (value) { // Optional validation
                //   if (value != null && value.isNotEmpty && double.tryParse(value) == null) {
                //     return 'Please enter a valid number';
                //   }
                //   return null;
                // },
              ),
              const SizedBox(height: 16),

              // Blood Pressure (Systolic/Diastolic) - Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _systolicController,
                      decoration: const InputDecoration(
                        labelText: 'BP Systolic (mmHg)',
                        prefixIcon: Icon(
                          Icons.favorite_border,
                        ), // Heart icon variation
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _diastolicController,
                      decoration: const InputDecoration(
                        labelText: 'BP Diastolic (mmHg)',
                        prefixIcon: Icon(Icons.favorite), // Filled heart icon
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Pulse Rate
              TextFormField(
                controller: _pulseController,
                decoration: const InputDecoration(
                  labelText: 'Pulse Rate (bpm)',
                  prefixIcon: Icon(Icons.monitor_heart), // ECG icon
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 24),

              // Wound Photo Upload
              const Text(
                'Wound Photo (Optional)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Upload Wound Photo'),
                    onPressed:
                        () => _showImagePickerOptions(
                          true,
                        ), // true for wound photo
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey[50],
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (_woundImageFile != null)
                    Expanded(
                      // Use Expanded to prevent overflow
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _woundImageFile!.name,
                              overflow:
                                  TextOverflow
                                      .ellipsis, // Handle long file names
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.clear,
                              size: 18,
                              color: Colors.redAccent,
                            ),
                            onPressed:
                                () => setState(() => _woundImageFile = null),
                            tooltip: 'Remove image',
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              if (_woundImageFile != null) // Show preview
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Image.file(
                    File(_woundImageFile!.path),
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 24),

              // Food/Diet Photo Upload
              const Text(
                'Food/Diet Photo (Optional)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.restaurant_menu),
                    label: const Text('Upload Food Photo'),
                    onPressed:
                        () => _showImagePickerOptions(
                          false,
                        ), // false for food photo
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[50],
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (_foodImageFile != null)
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _foodImageFile!.name,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.clear,
                              size: 18,
                              color: Colors.redAccent,
                            ),
                            onPressed:
                                () => setState(() => _foodImageFile = null),
                            tooltip: 'Remove image',
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              if (_foodImageFile != null) // Show preview
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Image.file(
                    File(_foodImageFile!.path),
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 24),

              // Notes
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'Any additional details...',
                  prefixIcon: Icon(Icons.notes),
                  alignLabelWithHint: true, // Good for multi-line
                ),
                maxLines: 3, // Allow multiple lines for notes
              ),
              const SizedBox(height: 30),

              // Error Message
              if (_uploadError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    _uploadError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Submit Button
              _isUploading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Submit Log'),
                    onPressed: _submitMetrics,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15.0),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
