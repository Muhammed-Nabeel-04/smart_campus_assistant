// File: lib/screens/admin/admin_settings_screen.dart
import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/session.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  bool _enableNotifications = true;
  bool _autoApproveComplaints = false;
  bool _requireApprovalForFaculty = true;
  String _sessionTimeout = '24';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(title: const Text('Admin Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Account Section
          _buildSectionTitle('Account'),
          _buildAccountCard(),

          const SizedBox(height: 24),

          // System Settings
          _buildSectionTitle('System Settings'),
          _buildSettingCard(
            'Enable Notifications',
            'Send push notifications to users',
            Switch(
              value: _enableNotifications,
              onChanged: (v) => setState(() => _enableNotifications = v),
              activeColor: AppColors.danger,
            ),
          ),
          _buildSettingCard(
            'Faculty Approval Required',
            'New faculty must be approved before access',
            Switch(
              value: _requireApprovalForFaculty,
              onChanged: (v) => setState(() => _requireApprovalForFaculty = v),
              activeColor: AppColors.danger,
            ),
          ),
          _buildSettingCard(
            'Auto-Approve Complaints',
            'Automatically mark complaints as approved',
            Switch(
              value: _autoApproveComplaints,
              onChanged: (v) => setState(() => _autoApproveComplaints = v),
              activeColor: AppColors.danger,
            ),
          ),

          const SizedBox(height: 24),

          // Security Settings
          _buildSectionTitle('Security'),
          _buildSettingCard(
            'Session Timeout',
            'Automatically logout after inactivity',
            DropdownButton<String>(
              value: _sessionTimeout,
              items: const [
                DropdownMenuItem(value: '1', child: Text('1 hour')),
                DropdownMenuItem(value: '6', child: Text('6 hours')),
                DropdownMenuItem(value: '24', child: Text('24 hours')),
                DropdownMenuItem(value: '168', child: Text('7 days')),
              ],
              onChanged: (v) => setState(() => _sessionTimeout = v!),
              dropdownColor: AppColors.bgCard,
            ),
          ),

          const SizedBox(height: 12),

          _buildActionButton(
            'Change Password',
            Icons.lock_outline,
            () => _showPasswordDialog(),
          ),

          const SizedBox(height: 24),

          // Data Management
          _buildSectionTitle('Data Management'),
          _buildActionButton(
            'Export All Data',
            Icons.download,
            () => _showExportDialog(),
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            'Clear Cache',
            Icons.delete_sweep,
            () => _confirmClearCache(),
          ),

          const SizedBox(height: 24),

          // About
          _buildSectionTitle('About'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildInfoRow('App Version', '1.0.0'),
                const Divider(height: 24),
                _buildInfoRow('Build Number', '1'),
                const Divider(height: 24),
                _buildInfoRow('Last Updated', '2024-03-10'),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Danger Zone
          _buildSectionTitle('Danger Zone'),
          _buildActionButton(
            'Reset System',
            Icons.restore,
            () => _confirmReset(),
            color: AppColors.warning,
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            'Delete All Data',
            Icons.delete_forever,
            () => _confirmDeleteAll(),
            color: AppColors.danger,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildAccountCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.danger,
            child: Text(
              SessionManager.name?.substring(0, 1) ?? 'A',
              style: const TextStyle(fontSize: 24, color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  SessionManager.name ?? 'Administrator',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  SessionManager.email ?? 'admin@college.edu',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Role: Admin',
                  style: const TextStyle(
                    color: AppColors.danger,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard(String title, String subtitle, Widget trailing) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap, {Color? color}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: (color ?? AppColors.primary).withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color ?? AppColors.primary, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: color ?? AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: AppColors.textHint, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        Text(
          value,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  void _showPasswordDialog() {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentController,
              decoration: const InputDecoration(labelText: 'Current Password'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newController,
              decoration: const InputDecoration(labelText: 'New Password'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmController,
              decoration: const InputDecoration(labelText: 'Confirm New Password'),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password changed successfully')),
              );
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: const Text('Choose data format for export:'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CSV')),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('JSON')),
        ],
      ),
    );
  }

  void _confirmClearCache() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('This will clear all cached data. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _confirmReset() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset System'),
        content: const Text('This will reset all system settings to default. User data will NOT be affected.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('System reset complete')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.warning),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAll() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Data'),
        content: const Text('WARNING: This will delete ALL data including users, attendance, and complaints. This action CANNOT be undone!'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('For safety, this action requires server confirmation'),
                  backgroundColor: AppColors.danger,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('DELETE ALL'),
          ),
        ],
      ),
    );
  }
}
