import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dotted_border/dotted_border.dart';
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 8),
              const Text(
                'Submit Health Metric',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1DA1F2),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              const Text(
                'Log your health metrics to keep your doctor updated.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              // Blood Pressure Section
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Blood Pressure',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1DA1F2),
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Log your blood pressure to keep your doctor updated.',
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Systolic',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1DA1F2),
                                ),
                              ),
                              const SizedBox(height: 4),
                              TextFormField(
                                controller: _systolicController,
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Color(0xFF1DA1F2),
                                    ),
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'mmHg',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Diastolic',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1DA1F2),
                                ),
                              ),
                              const SizedBox(height: 4),
                              TextFormField(
                                controller: _diastolicController,
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Color(0xFF1DA1F2),
                                    ),
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'mmHg',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Blood Glucose Section
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Blood Glucose',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1DA1F2),
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Log your fasting blood sugar to keep your doctor updated.',
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _glucoseController,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFF1DA1F2),
                          ),
                        ),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^[0-9.]*')),
                      ],
                    ),
                  ],
                ),
              ),
              // Wound Photo Section
              if (widget.phase == "Post-Operative") ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Wound Photo',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1DA1F2),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Please attach a wound image to update your doctor on its progress.',
                        style: TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: _showImagePickerOptions,
                        child: DottedBorder(
                          color: const Color(0xFF1DA1F2),
                          borderType: BorderType.RRect,
                          radius: const Radius.circular(12),
                          dashPattern: const [6, 3],
                          strokeWidth: 1.5,
                          child: Container(
                            width: double.infinity,
                            height: 120,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.cloud_upload,
                                  size: 36,
                                  color: Color(0xFF1DA1F2),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _woundImageFile != null
                                      ? 'Image Selected'
                                      : 'Click to Upload',
                                  style: const TextStyle(
                                    color: Color(0xFF1DA1F2),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (_woundImageFile != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Image.file(
                            File(_woundImageFile!.path),
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                      if (_woundPhotoUrl != null && _woundImageFile == null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Image.network(
                            _woundPhotoUrl!,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              // Notes Section
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Additional notes:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1DA1F2),
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        hintText:
                            'Inform your attending physician of any complaint or discomfort',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                          borderSide: BorderSide(color: Color(0xFF1DA1F2)),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
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
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1DA1F2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _submitMetrics,
                      child: const Text(
                        'Save Log',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
              const SizedBox(height: 10),
              const Text(
                'Your submitted data is securely stored and accessible in your health history.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
