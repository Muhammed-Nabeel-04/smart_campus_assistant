// lib/screens/principal/principal_profile_screen.dart
import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/session.dart';
import '../../services/api_service.dart';

class PrincipalProfileScreen extends StatefulWidget {
  const PrincipalProfileScreen({super.key});

  @override
  State<PrincipalProfileScreen> createState() =>
      _PrincipalProfileScreenState();
}

class _PrincipalProfileScreenState extends State<PrincipalProfileScreen> {
  final _passFormKey = GlobalKey<FormState>();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
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
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleChangePassword() async {
    if (!_passFormKey.currentState!.validate()) return;
    setState(() => _isChangingPass = true);
    try {
      await ApiService.changePrincipalPassword(
          newPassword: _newPassCtrl.text);
      if (mounted) {
        _newPassCtrl.clear();
        _confirmPassCtrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Password changed successfully'),
            backgroundColor: AppColors.success));
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.message), backgroundColor: AppColors.danger));
      }
    } finally {
      if (mounted) setState(() => _isChangingPass = false);
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: const Text('Logout',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('Are you sure you want to logout?',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await SessionManager.clearSession();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
            context, '/', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(title: const Text('My Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6A1B9A), Color(0xFF8E24AA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: Colors.white,
                  child: Text(
                    (SessionManager.displayName)
                        .substring(0, 1)
                        .toUpperCase(),
                    style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6A1B9A)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  SessionManager.displayName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  SessionManager.email ?? '',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Principal',
                      style:
                          TextStyle(color: Colors.white, fontSize: 13)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Change password card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Form(
              key: _passFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Change Password',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _newPassCtrl,
                    obscureText: _obscureNew,
                    style:
                        const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureNew
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () => setState(
                            () => _obscureNew = !_obscureNew),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (v.length < 6) return 'Min 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _confirmPassCtrl,
                    obscureText: _obscureConfirm,
                    style:
                        const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirm
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () => setState(
                            () => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                    validator: (v) {
                      if (v != _newPassCtrl.text)
                        return 'Passwords do not match';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isChangingPass
                          ? null
                          : _handleChangePassword,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6A1B9A)),
                      child: _isChangingPass
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white))
                          : const Text('Update Password'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Logout button
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _handleLogout,
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger),
              icon: const Icon(Icons.logout),
              label: const Text('Logout',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
