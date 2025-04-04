import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import 'login_screen.dart'; // Go back to login after signup

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _dobController =
      TextEditingController(); // For displaying selected date
  final _contactController = TextEditingController();

  final _supabaseService = SupabaseService();
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _selectedDateOfBirth;
  String? _selectedDoctorId;
  String? _selectedSurgicalStatus;
  List<Map<String, dynamic>> _doctors = []; // List to hold fetched doctors

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _dobController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _loadDoctors() async {
    setState(() => _isLoading = true); // Show loading indicator for doctors too
    try {
      final doctorsList = await _supabaseService.getDoctors();
      if (mounted) {
        setState(() {
          _doctors = doctorsList;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load doctors: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDateOfBirth) {
      setState(() {
        _selectedDateOfBirth = picked;
        _dobController.text =
            "${picked.toLocal()}".split(' ')[0]; // Format as YYYY-MM-DD
      });
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) {
      return; // Don't proceed if form is invalid
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Passwords do not match.';
      });
      return;
    }
    if (_selectedDoctorId == null) {
      setState(() {
        _errorMessage = 'Please select a preferred doctor.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final patientData = await _supabaseService.signUpPatient(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        preferredDoctorId: _selectedDoctorId,
        surgicalStatus: _selectedSurgicalStatus,
        dateOfBirth: _selectedDateOfBirth,
        contactInfo:
            _contactController.text.trim().isNotEmpty
                ? _contactController.text.trim()
                : null,
      );

      if (patientData != null && mounted) {
        // Show success message and navigate back to Login
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sign up successful! Please log in.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Go back to Login Screen
      } else if (mounted) {
        // Should be caught by exception, but as fallback
        setState(() {
          _errorMessage = 'Sign up failed. Please try again.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst(
            'Exception: ',
            '',
          ); // Show error
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Patient Sign Up')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                'Create Account',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // First Name
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name',
                  prefixIcon: Icon(Icons.person),
                ),
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Please enter first name'
                            : null,
              ),
              const SizedBox(height: 16),

              // Last Name
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Please enter last name'
                            : null,
              ),
              const SizedBox(height: 16),

              // Email
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty || !value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Password
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty || value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Confirm Password
              TextFormField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Date of Birth
              TextFormField(
                controller: _dobController,
                decoration: InputDecoration(
                  labelText: 'Date of Birth (Optional)',
                  prefixIcon: const Icon(Icons.calendar_today),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.edit_calendar),
                    onPressed: _selectDate,
                  ),
                ),
                readOnly: true, // Prevent manual editing
                onTap: _selectDate,
              ),
              const SizedBox(height: 16),

              // Contact Info
              TextFormField(
                controller: _contactController,
                decoration: const InputDecoration(
                  labelText: 'Contact Number (Optional)',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              // Preferred Doctor Dropdown
              if (_doctors.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: _selectedDoctorId,
                  decoration: const InputDecoration(
                    labelText: 'Preferred Doctor',
                    prefixIcon: Icon(Icons.medical_services),
                  ),
                  items:
                      _doctors.map((doctor) {
                        return DropdownMenuItem<String>(
                          value: doctor['doctor_id'] as String,
                          child: Text(
                            '${doctor['first_name']} ${doctor['last_name']} (${doctor['specialization'] ?? 'General'})',
                          ),
                        );
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDoctorId = value;
                    });
                  },
                  validator:
                      (value) =>
                          value == null ? 'Please select a doctor' : null,
                )
              else if (_isLoading) // Show loading indicator while fetching doctors
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text("Loading doctors..."),
                  ),
                )
              else // Show message if doctors couldn't be loaded
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Could not load doctors. Please try again later.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                value: _selectedSurgicalStatus,
                decoration: const InputDecoration(
                  labelText: 'Surgical Status',
                  prefixIcon: Icon(Icons.medical_services),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Pre-Operative',
                    child: Text('Pre-Operative'),
                  ),
                  DropdownMenuItem(
                    value: 'Post-Operative',
                    child: Text('Post-Operative'),
                  ),
                ],
                validator:
                    (value) =>
                        value == null ? 'Please select surgical status' : null,
                onChanged: (value) {
                  setState(() {
                    _selectedSurgicalStatus = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              // Error Message Display
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Sign Up Button
              _isLoading &&
                      _doctors
                          .isEmpty // Show loading only if doctors are still loading initially
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                    // Disable button if doctors haven't loaded or during signup process
                    onPressed:
                        (_isLoading || _doctors.isEmpty) ? null : _signUp,
                    child:
                        _isLoading
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Text('Sign Up'),
                  ),
              const SizedBox(height: 20),
              const Text(
                'For demonstration purposes only.',
                style: TextStyle(color: Colors.orange, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
