// lib/screens/principal/principal_initial_setup_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_colors.dart';
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

  // Step 1 — Change password
  // Step 2 — Change email
  final _emailCtrl = TextEditingController();
  bool _isChangingEmail = false;
  final _passFormKey = GlobalKey<FormState>();
  final _currentPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _passLoading = false;

  // Step 2 — Add departments
  final _deptNameCtrl = TextEditingController();
  final _deptCodeCtrl = TextEditingController();
  final List<Map<String, String>> _departments = [];
  bool _deptLoading = false;

  @override
  void dispose() {
    _pageCtrl.dispose();
    _currentPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
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
      if (mounted) _showSnack(e.message, AppColors.danger);
    } finally {
      if (mounted) setState(() => _passLoading = false);
    }
  }

  void _addDepartment() {
    final name = _deptNameCtrl.text.trim();
    final code = _deptCodeCtrl.text.trim().toUpperCase();
    if (name.isEmpty || code.isEmpty) {
      _showSnack('Enter department name and code', AppColors.warning);
      return;
    }
    if (_departments.any((d) => d['code'] == code)) {
      _showSnack('Department code already added', AppColors.warning);
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
      _showSnack('Add at least one department', AppColors.warning);
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
      if (mounted) _showSnack(e.message, AppColors.danger);
    } finally {
      if (mounted) setState(() => _deptLoading = false);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.account_balance_rounded,
                        color: Color(0xFF6A1B9A),
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Principal Setup',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Step ${_currentPage + 1}/3',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: List.generate(2, (i) {
                      final done = i < _currentPage;
                      final active = i == _currentPage;
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 4,
                          decoration: BoxDecoration(
                            color: done || active
                                ? const Color(0xFF6A1B9A)
                                : AppColors.bgSeparator,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildChangePasswordPage(),
                  _buildChangeEmailPage(),
                  _buildAddDepartmentsPage(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChangeEmailPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Update Email',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Change your default email to your official email address.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              labelText: 'New Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isChangingEmail ? null : _submitEmail,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: _isChangingEmail
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Save & Continue',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => _pageCtrl.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              ),
              child: const Text(
                'Skip for now',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitEmail() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showSnack('Enter a valid email', AppColors.warning);
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
        setState(() => _currentPage++);
      }
    } on ApiException catch (e) {
      if (mounted) _showSnack(e.message, AppColors.danger);
    } finally {
      if (mounted) setState(() => _isChangingEmail = false);
    }
  }

  Widget _buildChangePasswordPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _passFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Set New Password',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Change your default password to something secure.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 32),

            TextFormField(
              controller: _newPassCtrl,
              obscureText: _obscureNew,
              style: const TextStyle(color: AppColors.textPrimary),
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
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (v.length < 6) return 'Min 6 characters';
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _confirmPassCtrl,
              obscureText: _obscureConfirm,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: const Icon(Icons.lock_outline),
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
              validator: (v) {
                if (v != _newPassCtrl.text) return 'Passwords do not match';
                return null;
              },
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _passLoading ? null : _handleChangePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A1B9A),
                ),
                child: _passLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Save & Continue',
                        style: TextStyle(
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

  Widget _buildAddDepartmentsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add Departments',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add all departments in your institution. You can add more later.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 24),

          // Input row
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _deptNameCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Department Name',
                    hintText: 'Computer Science',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _deptCodeCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Code',
                    hintText: 'CSE',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: _addDepartment,
                icon: const Icon(
                  Icons.add_circle,
                  color: Color(0xFF6A1B9A),
                  size: 36,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Added departments
          if (_departments.isNotEmpty) ...[
            const Text(
              'ADDED DEPARTMENTS',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 12),
            ..._departments.map(
              (d) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF6A1B9A).withOpacity(0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6A1B9A).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        d['code']!,
                        style: const TextStyle(
                          color: Color(0xFF6A1B9A),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        d['name']!,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: AppColors.danger,
                        size: 18,
                      ),
                      onPressed: () => setState(() => _departments.remove(d)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _deptLoading ? null : _handleFinish,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A1B9A),
              ),
              child: _deptLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Complete Setup',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
