// File: lib/screens/principal/principal_add_department_screen.dart
// Principal interface to create new academic departments within the system

import 'package:flutter/material.dart';
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Department added successfully'),
            backgroundColor: Color(0xFF4CAF50), // Success Green
          ),
        );
        Navigator.pop(context, true);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
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
      appBar: AppBar(title: const Text('Add Department')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Info Banner using Primary color context
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
                      'The department code (e.g., CSE, AIDS) will be used to link subjects, faculty, and students across the platform.',
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
                labelText: 'Full Department Name',
                hintText: 'e.g. Artificial Intelligence & Data Science',
                prefixIcon: Icon(Icons.account_tree_outlined),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),

            const SizedBox(height: 20),

            TextFormField(
              controller: _codeCtrl,
              style: TextStyle(color: cs.onSurface),
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Short Code',
                hintText: 'e.g. AIDS',
                prefixIcon: Icon(Icons.qr_code_outlined),
                counterStyle: TextStyle(fontSize: 10),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (v.trim().length < 2) return 'Min 2 characters';
                return null;
              },
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
                    : const Icon(Icons.add_business_outlined),
                label: Text(
                  _isLoading ? 'Processing...' : 'Register Department',
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
