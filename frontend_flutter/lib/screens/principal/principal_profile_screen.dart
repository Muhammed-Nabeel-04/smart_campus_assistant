// File: lib/screens/principal/principal_profile_screen.dart
// Principal's personal profile management: Account security and contact updates

import 'package:flutter/material.dart';
import '../../core/session.dart';
import '../../services/api_service.dart';

class PrincipalProfileScreen extends StatefulWidget {
  const PrincipalProfileScreen({super.key});

  @override
  State<PrincipalProfileScreen> createState() => _PrincipalProfileScreenState();
}

class _PrincipalProfileScreenState extends State<PrincipalProfileScreen> {
  final _passFormKey = GlobalKey<FormState>();
  final _currentPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isChangingPass = false;
  bool _isChangingEmail = false;

  @override
  void initState() {
    super.initState();
    _emailCtrl.text = SessionManager.email ?? '';
  }

  @override
  void dispose() {
    _currentPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleChangeEmail() async {
    final cs = Theme.of(context).colorScheme;
    final email = _emailCtrl.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      _showSnack('Please enter a valid official email', isError: true);
      return;
    }

    final passCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surface,
        title: const Text('Confirm Identity'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your current password to update email settings.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Verify'),
          ),
        ],
      ),
    );

    if (confirmed != true || passCtrl.text.isEmpty) return;

    setState(() => _isChangingEmail = true);
    try {
      await ApiService.changePrincipalEmail(
        newEmail: email,
        password: passCtrl.text,
      );
      await SessionManager.updateProfile(email: email);
      _showSnack('Institutional email updated successfully');
    } on ApiException catch (e) {
      _showSnack(e.message, isError: true);
    } finally {
      if (mounted) setState(() => _isChangingEmail = false);
    }
  }

  Future<void> _handleChangePassword() async {
    if (!_passFormKey.currentState!.validate()) return;
    setState(() => _isChangingPass = true);
    try {
      await ApiService.changePrincipalPassword(
        currentPassword: _currentPassCtrl.text,
        newPassword: _newPassCtrl.text,
      );
      if (mounted) {
        _currentPassCtrl.clear();
        _newPassCtrl.clear();
        _confirmPassCtrl.clear();
        _showSnack('Password successfully updated');
      }
    } on ApiException catch (e) {
      _showSnack(e.message, isError: true);
    } finally {
      if (mounted) setState(() => _isChangingPass = false);
    }
  }

  Future<void> _handleLogout() async {
    final cs = Theme.of(context).colorScheme;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surface,
        title: const Text('Logout'),
        content: const Text('Are you sure you want to end your session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: cs.error),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ApiService.logout();
      await SessionManager.clearSession();
      if (mounted)
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : const Color(0xFF4CAF50),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Administrator Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Elegant Header Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cs.primary,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 46,
                  backgroundColor: cs.onPrimary,
                  child: Text(
                    (SessionManager.displayName).substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      color: cs.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  SessionManager.displayName,
                  style: TextStyle(
                    color: cs.onPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Chief Administrator / Principal',
                  style: TextStyle(
                    color: cs.onPrimary.withOpacity(0.7),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Security Management Card
          _buildCard(
            title: 'Security Settings',
            icon: Icons.shield_outlined,
            cs: cs,
            child: Form(
              key: _passFormKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _currentPassCtrl,
                    obscureText: _obscureCurrent,
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureCurrent
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () =>
                            setState(() => _obscureCurrent = !_obscureCurrent),
                      ),
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _newPassCtrl,
                    obscureText: _obscureNew,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: const Icon(Icons.lock_open_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureNew
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () =>
                            setState(() => _obscureNew = !_obscureNew),
                      ),
                    ),
                    validator: (v) =>
                        (v == null || v.length < 6) ? 'Min 6 characters' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPassCtrl,
                    obscureText: _obscureConfirm,
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      prefixIcon: const Icon(Icons.lock_reset_outlined),
                    ),
                    validator: (v) => v != _newPassCtrl.text
                        ? 'Passwords do not match'
                        : null,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isChangingPass ? null : _handleChangePassword,
                      child: _isChangingPass
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Update Credentials'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Communication Card
          _buildCard(
            title: 'Contact Information',
            icon: Icons.alternate_email_outlined,
            cs: cs,
            child: Column(
              children: [
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Official Institutional Email',
                    hintText: 'principal@college.edu',
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: _isChangingEmail ? null : _handleChangeEmail,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: cs.primary),
                    ),
                    child: _isChangingEmail
                        ? const CircularProgressIndicator()
                        : const Text('Change Official Email'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Destructive Action: Logout
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton.icon(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout),
              label: const Text(
                'Sign Out',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: cs.error,
                side: BorderSide(color: cs.error),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Widget child,
    required ColorScheme cs,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.onSurface.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: cs.primary, size: 20),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}
