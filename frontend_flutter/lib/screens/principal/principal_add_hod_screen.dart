// lib/screens/principal/principal_add_hod_screen.dart
import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
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
      final data = await ApiService.getAllDepartments();
      if (mounted) {
        setState(() {
          _departments = List<Map<String, dynamic>>.from(data);
          _loadingDepts = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingDepts = false);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDeptId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a department'),
          backgroundColor: AppColors.warning,
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
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(title: const Text('Add New HOD')),
      body: _loadingDepts
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Info banner
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.info.withOpacity(0.2),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.info,
                          size: 18,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'After creating, generate a QR code so the HOD can set their password.',
                            style: TextStyle(
                              color: AppColors.info,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _nameCtrl,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _empIdCtrl,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Employee ID',
                      prefixIcon: Icon(Icons.badge),
                    ),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Phone (Optional)',
                      prefixIcon: Icon(Icons.phone),
                    ),
                  ),
                  const SizedBox(height: 14),

                  DropdownButtonFormField<int>(
                    value: _selectedDeptId,
                    decoration: const InputDecoration(
                      labelText: 'Assign Department',
                      prefixIcon: Icon(Icons.account_tree),
                    ),
                    items: _departments
                        .map(
                          (d) => DropdownMenuItem<int>(
                            value: d['id'] as int,
                            child: Text(
                              '${d['code']} · ${d['name']}',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedDeptId = v),
                    validator: (v) => v == null ? 'Select a department' : null,
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                      ),
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_circle_outline),
                      label: Text(
                        _isLoading ? 'Creating...' : 'Create HOD',
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
}
