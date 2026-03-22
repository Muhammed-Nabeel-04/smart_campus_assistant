// File: lib/screens/admin/hod_password_setup_screen.dart
// HOD first-time setup: Create password after secure QR onboarding

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../../core/session.dart';

class HODPasswordSetupScreen extends StatefulWidget {
  final Map<String, dynamic> hodData;
  const HODPasswordSetupScreen({super.key, required this.hodData});

  @override
  State<HODPasswordSetupScreen> createState() => _HODPasswordSetupScreenState();
}

class _HODPasswordSetupScreenState extends State<HODPasswordSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSetup() async {
    final cs = Theme.of(context).colorScheme;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.setHODPassword(
        hodId: widget.hodData['hod_id'],
        password: _passwordCtrl.text,
        token: widget.hodData['token'],
      );

      await SessionManager.saveSession(
        userId: response['user_id'],
        name: response['name'],
        email: response['email'],
        role: 'admin',
        token: response['token'],
        adminId: response['user_id'],
      );

      if (mounted) {
        // Mark setup complete locally so login skips wizard next time
        final prefs = await SharedPreferences.getInstance();
        final uid = response['user_id'] as int;
        await prefs.setBool('hod_setup_done_$uid', true);

        Navigator.pushReplacementNamed(context, '/adminDashboard');
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
                      Icons.admin_panel_settings_outlined,
                      size: 60,
                      color: cs.onPrimary,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                Text(
                  'Welcome, HOD!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Complete your secure account setup',
                  style: TextStyle(
                    fontSize: 16,
                    color: cs.onSurface.withOpacity(0.7),
                  ),
                ),

                const SizedBox(height: 32),

                // HOD info card
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
                      _infoRow(
                        Icons.person_outline,
                        'Name',
                        widget.hodData['name'] ?? 'N/A',
                        cs,
                      ),
                      Divider(
                        height: 24,
                        color: cs.onSurface.withOpacity(0.05),
                      ),
                      _infoRow(
                        Icons.alternate_email,
                        'Email',
                        widget.hodData['email'] ?? 'N/A',
                        cs,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Password
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscurePass,
                  style: TextStyle(color: cs.onSurface),
                  decoration: InputDecoration(
                    labelText: 'Create Password',
                    prefixIcon: Icon(Icons.lock_outline, color: cs.primary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePass
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: cs.primary,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePass = !_obscurePass),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (v.length < 6) return 'Min 6 characters';
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Confirm password
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: _obscureConfirm,
                  style: TextStyle(color: cs.onSurface),
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: Icon(Icons.lock_reset, color: cs.primary),
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
                  validator: (v) {
                    if (v != _passwordCtrl.text)
                      return 'Passwords do not match';
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
                            'Finalize Setup',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, ColorScheme cs) {
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
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
