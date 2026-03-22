// File: lib/screens/admin/admin_settings_screen.dart
// Admin interface for system configurations, account security, and data management

import 'package:flutter/material.dart';
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
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Account Section
          _buildSectionTitle('Account Profile', cs),
          _buildAccountCard(cs),

          const SizedBox(height: 24),

          // System Settings
          _buildSectionTitle('System Configuration', cs),
          _buildSettingCard(
            'Push Notifications',
            'Send real-time alerts to users',
            Switch(
              value: _enableNotifications,
              onChanged: (v) => setState(() => _enableNotifications = v),
              activeColor: cs.primary,
            ),
            cs,
          ),
          _buildSettingCard(
            'Faculty Verification',
            'Manual approval for new faculty',
            Switch(
              value: _requireApprovalForFaculty,
              onChanged: (v) => setState(() => _requireApprovalForFaculty = v),
              activeColor: cs.primary,
            ),
            cs,
          ),
          _buildSettingCard(
            'Auto-Resolve Tickets',
            'Automate student complaint closure',
            Switch(
              value: _autoApproveComplaints,
              onChanged: (v) => setState(() => _autoApproveComplaints = v),
              activeColor: cs.primary,
            ),
            cs,
          ),

          const SizedBox(height: 24),

          // Security Settings
          _buildSectionTitle('Security & Privacy', cs),
          _buildSettingCard(
            'Session Timeout',
            'Duration before auto-logout',
            DropdownButton<String>(
              value: _sessionTimeout,
              dropdownColor: cs.surface,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: '1', child: Text('1 hour')),
                DropdownMenuItem(value: '6', child: Text('6 hours')),
                DropdownMenuItem(value: '24', child: Text('24 hours')),
                DropdownMenuItem(value: '168', child: Text('7 days')),
              ],
              onChanged: (v) => setState(() => _sessionTimeout = v!),
            ),
            cs,
          ),

          const SizedBox(height: 12),

          _buildActionButton(
            'Update Login Password',
            Icons.lock_reset_outlined,
            () => _showPasswordDialog(),
            cs,
          ),

          const SizedBox(height: 24),

          // Data Management
          _buildSectionTitle('System Maintenance', cs),
          _buildActionButton(
            'Generate System Backup',
            Icons.cloud_download_outlined,
            () => _showExportDialog(),
            cs,
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            'Wipe Application Cache',
            Icons.cleaning_services_outlined,
            () => _confirmClearCache(),
            cs,
          ),

          const SizedBox(height: 24),

          // About
          _buildSectionTitle('About Platform', cs),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.onSurface.withOpacity(0.05)),
            ),
            child: Column(
              children: [
                _buildInfoRow('Version', '2.0.4 Enterprise', cs),
                Divider(height: 24, color: cs.onSurface.withOpacity(0.05)),
                _buildInfoRow('Environment', 'Production', cs),
                Divider(height: 24, color: cs.onSurface.withOpacity(0.05)),
                _buildInfoRow('Last Patch', '2026-03-15', cs),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Danger Zone
          _buildSectionTitle('Danger Zone', cs),
          _buildActionButton(
            'Re-initialize System',
            Icons.factory_outlined,
            () => _confirmReset(),
            cs,
            color: const Color(0xFFFF9800), // Warning Orange
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            'Purge Database Records',
            Icons.delete_forever_outlined,
            () => _confirmDeleteAll(),
            cs,
            color: cs.error,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: cs.onSurface.withOpacity(0.5),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildAccountCard(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: cs.primary,
            child: Text(
              SessionManager.name?.substring(0, 1).toUpperCase() ?? 'A',
              style: TextStyle(
                fontSize: 22,
                color: cs.onPrimary,
                fontWeight: FontWeight.bold,
              ),
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
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  SessionManager.email ?? 'admin@campus.edu',
                  style: TextStyle(
                    color: cs.onSurface.withOpacity(0.6),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Super Admin Access',
                  style: TextStyle(
                    color: cs.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard(
    String title,
    String subtitle,
    Widget trailing,
    ColorScheme cs,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.onSurface.withOpacity(0.05)),
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
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: cs.onSurface.withOpacity(0.5),
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

  Widget _buildActionButton(
    String label,
    IconData icon,
    VoidCallback onTap,
    ColorScheme cs, {
    Color? color,
  }) {
    final activeColor = color ?? cs.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: activeColor.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: activeColor, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: color ?? cs.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: cs.onSurface.withOpacity(0.3),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, ColorScheme cs) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: cs.onSurface.withOpacity(0.5), fontSize: 13),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }

  // --- Modal Logic ---

  void _showPasswordDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Security Update'),
        content: const Text(
          'This will redirect you to the password management portal.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Proceed'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Export System Log'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Save as CSV'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Save as PDF'),
          ),
        ],
      ),
    );
  }

  void _confirmClearCache() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('App cache has been cleared')));
  }

  void _confirmReset() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('System Reset'),
        content: const Text(
          'This will restore all configuration defaults. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Reset',
              style: TextStyle(color: Color(0xFFFF9800)),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAll() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Purge Database'),
        content: const Text(
          'This action will delete all user data permanently. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );
  }
}
