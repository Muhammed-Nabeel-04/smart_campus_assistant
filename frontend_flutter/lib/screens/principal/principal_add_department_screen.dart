// lib/screens/principal/principal_add_department_screen.dart
import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../services/api_service.dart';

class PrincipalAddDepartmentScreen extends StatefulWidget {
  const PrincipalAddDepartmentScreen({super.key});

  @override
  State<PrincipalAddDepartmentScreen> createState() =>
      _PrincipalAddDepartmentScreenState();
}

class _PrincipalAddDepartmentScreenState
    extends State<PrincipalAddDepartmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ApiService.createDepartment(
        name: _nameCtrl.text.trim(),
        code: _codeCtrl.text.trim().toUpperCase(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Department added successfully'),
            backgroundColor: AppColors.success));
        Navigator.pop(context, true);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.message), backgroundColor: AppColors.danger));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(title: const Text('Add Department')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF6A1B9A).withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFF6A1B9A).withOpacity(0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline,
                      color: Color(0xFF6A1B9A), size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Department code is used across the system (e.g. CSE, ECE). Keep it short and uppercase.',
                      style: TextStyle(
                          color: Color(0xFF6A1B9A), fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            TextFormField(
              controller: _nameCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Department Name',
                hintText: 'e.g. Computer Science Engineering',
                prefixIcon: Icon(Icons.account_tree),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _codeCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Department Code',
                hintText: 'e.g. CSE',
                prefixIcon: Icon(Icons.code),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (v.trim().length < 2) return 'Min 2 characters';
                return null;
              },
            ),
            const SizedBox(height: 32),

            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6A1B9A)),
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_circle_outline),
                label: Text(
                  _isLoading ? 'Adding...' : 'Add Department',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
