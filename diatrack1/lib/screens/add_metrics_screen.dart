import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../services/supabase_service.dart';

class AddMetricsScreen extends StatefulWidget {
  final String patientId;
  final Map<String, dynamic>? existingMetric;

  const AddMetricsScreen({
    super.key,
    required this.patientId,
    this.existingMetric,
  });

  @override
  State<AddMetricsScreen> createState() => _AddMetricsScreenState();
}

class _AddMetricsScreenState extends State<AddMetricsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabaseService = SupabaseService();

  final _glucoseController = TextEditingController();
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();
  final _pulseController = TextEditingController();
  final _notesController = TextEditingController();

  XFile? _woundImageFile;
  XFile? _foodImageFile;
  String? _woundPhotoUrl;
  String? _foodPhotoUrl;
  bool _isUploading = false;
  String? _uploadError;

  @override
  void initState() {
    super.initState();
    if (widget.existingMetric != null) {
      _loadExistingData();
    }
  }

  void _loadExistingData() {
    final metric = widget.existingMetric!;
    _glucoseController.text = metric['blood_glucose']?.toString() ?? '';
    _systolicController.text = metric['bp_systolic']?.toString() ?? '';
    _diastolicController.text = metric['bp_diastolic']?.toString() ?? '';
    _pulseController.text = metric['pulse_rate']?.toString() ?? '';
    _notesController.text = metric['notes']?.toString() ?? '';
    _woundPhotoUrl = metric['wound_photo_url']?.toString();
    _foodPhotoUrl = metric['food_photo_url']?.toString();
  }

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
          _woundPhotoUrl = null;
        } else {
          _foodImageFile = pickedFile;
          _foodPhotoUrl = null;
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
    if (!_formKey.currentState!.validate()) return;
    if (_isUploading) return;

    setState(() {
      _isUploading = true;
      _uploadError = null;
    });

    try {
      if (_woundImageFile != null) {
        final url = await _supabaseService.uploadImage(
          _woundImageFile!,
          'wound-photos',
          widget.patientId,
        );
        if (url == null) throw Exception("Wound photo upload failed.");
        _woundPhotoUrl = url;
      }

      if (_foodImageFile != null) {
        final url = await _supabaseService.uploadImage(
          _foodImageFile!,
          'food-photos',
          widget.patientId,
        );
        if (url == null) throw Exception("Food photo upload failed.");
        _foodPhotoUrl = url;
      }

      if (widget.existingMetric != null) {
        final existing = widget.existingMetric!;
        if (_woundImageFile != null && existing['wound_photo_url'] != null) {
          await _supabaseService.deleteImage(existing['wound_photo_url']!);
        }
        if (_foodImageFile != null && existing['food_photo_url'] != null) {
          await _supabaseService.deleteImage(existing['food_photo_url']!);
        }
      }

      await _supabaseService.addHealthMetric(
        patientId: widget.patientId,
        bloodGlucose: double.tryParse(_glucoseController.text),
        bpSystolic: int.tryParse(_systolicController.text),
        bpDiastolic: int.tryParse(_diastolicController.text),
        pulseRate: int.tryParse(_pulseController.text),
        woundPhotoUrl: _woundPhotoUrl,
        foodPhotoUrl: _foodPhotoUrl,
        notes: _notesController.text.trim(),
        metricId: widget.existingMetric?['id'],
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Metrics saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
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
      appBar: AppBar(
        title: Text(
          widget.existingMetric == null
              ? 'Add New Health Log'
              : 'Edit Health Log',
        ),
      ),
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
              TextFormField(
                controller: _glucoseController,
                decoration: const InputDecoration(
                  labelText: 'Blood Glucose (mg/dL)',
                  prefixIcon: Icon(Icons.opacity),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _systolicController,
                      decoration: const InputDecoration(
                        labelText: 'BP Systolic (mmHg)',
                        prefixIcon: Icon(Icons.favorite_border),
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
                        prefixIcon: Icon(Icons.favorite),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pulseController,
                decoration: const InputDecoration(
                  labelText: 'Pulse Rate (bpm)',
                  prefixIcon: Icon(Icons.monitor_heart),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 24),
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
                    onPressed: () => _showImagePickerOptions(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey[50],
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (_woundImageFile != null || _woundPhotoUrl != null)
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
                              _woundImageFile?.name ?? 'Existing photo',
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
                                () => setState(() {
                                  _woundImageFile = null;
                                  _woundPhotoUrl = null;
                                }),
                            tooltip: 'Remove image',
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              if (_woundImageFile != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Image.file(
                    File(_woundImageFile!.path),
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
              if (_woundPhotoUrl != null && _woundImageFile == null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Image.network(
                    _woundPhotoUrl!,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 24),
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
                    onPressed: () => _showImagePickerOptions(false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[50],
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (_foodImageFile != null || _foodPhotoUrl != null)
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
                              _foodImageFile?.name ?? 'Existing photo',
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
                                () => setState(() {
                                  _foodImageFile = null;
                                  _foodPhotoUrl = null;
                                }),
                            tooltip: 'Remove image',
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              if (_foodImageFile != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Image.file(
                    File(_foodImageFile!.path),
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
              if (_foodPhotoUrl != null && _foodImageFile == null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Image.network(
                    _foodPhotoUrl!,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'Any additional details...',
                  prefixIcon: Icon(Icons.notes),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 30),
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
              _isUploading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Save Log'),
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
