// File: lib/screens/principal/principal_add_hod_screen.dart
// Principal interface to register HODs for specific departments

import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class PrincipalAddHODScreen extends StatefulWidget {
  const PrincipalAddHODScreen({super.key});

  @override
  State<PrincipalAddHODScreen> createState() => _PrincipalAddHODScreenState();
}

class _PrincipalAddHODScreenState extends State<PrincipalAddHODScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _empIdCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  List<Map<String, dynamic>> _departments = [];
  int? _selectedDeptId;
  bool _isLoading = false;
  bool _loadingDepts = true;

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _empIdCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDepartments() async {
    try {
      final data = await ApiService.getPrincipalDepartments();
      if (mounted) {
        setState(() {
          // Only show departments that have no HOD assigned yet
          _departments = List<Map<String, dynamic>>.from(
            data,
          ).where((d) => d['hod'] == null).toList();
          _loadingDepts = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingDepts = false);
    }
  }

  Future<void> _handleSubmit() async {
    final cs = Theme.of(context).colorScheme;
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDeptId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a department'),
          backgroundColor: Color(0xFFFF9800), // Warning Orange
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ApiService.createHOD(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        departmentId: _selectedDeptId!,
        employeeId: _empIdCtrl.text.trim().isEmpty
            ? null
            : _empIdCtrl.text.trim(),
        phoneNumber: _phoneCtrl.text.trim().isEmpty
            ? null
            : _phoneCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('HOD created! Generate QR to complete onboarding.'),
            backgroundColor: Color(0xFF4CAF50), // Success Green
          ),
        );
        Navigator.pop(context, true);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: cs.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Register HOD')),
      body: _loadingDepts
          ? Center(child: CircularProgressIndicator(color: cs.primary))
          : _departments.isEmpty
          ? _buildAllAssignedState(cs)
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  // Info Banner
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cs.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cs.primary.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: cs.primary, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Once registered, the HOD must scan a secure QR code to finalize their account setup.',
                            style: TextStyle(
                              color: cs.primary,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  TextFormField(
                    controller: _nameCtrl,
                    style: TextStyle(color: cs.onSurface),
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(color: cs.onSurface),
                    decoration: const InputDecoration(
                      labelText: 'Official Email',
                      prefixIcon: Icon(Icons.alternate_email),
                    ),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _empIdCtrl,
                    style: TextStyle(color: cs.onSurface),
                    decoration: const InputDecoration(
                      labelText: 'Employee ID',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(color: cs.onSurface),
                    decoration: const InputDecoration(
                      labelText: 'Phone Number (Optional)',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 20),

                  DropdownButtonFormField<int>(
                    value: _selectedDeptId,
                    dropdownColor: cs.surface,
                    style: TextStyle(color: cs.onSurface, fontSize: 15),
                    decoration: const InputDecoration(
                      labelText: 'Assign Department',
                      prefixIcon: Icon(Icons.business_outlined),
                    ),
                    items: _departments
                        .map(
                          (d) => DropdownMenuItem<int>(
                            value: d['id'] as int,
                            child: Text('${d['code']} — ${d['name']}'),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedDeptId = v),
                    validator: (v) => v == null ? 'Select a department' : null,
                  ),
                  const SizedBox(height: 40),

                  SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _handleSubmit,
                      icon: _isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: cs.onPrimary,
                              ),
                            )
                          : const Icon(Icons.how_to_reg_outlined),
                      label: Text(
                        _isLoading ? 'Processing...' : 'Create HOD Account',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildAllAssignedState(ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.verified_user_outlined,
              size: 80,
              color: cs.primary.withOpacity(0.2),
            ),
            const SizedBox(height: 24),
            const Text(
              'Assignments Complete',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'All existing departments currently have HODs assigned. To reassign, manage existing HODs first.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: cs.onSurface.withOpacity(0.6),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}
