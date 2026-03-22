// File: lib/screens/principal/principal_initial_setup_screen.dart
// First-time wizard for Principal: Password setup, Email update, and Batch Department registration

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../../core/session.dart';

class PrincipalInitialSetupScreen extends StatefulWidget {
  final int? userId;
  const PrincipalInitialSetupScreen({super.key, this.userId});

  @override
  State<PrincipalInitialSetupScreen> createState() =>
      _PrincipalInitialSetupScreenState();
}

class _PrincipalInitialSetupScreenState
    extends State<PrincipalInitialSetupScreen> {
  final PageController _pageCtrl = PageController();
  int _currentPage = 0;

  // Step 1 & 2: Account Security
  final _emailCtrl = TextEditingController();
  final _passFormKey = GlobalKey<FormState>();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _isChangingEmail = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _passLoading = false;

  // Step 3: Batch Departments
  final _deptNameCtrl = TextEditingController();
  final _deptCodeCtrl = TextEditingController();
  final List<Map<String, String>> _departments = [];
  bool _deptLoading = false;

  @override
  void dispose() {
    _pageCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    _emailCtrl.dispose();
    _deptNameCtrl.dispose();
    _deptCodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleChangePassword() async {
    if (!_passFormKey.currentState!.validate()) return;
    setState(() => _passLoading = true);
    try {
      await ApiService.setPrincipalInitialPassword(
        newPassword: _newPassCtrl.text,
      );
      if (mounted) {
        _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        setState(() => _currentPage = 1);
      }
    } on ApiException catch (e) {
      if (mounted) _showSnack(e.message, isError: true);
    } finally {
      if (mounted) setState(() => _passLoading = false);
    }
  }

  Future<void> _submitEmail() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showSnack('Enter a valid official email', isError: true);
      return;
    }
    setState(() => _isChangingEmail = true);
    try {
      await ApiService.changePrincipalEmail(
        newEmail: email,
        password: _newPassCtrl.text.isNotEmpty
            ? _newPassCtrl.text
            : 'principal@123',
      );
      if (mounted) {
        _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        setState(() => _currentPage = 2);
      }
    } on ApiException catch (e) {
      if (mounted) _showSnack(e.message, isError: true);
    } finally {
      if (mounted) setState(() => _isChangingEmail = false);
    }
  }

  void _addDepartment() {
    final name = _deptNameCtrl.text.trim();
    final code = _deptCodeCtrl.text.trim().toUpperCase();
    if (name.isEmpty || code.isEmpty) {
      _showSnack('Fill both fields', isError: true);
      return;
    }
    if (_departments.any((d) => d['code'] == code)) {
      _showSnack('Code already exists', isError: true);
      return;
    }
    setState(() {
      _departments.add({'name': name, 'code': code});
      _deptNameCtrl.clear();
      _deptCodeCtrl.clear();
    });
  }

  Future<void> _handleFinish() async {
    if (_departments.isEmpty) {
      _showSnack('Register at least one department', isError: true);
      return;
    }
    setState(() => _deptLoading = true);
    try {
      await ApiService.createDepartmentsBatch(
        _departments
            .map((d) => {'name': d['name']!, 'code': d['code']!})
            .toList(),
      );
      final prefs = await SharedPreferences.getInstance();
      final uid = widget.userId ?? SessionManager.userId;
      await prefs.setBool('principal_setup_done_$uid', true);

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/principalDashboard');
      }
    } on ApiException catch (e) {
      if (mounted) _showSnack(e.message, isError: true);
    } finally {
      if (mounted) setState(() => _deptLoading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? cs.error : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(cs),
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildPasswordPage(cs),
                  _buildEmailPage(cs),
                  _buildDepartmentsPage(cs),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined, color: cs.primary, size: 28),
              const SizedBox(width: 12),
              const Text(
                'Institution Setup',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                'Step ${_currentPage + 1} of 3',
                style: TextStyle(
                  color: cs.onSurface.withOpacity(0.5),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: List.generate(3, (i) {
              final active = i <= _currentPage;
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 4,
                  decoration: BoxDecoration(
                    color: active ? cs.primary : cs.onSurface.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordPage(ColorScheme cs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _passFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Secure Your Account',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Update your default password to continue.',
              style: TextStyle(color: cs.onSurface.withOpacity(0.6)),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _newPassCtrl,
              obscureText: _obscureNew,
              decoration: InputDecoration(
                labelText: 'New Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureNew
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                ),
              ),
              validator: (v) =>
                  (v == null || v.length < 6) ? 'Min 6 characters' : null,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _confirmPassCtrl,
              obscureText: _obscureConfirm,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: const Icon(Icons.lock_reset),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              validator: (v) =>
                  v != _newPassCtrl.text ? 'Passwords do not match' : null,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _passLoading ? null : _handleChangePassword,
                child: _passLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Save & Continue',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailPage(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Primary Contact',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Verify your official institutional email.',
            style: TextStyle(color: cs.onSurface.withOpacity(0.6)),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Institutional Email',
              prefixIcon: Icon(Icons.alternate_email),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isChangingEmail ? null : _submitEmail,
              child: _isChangingEmail
                  ? const CircularProgressIndicator()
                  : const Text('Next Step'),
            ),
          ),
          Center(
            child: TextButton(
              onPressed: () => setState(() => _currentPage = 2),
              child: Text(
                'Skip',
                style: TextStyle(color: cs.onSurface.withOpacity(0.4)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentsPage(ColorScheme cs) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Initialize Departments',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add the foundational departments of your college.',
                  style: TextStyle(color: cs.onSurface.withOpacity(0.6)),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _deptNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Name (e.g. Mechanical)',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _deptCodeCtrl,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(labelText: 'Code'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _addDepartment,
                      icon: const Icon(Icons.add),
                      style: IconButton.styleFrom(backgroundColor: cs.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                if (_departments.isNotEmpty) ...[
                  Text(
                    'REGISTRATION LIST',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: cs.primary,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._departments.map((d) => _buildDeptTile(d, cs)),
                ],
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _deptLoading ? null : _handleFinish,
              child: _deptLoading
                  ? const CircularProgressIndicator()
                  : const Text('Finalize All Setup'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeptTile(Map<String, String> d, ColorScheme cs) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.onSurface.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: cs.primaryContainer,
            child: Text(
              d['code']!,
              style: TextStyle(
                color: cs.onPrimaryContainer,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              d['name']!,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _departments.remove(d)),
            icon: Icon(Icons.remove_circle_outline, color: cs.error, size: 20),
          ),
        ],
      ),
    );
  }
}
