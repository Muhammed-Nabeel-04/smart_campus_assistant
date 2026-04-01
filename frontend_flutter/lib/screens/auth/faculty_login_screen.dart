// File: lib/screens/faculty/faculty_login_screen.dart
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../core/session.dart';

class FacultyLoginScreen extends StatefulWidget {
  const FacultyLoginScreen({super.key});

  @override
  State<FacultyLoginScreen> createState() => _FacultyLoginScreenState();
}

class _FacultyLoginScreenState extends State<FacultyLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final role = response['role'] as String? ?? '';

      if (role != 'faculty' && role != 'admin') {
        throw Exception('Invalid credentials. Faculty / HOD access only.');
      }

      await SessionManager.saveSession(
        userId: response['user_id'],
        name: response['name'],
        email: response['email'],
        role: role,
        token: response['token'],
        facultyId: response['faculty_id'],
        department: response['department'],
      );

      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          role == 'admin' ? '/adminDashboard' : '/facultyDashboard',
        );
      }
    } on ApiException catch (e) {
      if (mounted) _showError(e.message);
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: cs.error));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── Logo (Floating Emblem with Soft Glow) ─────────────
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color:
                              cs.primary.withOpacity(0.25), // Soft ambient glow
                          blurRadius:
                              50, // Wide blur so it doesn't look like a solid shape
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/college_logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(height: 32),

                  Text(
                    'Faculty / HOD Portal',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: cs.primary,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Sign in to manage your classes',
                    style: TextStyle(
                      fontSize: 16,
                      color: cs.onBackground.withOpacity(0.6),
                    ),
                  ),

                  const SizedBox(height: 48),

                  // ── Email ─────────────────────────────────────
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty)
                        return 'Please enter your email';
                      if (!v.contains('@')) return 'Please enter a valid email';
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // ── Password ──────────────────────────────────
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty)
                        return 'Please enter your password';
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // ── Login Button ──────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      child: _isLoading
                          ? SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: cs.onTertiary,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── OR Divider ────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: Divider(color: cs.onBackground.withOpacity(0.2)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR',
                          style: TextStyle(
                            color: cs.onBackground.withOpacity(0.5),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(color: cs.onBackground.withOpacity(0.2)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── First Time Setup (Faculty) ─────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/facultyQrOnboarding'),
                      icon: const Icon(Icons.qr_code_scanner, size: 24),
                      label: const Text(
                        'First Time Setup (Faculty)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── First Time Setup (HOD) ────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/hodQROnboarding'),
                      icon: const Icon(Icons.qr_code_scanner, size: 24),
                      label: const Text(
                        'First Time Setup (HOD)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Info Note ─────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: cs.primary.withOpacity(0.25)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: cs.primary, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'New faculty or HOD? Get your setup QR from admin.',
                            style: TextStyle(color: cs.primary, fontSize: 12),
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
      ),
    );
  }
}
