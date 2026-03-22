// File: lib/screens/faculty/faculty_add_student_screen.dart
// Faculty form to add new student with personal, contact, and parent details

import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class FacultyAddStudentScreen extends StatefulWidget {
  final Map<String, dynamic> department;
  final Map<String, dynamic> classData;

  const FacultyAddStudentScreen({
    super.key,
    required this.department,
    required this.classData,
  });

  @override
  State<FacultyAddStudentScreen> createState() =>
      _FacultyAddStudentScreenState();
}

class _FacultyAddStudentScreenState extends State<FacultyAddStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  // Personal Information
  final _fullNameController = TextEditingController();
  final _registerNumberController = TextEditingController();
  DateTime? _dateOfBirth;
  String? _bloodGroup;
  String? _gender;

  // Contact Information
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();

  // Parent Details
  final _parentNameController = TextEditingController();
  final _parentPhoneController = TextEditingController();
  final _parentEmailController = TextEditingController();
  String _parentRelationship = 'Father';

  // Residential Information
  String _residentialType = 'Day Scholar';
  final _roomNumberController = TextEditingController();
  final _hostelNameController = TextEditingController();

  // Emergency Contact
  final _emergencyContactNameController = TextEditingController();
  final _emergencyContactPhoneController = TextEditingController();
  final _medicalConditionsController = TextEditingController();

  final List<String> _bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];
  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _relationships = ['Father', 'Mother', 'Guardian'];

  @override
  void dispose() {
    _fullNameController.dispose();
    _registerNumberController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _parentNameController.dispose();
    _parentPhoneController.dispose();
    _parentEmailController.dispose();
    _roomNumberController.dispose();
    _hostelNameController.dispose();
    _emergencyContactNameController.dispose();
    _emergencyContactPhoneController.dispose();
    _medicalConditionsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final cs = Theme.of(context).colorScheme;
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(
        const Duration(days: 6570),
      ), // ~18 years
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: cs.copyWith(
              primary: cs.primary,
              surface: cs.surface,
              onSurface: cs.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _dateOfBirth = picked);
    }
  }

  Future<void> _submitForm() async {
    final cs = Theme.of(context).colorScheme;
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill all required fields'),
          backgroundColor: cs.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final studentData = {
        'full_name': _fullNameController.text.trim(),
        'register_number': _registerNumberController.text.trim(),
        'date_of_birth': _dateOfBirth?.toIso8601String(),
        'blood_group': _bloodGroup,
        'gender': _gender,
        'department': widget.department['code'].toString(),
        'year': widget.classData['year'],
        'section': widget.classData['section'],
        'phone_number': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'address': _addressController.text.trim(),
        'parent_name': _parentNameController.text.trim(),
        'parent_phone': _parentPhoneController.text.trim(),
        'parent_email': _parentEmailController.text.trim(),
        'parent_relationship': _parentRelationship,
        'residential_type': _residentialType,
        'room_number': _residentialType == 'Hosteler'
            ? _roomNumberController.text.trim()
            : null,
        'hostel_name': _residentialType == 'Hosteler'
            ? _hostelNameController.text.trim()
            : null,
        'emergency_contact_name': _emergencyContactNameController.text.trim(),
        'emergency_contact_phone': _emergencyContactPhoneController.text.trim(),
        'medical_conditions': _medicalConditionsController.text.trim(),
      };

      await ApiService.addStudent(studentData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Student added successfully!'),
            backgroundColor: Color(0xFF4CAF50), // Fixed success green
          ),
        );
        Navigator.pop(context);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: cs.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Student'),
        actions: [
          if (_isSubmitting)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: cs.primary,
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildSectionHeader('Personal Information', Icons.person, cs),
            _buildTextField(
              controller: _fullNameController,
              label: 'Full Name',
              icon: Icons.person_outline,
              cs: cs,
              validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
            ),
            _buildTextField(
              controller: _registerNumberController,
              label: 'Register Number',
              icon: Icons.badge_outlined,
              cs: cs,
              validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
            ),

            InkWell(
              onTap: _selectDate,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Date of Birth',
                  prefixIcon: Icon(Icons.calendar_today, color: cs.primary),
                ),
                child: Text(
                  _dateOfBirth != null
                      ? '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}'
                      : 'Select date',
                  style: TextStyle(
                    color: _dateOfBirth != null
                        ? cs.onSurface
                        : cs.onSurface.withOpacity(0.4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    label: 'Blood Group',
                    value: _bloodGroup,
                    items: _bloodGroups,
                    onChanged: (v) => setState(() => _bloodGroup = v),
                    icon: Icons.bloodtype_outlined,
                    cs: cs,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDropdown(
                    label: 'Gender',
                    value: _gender,
                    items: _genders,
                    onChanged: (v) => setState(() => _gender = v),
                    icon: Icons.wc_outlined,
                    cs: cs,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            _buildSectionHeader('Contact Information', Icons.phone, cs),
            _buildTextField(
              controller: _phoneController,
              label: 'Phone Number',
              icon: Icons.phone_android,
              keyboardType: TextInputType.phone,
              cs: cs,
              validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
            ),
            _buildTextField(
              controller: _emailController,
              label: 'Email',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              cs: cs,
            ),
            _buildTextField(
              controller: _addressController,
              label: 'Address',
              icon: Icons.location_on_outlined,
              maxLines: 3,
              cs: cs,
            ),

            const SizedBox(height: 24),
            _buildSectionHeader('Parent Details', Icons.family_restroom, cs),
            _buildTextField(
              controller: _parentNameController,
              label: 'Parent Name',
              icon: Icons.person_outline,
              cs: cs,
              validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
            ),
            _buildTextField(
              controller: _parentPhoneController,
              label: 'Parent Phone',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              cs: cs,
              validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
            ),
            _buildTextField(
              controller: _parentEmailController,
              label: 'Parent Email',
              icon: Icons.alternate_email,
              keyboardType: TextInputType.emailAddress,
              cs: cs,
            ),
            _buildDropdown(
              label: 'Relationship',
              value: _parentRelationship,
              items: _relationships,
              onChanged: (v) => setState(() => _parentRelationship = v!),
              icon: Icons.diversity_3_outlined,
              cs: cs,
            ),

            const SizedBox(height: 24),
            _buildSectionHeader(
              'Residential Information',
              Icons.home_outlined,
              cs,
            ),
            _buildResidentialTypeSelector(cs),
            if (_residentialType == 'Hosteler') ...[
              const SizedBox(height: 16),
              _buildTextField(
                controller: _hostelNameController,
                label: 'Hostel Name',
                icon: Icons.apartment_outlined,
                cs: cs,
              ),
              _buildTextField(
                controller: _roomNumberController,
                label: 'Room Number',
                icon: Icons.meeting_room_outlined,
                cs: cs,
              ),
            ],

            const SizedBox(height: 24),
            _buildSectionHeader(
              'Emergency Contact',
              Icons.emergency_outlined,
              cs,
            ),
            _buildTextField(
              controller: _emergencyContactNameController,
              label: 'Emergency Contact Name',
              icon: Icons.contact_phone_outlined,
              cs: cs,
            ),
            _buildTextField(
              controller: _emergencyContactPhoneController,
              label: 'Emergency Contact Phone',
              icon: Icons.phone_callback_outlined,
              keyboardType: TextInputType.phone,
              cs: cs,
            ),
            _buildTextField(
              controller: _medicalConditionsController,
              label: 'Medical Conditions (if any)',
              icon: Icons.medical_information_outlined,
              maxLines: 2,
              cs: cs,
            ),

            const SizedBox(height: 32),

            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitForm,
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text(
                  'Add Student',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: cs.primary, size: 24),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required ColorScheme cs,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        style: TextStyle(color: cs.onSurface),
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: cs.primary),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    required IconData icon,
    required ColorScheme cs,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value,
        dropdownColor: cs.surface,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: cs.primary),
        ),
        style: TextStyle(color: cs.onSurface),
        items: items.map((item) {
          return DropdownMenuItem(value: item, child: Text(item));
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildResidentialTypeSelector(ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.onSurface.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: RadioListTile<String>(
              title: const Text('Day Scholar', style: TextStyle(fontSize: 14)),
              value: 'Day Scholar',
              groupValue: _residentialType,
              onChanged: (v) => setState(() => _residentialType = v!),
              activeColor: cs.primary,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          Expanded(
            child: RadioListTile<String>(
              title: const Text('Hosteler', style: TextStyle(fontSize: 14)),
              value: 'Hosteler',
              groupValue: _residentialType,
              onChanged: (v) => setState(() => _residentialType = v!),
              activeColor: cs.primary,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}
