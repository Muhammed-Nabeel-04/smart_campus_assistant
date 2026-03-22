// File: lib/screens/faculty/faculty_password_setup_screen.dart
// Faculty creates password after scanning onboarding QR

import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../core/session.dart';

class FacultyPasswordSetupScreen extends StatefulWidget {
  final Map<String, dynamic> facultyData;

  const FacultyPasswordSetupScreen({super.key, required this.facultyData});

  @override
  State<FacultyPasswordSetupScreen> createState() =>
      _FacultyPasswordSetupScreenState();
}

class _FacultyPasswordSetupScreenState
    extends State<FacultyPasswordSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSetup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.setFacultyPassword(
        facultyId: widget.facultyData['faculty_id'],
        password: _passwordController.text,
        token: widget.facultyData['token'],
      );

      await SessionManager.saveSession(
        userId: response['user_id'],
        name: response['full_name'],
        email: response['email'],
        role: 'faculty',
        token: response['token'],
        facultyId: response['faculty_id'],
        department: response['department'],
      );

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/facultyDashboard');
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
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cs.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: cs.primary.withOpacity(0.3),
                          blurRadius: 30,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.lock_reset,
                      size: 60,
                      color: cs.onPrimary,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                Text(
                  'Welcome, Faculty!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Set up your password to continue',
                  style: TextStyle(
                    fontSize: 16,
                    color: cs.onSurface.withOpacity(0.7),
                  ),
                ),

                const SizedBox(height: 40),

                // Faculty info card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cs.primary.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(
                        Icons.person,
                        'Name',
                        widget.facultyData['full_name'] ??
                            widget.facultyData['name'] ??
                            'N/A',
                        cs,
                      ),
                      Divider(height: 24, color: cs.onSurface.withOpacity(0.1)),
                      _buildInfoRow(
                        Icons.badge,
                        'Faculty ID',
                        widget.facultyData['faculty_id']?.toString() ?? 'N/A',
                        cs,
                      ),
                      Divider(height: 24, color: cs.onSurface.withOpacity(0.1)),
                      _buildInfoRow(
                        Icons.school,
                        'Department',
                        widget.facultyData['department'] ?? 'N/A',
                        cs,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Password field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: TextStyle(color: cs.onSurface),
                  decoration: InputDecoration(
                    labelText: 'Create Password',
                    prefixIcon: Icon(Icons.lock_outline, color: cs.primary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: cs.primary,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Confirm password field
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  style: TextStyle(color: cs.onSurface),
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: Icon(Icons.lock_outline, color: cs.primary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: cs.primary,
                      ),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSetup,
                    child: _isLoading
                        ? SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: cs.onPrimary,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Complete Setup',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFF2196F3,
                    ).withOpacity(0.1), // Info color
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF2196F3).withOpacity(0.3),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Color(0xFF2196F3),
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Remember this password. You\'ll use it to login.',
                          style: TextStyle(
                            color: Color(0xFF2196F3),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    ColorScheme cs,
  ) {
    return Row(
      children: [
        Icon(icon, color: cs.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: cs.onSurface.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
