// File: lib/screens/faculty/faculty_edit_student_screen.dart
// Faculty form to edit all student profile details

import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class FacultyEditStudentScreen extends StatefulWidget {
  final Map<String, dynamic> studentData;
  final Map<String, dynamic> classData;

  const FacultyEditStudentScreen({
    super.key,
    required this.studentData,
    required this.classData,
  });

  @override
  State<FacultyEditStudentScreen> createState() =>
      _FacultyEditStudentScreenState();
}

class _FacultyEditStudentScreenState extends State<FacultyEditStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  bool loading = false;

  // Basic
  late TextEditingController nameCtrl;
  late TextEditingController emailCtrl;
  late TextEditingController phoneCtrl;
  late TextEditingController dobCtrl;
  late TextEditingController addressCtrl;

  // Dropdowns
  String? gender;
  String? bloodGroup;
  String? residentialType;

  // Parent
  late TextEditingController parentNameCtrl;
  late TextEditingController parentPhoneCtrl;
  late TextEditingController parentEmailCtrl;
  late TextEditingController parentRelCtrl;

  // Hostel
  late TextEditingController hostelCtrl;
  late TextEditingController roomCtrl;

  // Emergency
  late TextEditingController emergNameCtrl;
  late TextEditingController emergPhoneCtrl;
  late TextEditingController medicalCtrl;

  @override
  void initState() {
    super.initState();
    final s = widget.studentData;

    nameCtrl = TextEditingController(text: s['full_name'] ?? '');
    emailCtrl = TextEditingController(text: s['email'] ?? '');
    phoneCtrl = TextEditingController(
        text: s['phone'] ?? s['phone_number'] ?? '');
    dobCtrl = TextEditingController(text: s['date_of_birth'] ?? '');
    addressCtrl = TextEditingController(text: s['address'] ?? '');

    gender = s['gender'];
    bloodGroup = s['blood_group'];
    residentialType = s['residential_type'] ?? 'Day Scholar';

    parentNameCtrl = TextEditingController(text: s['parent_name'] ?? '');
    parentPhoneCtrl = TextEditingController(text: s['parent_phone'] ?? '');
    parentEmailCtrl = TextEditingController(text: s['parent_email'] ?? '');
    parentRelCtrl =
        TextEditingController(text: s['parent_relationship'] ?? '');

    hostelCtrl = TextEditingController(text: s['hostel_name'] ?? '');
    roomCtrl = TextEditingController(text: s['room_number'] ?? '');

    emergNameCtrl =
        TextEditingController(text: s['emergency_contact_name'] ?? '');
    emergPhoneCtrl =
        TextEditingController(text: s['emergency_contact_phone'] ?? '');
    medicalCtrl =
        TextEditingController(text: s['medical_conditions'] ?? '');
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    dobCtrl.dispose();
    addressCtrl.dispose();
    parentNameCtrl.dispose();
    parentPhoneCtrl.dispose();
    parentEmailCtrl.dispose();
    parentRelCtrl.dispose();
    hostelCtrl.dispose();
    roomCtrl.dispose();
    emergNameCtrl.dispose();
    emergPhoneCtrl.dispose();
    medicalCtrl.dispose();
    super.dispose();
  }

  Future<void> _updateStudent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      final data = <String, dynamic>{
        'full_name': nameCtrl.text.trim(),
        'email': emailCtrl.text.trim(),
        'phone_number': phoneCtrl.text.trim(),
        'date_of_birth': dobCtrl.text.trim(),
        'address': addressCtrl.text.trim(),
        'gender': gender ?? '',
        'blood_group': bloodGroup ?? '',
        'residential_type': residentialType ?? 'Day Scholar',
        'parent_name': parentNameCtrl.text.trim(),
        'parent_phone': parentPhoneCtrl.text.trim(),
        'parent_email': parentEmailCtrl.text.trim(),
        'parent_relationship': parentRelCtrl.text.trim(),
        'emergency_contact_name': emergNameCtrl.text.trim(),
        'emergency_contact_phone': emergPhoneCtrl.text.trim(),
        'medical_conditions': medicalCtrl.text.trim(),
      };

      // Only include hostel fields if not Day Scholar
      if (residentialType != 'Day Scholar') {
        data['hostel_name'] = hostelCtrl.text.trim();
        data['room_number'] = roomCtrl.text.trim();
      }

      await ApiService.updateStudent(widget.studentData['id'], data);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Student updated successfully'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Student')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Basic Information ─────────────────────────
              _sectionTitle('Basic Information', cs),
              const SizedBox(height: 12),

              _textField(nameCtrl, 'Full Name', Icons.person_outline,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Enter name' : null),
              _textField(emailCtrl, 'Email', Icons.email_outlined,
                  keyboard: TextInputType.emailAddress),
              _textField(phoneCtrl, 'Phone Number', Icons.phone_outlined,
                  keyboard: TextInputType.phone),
              _textField(dobCtrl, 'Date of Birth', Icons.cake_outlined,
                  hint: 'DD/MM/YYYY'),
              _textField(addressCtrl, 'Address', Icons.home_outlined,
                  maxLines: 2),

              const SizedBox(height: 8),

              // Gender dropdown
              DropdownButtonFormField<String>(
                value: gender,
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  prefixIcon: Icon(Icons.wc_outlined),
                ),
                style: TextStyle(color: cs.onSurface),
                dropdownColor: cs.surface,
                items: ['Male', 'Female', 'Other']
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (v) => setState(() => gender = v),
              ),
              const SizedBox(height: 14),

              // Blood group dropdown
              DropdownButtonFormField<String>(
                value: bloodGroup,
                decoration: const InputDecoration(
                  labelText: 'Blood Group',
                  prefixIcon: Icon(Icons.bloodtype_outlined),
                ),
                style: TextStyle(color: cs.onSurface),
                dropdownColor: cs.surface,
                items: ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-']
                    .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                    .toList(),
                onChanged: (v) => setState(() => bloodGroup = v),
              ),
              const SizedBox(height: 14),

              // Residential type dropdown
              DropdownButtonFormField<String>(
                value: residentialType,
                decoration: const InputDecoration(
                  labelText: 'Residential Type',
                  prefixIcon: Icon(Icons.house_outlined),
                ),
                style: TextStyle(color: cs.onSurface),
                dropdownColor: cs.surface,
                items: ['Day Scholar', 'Hosteller']
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) => setState(() => residentialType = v),
              ),

              // ── Hostel (only if Hosteller) ─────────────────
              if (residentialType != 'Day Scholar') ...[
                const SizedBox(height: 20),
                _sectionTitle('Hostel Details', cs),
                const SizedBox(height: 12),
                _textField(hostelCtrl, 'Hostel Name', Icons.apartment_outlined),
                _textField(roomCtrl, 'Room Number', Icons.meeting_room_outlined),
              ],

              // ── Parent Details ─────────────────────────────
              const SizedBox(height: 20),
              _sectionTitle('Parent / Guardian', cs),
              const SizedBox(height: 12),
              _textField(parentNameCtrl, 'Parent Name', Icons.person_outline),
              _textField(parentPhoneCtrl, 'Parent Phone', Icons.phone_outlined,
                  keyboard: TextInputType.phone),
              _textField(
                  parentEmailCtrl, 'Parent Email', Icons.email_outlined,
                  keyboard: TextInputType.emailAddress),
              _textField(parentRelCtrl, 'Relationship', Icons.family_restroom,
                  hint: 'Father, Mother, Guardian...'),

              // ── Emergency Contact ──────────────────────────
              const SizedBox(height: 20),
              _sectionTitle('Emergency Contact', cs),
              const SizedBox(height: 12),
              _textField(emergNameCtrl, 'Contact Name', Icons.emergency_outlined),
              _textField(
                  emergPhoneCtrl, 'Contact Phone', Icons.phone_outlined,
                  keyboard: TextInputType.phone),
              _textField(medicalCtrl, 'Medical Conditions', Icons.medical_services_outlined,
                  maxLines: 2, hint: 'Allergies, conditions, etc.'),

              // ── Save Button ────────────────────────────────
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: loading ? null : _updateStudent,
                  child: loading
                      ? SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: cs.onPrimary,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Update Student',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────

  Widget _sectionTitle(String title, ColorScheme cs) {
    return Text(
      title,
      style: TextStyle(
        color: cs.primary,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _textField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType? keyboard,
    String? hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: ctrl,
        style: TextStyle(color: cs.onSurface),
        keyboardType: keyboard,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
        ),
        validator: validator,
      ),
    );
  }
}
