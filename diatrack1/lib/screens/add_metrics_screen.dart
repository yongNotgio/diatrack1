import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../services/supabase_service.dart';

class AddMetricsScreen extends StatefulWidget {
  final String patientId;
  final Map<String, dynamic>? existingMetric;
  final String? phase; // Add this line

  const AddMetricsScreen({
    super.key,
    required this.patientId,
    this.existingMetric,
    this.phase, // Add this line
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
  final _notesController = TextEditingController();

  XFile? _woundImageFile;
  String? _woundPhotoUrl;
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
    _notesController.text = metric['notes']?.toString() ?? '';
    _woundPhotoUrl = metric['wound_photo_url']?.toString();
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _supabaseService.pickImage(source);
    if (pickedFile != null) {
      setState(() {
        _woundImageFile = pickedFile;
        _woundPhotoUrl = null;
      });
    }
  }

  void _showImagePickerOptions() {
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
                  _pickImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () {
                  _pickImage(ImageSource.camera);
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

      if (widget.existingMetric != null) {
        final existing = widget.existingMetric!;
        if (_woundImageFile != null && existing['wound_photo_url'] != null) {
          await _supabaseService.deleteImage(existing['wound_photo_url']!);
        }
      }

      await _supabaseService.addHealthMetric(
        patientId: widget.patientId,
        bloodGlucose: double.tryParse(_glucoseController.text),
        bpSystolic: int.tryParse(_systolicController.text),
        bpDiastolic: int.tryParse(_diastolicController.text),
        woundPhotoUrl: _woundPhotoUrl,
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
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Image.asset('assets/images/diatrack_logo.png', height: 32),
            const SizedBox(width: 8),
            Text(
              widget.existingMetric == null ? '' : '',
              style: const TextStyle(
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Blood Pressure',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const Text(
                    'Log your blood pressure to keep your doctor updated.',
                    style: TextStyle(fontSize: 14, color: Colors.blueGrey),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _systolicController,
                          decoration: InputDecoration(
                            labelText: 'Systolic (mmHg)',
                            labelStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey,
                            ),
                            prefixIcon: const Icon(
                              Icons.favorite_border,
                              color: Colors.blue,
                            ),
                            filled: true,
                            fillColor: Colors.blueGrey[50],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _diastolicController,
                          decoration: InputDecoration(
                            labelText: 'Diastolic (mmHg)',
                            labelStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey,
                            ),
                            prefixIcon: const Icon(
                              Icons.favorite,
                              color: Colors.blue,
                            ),
                            filled: true,
                            fillColor: Colors.blueGrey[50],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Blood Glucose',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const Text(
                    'Log your fasting blood sugar to keep your doctor updated.',
                    style: TextStyle(fontSize: 14, color: Colors.blueGrey),
                  ),
                  const SizedBox(height: 8),
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
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,1}'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (widget.phase == "Post-Operative") ...[
                    const Text(
                      'Upload Wound Photo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const Text(
                      'Please attach a wound image to update your doctor on its progress.',
                      style: TextStyle(fontSize: 14, color: Colors.blueGrey),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Click to Upload'),
                          onPressed: _showImagePickerOptions,
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
                  ],
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
                      : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.save),
                          label: const Text('Save Log'),
                          onPressed: _submitMetrics,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15.0),
                          ),
                        ),
                      ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
