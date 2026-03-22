// File: lib/screens/principal/principal_login_screen.dart
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../core/session.dart';

class PrincipalLoginScreen extends StatefulWidget {
  const PrincipalLoginScreen({super.key});

  @override
  State<PrincipalLoginScreen> createState() => _PrincipalLoginScreenState();
}

class _PrincipalLoginScreenState extends State<PrincipalLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  // Principal role color
  static const Color _principalColor = Color(0xFF9C27B0);

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

      if (response['role'] != 'principal') {
        throw Exception('Invalid credentials. Principal access only.');
      }

      await SessionManager.saveSession(
        userId: response['user_id'],
        name: response['name'],
        email: response['email'],
        role: 'principal',
        token: response['token'],
      );

      if (mounted) {
        final uid = response['user_id'] as int;

        bool setupDone = false;
        try {
          final status = await ApiService.checkPrincipalSetupStatus();
          setupDone = status['departments_added'] == true;
        } catch (_) {}

        if (!mounted) return;

        if (setupDone) {
          Navigator.pushReplacementNamed(context, '/principalDashboard');
        } else {
          Navigator.pushReplacementNamed(
            context,
            '/principalInitialSetup',
            arguments: {'userId': uid},
          );
        }
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
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
                  // ── Logo ─────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _principalColor,
                          _principalColor.withOpacity(0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _principalColor.withOpacity(0.4),
                          blurRadius: 30,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      size: 64,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Title ─────────────────────────────────────
                  Text(
                    'Principal Portal',
                    style: TextStyle(
                      color: cs.onBackground,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'College Administration',
                    style: TextStyle(
                      color: cs.onBackground.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 48),

                  // ── Email ─────────────────────────────────────
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Principal Email',
                      hintText: 'principal@college.edu',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Email is required';
                      if (!v.contains('@')) return 'Enter a valid email';
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
                      if (v == null || v.isEmpty) return 'Password is required';
                      return null;
                    },
                  ),

                  const SizedBox(height: 32),

                  // ── Login Button ──────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _principalColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Login as Principal',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Back Button ───────────────────────────────
                  TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back,
                      color: cs.onBackground.withOpacity(0.5),
                    ),
                    label: Text(
                      'Back to Role Selection',
                      style: TextStyle(color: cs.onBackground.withOpacity(0.5)),
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
