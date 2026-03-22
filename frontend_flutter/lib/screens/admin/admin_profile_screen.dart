// File: lib/screens/admin/admin_profile_screen.dart
// Admin/HOD profile page with logout and account settings

import 'package:flutter/material.dart';
import '../../core/session.dart';
import '../../services/api_service.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  String _department = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDepartment();
  }

  Future<void> _loadDepartment() async {
    setState(() => _isLoading = true);
    try {
      final deptData = await ApiService.getHODDepartment();
      if (mounted) {
        setState(() {
          _department =
              deptData['department_name'] ??
              deptData['department'] ??
              'UNKNOWN';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _department = 'UNKNOWN';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    final cs = Theme.of(context).colorScheme;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cs.surface,
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: cs.error),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await ApiService.logout();
      await SessionManager.clearSession();
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  }

  void _showChangePasswordDialog() {
    final cs = Theme.of(context).colorScheme;
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cs.surface,
        title: const Text('Change Password'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: Icon(Icons.lock_reset),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                  prefixIcon: Icon(Icons.check_circle_outline),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPasswordController.text.length < 6) {
                _showSnack(
                  'Password must be at least 6 characters',
                  isError: true,
                );
                return;
              }
              if (newPasswordController.text !=
                  confirmPasswordController.text) {
                _showSnack('Passwords do not match', isError: true);
                return;
              }
              Navigator.pop(context);
              try {
                await ApiService.changeAdminPassword(
                  newPassword: newPasswordController.text,
                );
                _showSnack('Password changed successfully');
              } on ApiException catch (e) {
                _showSnack(e.message, isError: true);
              }
            },
            child: const Text('Change Password'),
          ),
        ],
      ),
    );
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
      appBar: AppBar(title: const Text('Profile'), centerTitle: true),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: cs.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Profile Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: cs.primary.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: cs.onPrimary,
                          child: Text(
                            SessionManager.name
                                    ?.substring(0, 1)
                                    .toUpperCase() ??
                                'A',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: cs.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          SessionManager.name ?? 'Administrator',
                          style: TextStyle(
                            color: cs.onPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: cs.onPrimary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$_department HOD',
                            style: TextStyle(
                              color: cs.onPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Info Card
                  Container(
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cs.onSurface.withOpacity(0.1)),
                    ),
                    child: Column(
                      children: [
                        _buildInfoTile(
                          Icons.alternate_email,
                          'Email',
                          SessionManager.email ?? 'N/A',
                          cs,
                        ),
                        _buildInfoTile(
                          Icons.business_outlined,
                          'Home Department',
                          _department,
                          cs,
                        ),
                        _buildInfoTile(
                          Icons.badge_outlined,
                          'Admin User ID',
                          '${SessionManager.userId ?? 'N/A'}',
                          cs,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Actions Card
                  Container(
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cs.onSurface.withOpacity(0.1)),
                    ),
                    child: Column(
                      children: [
                        _buildActionTile(
                          icon: Icons.lock_reset_outlined,
                          title: 'Change Account Password',
                          color: const Color(0xFFFF9800), // Warning orange
                          onTap: _showChangePasswordDialog,
                          cs: cs,
                        ),
                        _buildActionTile(
                          icon: Icons.settings_outlined,
                          title: 'System Settings',
                          color: const Color(0xFF2196F3), // Info blue
                          onTap: () =>
                              Navigator.pushNamed(context, '/adminSettings'),
                          cs: cs,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: _handleLogout,
                      icon: const Icon(Icons.logout),
                      label: const Text(
                        'Sign Out',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: cs.error,
                        side: BorderSide(color: cs.error),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  Text(
                    'Campus Assistant Enterprise v2.0.4',
                    style: TextStyle(
                      color: cs.onSurface.withOpacity(0.3),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoTile(
    IconData icon,
    String label,
    String value,
    ColorScheme cs,
  ) {
    return ListTile(
      leading: Icon(icon, color: cs.primary, size: 22),
      title: Text(
        label,
        style: TextStyle(color: cs.onSurface.withOpacity(0.5), fontSize: 12),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
    required ColorScheme cs,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      trailing: Icon(
        Icons.chevron_right,
        size: 18,
        color: cs.onSurface.withOpacity(0.3),
      ),
    );
  }
}
