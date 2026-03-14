import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../core/app_colors.dart';

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
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(
        const Duration(days: 6570),
      ), // ~18 years
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF1565C0),
              surface: AppColors.bgCard,
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
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: AppColors.danger,
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
        'department': widget.department['id'].toString(),
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
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgCard,
        elevation: 0,
        title: const Text('Add New Student'),
        actions: [
          if (_isSubmitting)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Color(0xFF1565C0),
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
            // Personal Information Section
            _buildSectionHeader('Personal Information', Icons.person),
            _buildTextField(
              controller: _fullNameController,
              label: 'Full Name',
              icon: Icons.person_outline,
              validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
            ),
            _buildTextField(
              controller: _registerNumberController,
              label: 'Register Number',
              icon: Icons.badge,
              validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
            ),

            // Date of Birth
            InkWell(
              onTap: _selectDate,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Date of Birth',
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  prefixIcon: const Icon(
                    Icons.calendar_today,
                    color: Color(0xFF1565C0),
                  ),
                  filled: true,
                  fillColor: AppColors.bgCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                child: Text(
                  _dateOfBirth != null
                      ? '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}'
                      : 'Select date',
                  style: TextStyle(
                    color: _dateOfBirth != null
                        ? AppColors.textPrimary
                        : AppColors.textHint,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Blood Group & Gender
            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    label: 'Blood Group',
                    value: _bloodGroup,
                    items: _bloodGroups,
                    onChanged: (v) => setState(() => _bloodGroup = v),
                    icon: Icons.bloodtype,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDropdown(
                    label: 'Gender',
                    value: _gender,
                    items: _genders,
                    onChanged: (v) => setState(() => _gender = v),
                    icon: Icons.wc,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Contact Information Section
            _buildSectionHeader('Contact Information', Icons.phone),
            _buildTextField(
              controller: _phoneController,
              label: 'Phone Number',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
              validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
            ),
            _buildTextField(
              controller: _emailController,
              label: 'Email',
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
            ),
            _buildTextField(
              controller: _addressController,
              label: 'Address',
              icon: Icons.location_on,
              maxLines: 3,
            ),

            const SizedBox(height: 24),

            // Parent Details Section
            _buildSectionHeader('Parent Details', Icons.family_restroom),
            _buildTextField(
              controller: _parentNameController,
              label: 'Parent Name',
              icon: Icons.person,
              validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
            ),
            _buildTextField(
              controller: _parentPhoneController,
              label: 'Parent Phone',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
              validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
            ),
            _buildTextField(
              controller: _parentEmailController,
              label: 'Parent Email',
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
            ),
            _buildDropdown(
              label: 'Relationship',
              value: _parentRelationship,
              items: _relationships,
              onChanged: (v) => setState(() => _parentRelationship = v!),
              icon: Icons.diversity_3,
            ),

            const SizedBox(height: 24),

            // Residential Information Section
            _buildSectionHeader('Residential Information', Icons.home),
            _buildResidentialTypeSelector(),
            if (_residentialType == 'Hosteler') ...[
              const SizedBox(height: 16),
              _buildTextField(
                controller: _hostelNameController,
                label: 'Hostel Name',
                icon: Icons.apartment,
              ),
              _buildTextField(
                controller: _roomNumberController,
                label: 'Room Number',
                icon: Icons.meeting_room,
              ),
            ],

            const SizedBox(height: 24),

            // Emergency Contact Section
            _buildSectionHeader('Emergency Contact', Icons.local_hospital),
            _buildTextField(
              controller: _emergencyContactNameController,
              label: 'Emergency Contact Name',
              icon: Icons.person,
            ),
            _buildTextField(
              controller: _emergencyContactPhoneController,
              label: 'Emergency Contact Phone',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
            ),
            _buildTextField(
              controller: _medicalConditionsController,
              label: 'Medical Conditions (if any)',
              icon: Icons.medical_information,
              maxLines: 2,
            ),

            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitForm,
                icon: const Icon(Icons.person_add),
                label: const Text(
                  'Add Student',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
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

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1565C0), size: 24),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
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
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: AppColors.textPrimary),
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.textSecondary),
          prefixIcon: Icon(icon, color: const Color(0xFF1565C0)),
          filled: true,
          fillColor: AppColors.bgCard,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.bgSeparator),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1565C0), width: 2),
          ),
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
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value,
        dropdownColor: AppColors.bgCard,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.textSecondary),
          prefixIcon: Icon(icon, color: const Color(0xFF1565C0)),
          filled: true,
          fillColor: AppColors.bgCard,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.bgSeparator),
          ),
        ),
        style: const TextStyle(color: AppColors.textPrimary),
        items: items.map((item) {
          return DropdownMenuItem(value: item, child: Text(item));
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildResidentialTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: RadioListTile<String>(
            title: const Text(
              'Day Scholar',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            value: 'Day Scholar',
            groupValue: _residentialType,
            onChanged: (v) => setState(() => _residentialType = v!),
            activeColor: const Color(0xFF1565C0),
            tileColor: AppColors.bgCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RadioListTile<String>(
            title: const Text(
              'Hosteler',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            value: 'Hosteler',
            groupValue: _residentialType,
            onChanged: (v) => setState(() => _residentialType = v!),
            activeColor: const Color(0xFF1565C0),
            tileColor: AppColors.bgCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}
