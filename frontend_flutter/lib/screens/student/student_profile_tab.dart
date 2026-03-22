// File: lib/screens/student/tabs/student_profile_tab.dart
// Student Profile with READ-ONLY data + Logout + Theme Toggle

import 'package:flutter/material.dart';
import '../../core/session.dart';
import '../../services/api_service.dart';
import '../../main.dart'; // Required for SmartCampusApp.setTheme

class StudentProfileTab extends StatefulWidget {
  const StudentProfileTab({super.key});

  @override
  State<StudentProfileTab> createState() => _StudentProfileTabState();
}

class _StudentProfileTabState extends State<StudentProfileTab> {
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getStudentProfile(
        SessionManager.studentId!,
      );
      setState(() {
        _profileData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    final cs = Theme.of(context).colorScheme;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cs.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Logout', style: TextStyle(color: cs.onSurface)),
        content: Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: cs.onSurface.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: cs.onSurface.withOpacity(0.6)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.error,
              foregroundColor: cs.onError,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await ApiService.logout();
      await SessionManager.clearSession();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: cs.primary));
    }

    return RefreshIndicator(
      onRefresh: _loadProfile,
      color: cs.primary,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Profile Header
          _buildProfileHeader(cs),

          const SizedBox(height: 24),

          // Theme Selection Section (NEW)
          _buildSection('App Settings', [_buildThemeTile(context, cs)], cs),

          const SizedBox(height: 16),

          // Academic Information
          _buildSection('Academic Information', [
            _buildInfoTile(
              Icons.school,
              'Department',
              _profileData?['department'] ?? SessionManager.department ?? 'N/A',
              cs,
            ),
            _buildInfoTile(
              Icons.class_,
              'Year',
              _profileData?['year'] ?? SessionManager.year ?? 'N/A',
              cs,
            ),
            _buildInfoTile(
              Icons.group,
              'Section',
              _profileData?['section'] ?? SessionManager.section ?? 'N/A',
              cs,
            ),
            _buildInfoTile(
              Icons.badge,
              'Register Number',
              _profileData?['register_number'] ??
                  SessionManager.registerNumber ??
                  'N/A',
              cs,
            ),
          ], cs),

          const SizedBox(height: 16),

          // Personal Information
          _buildSection('Personal Information', [
            _buildInfoTile(
              Icons.cake,
              'Date of Birth',
              _profileData?['date_of_birth'] != null
                  ? _profileData!['date_of_birth'].toString().split('T')[0]
                  : 'Not set',
              cs,
            ),
            _buildInfoTile(
              Icons.bloodtype,
              'Blood Group',
              _profileData?['blood_group'] ?? 'Not set',
              cs,
            ),
            _buildInfoTile(
              Icons.wc,
              'Gender',
              _profileData?['gender'] ?? 'Not set',
              cs,
            ),
            _buildInfoTile(
              Icons.home,
              'Residential Type',
              _profileData?['residential_type'] ?? 'Day Scholar',
              cs,
            ),
          ], cs),

          const SizedBox(height: 16),

          // Contact Information
          _buildSection('Contact Information', [
            _buildInfoTile(
              Icons.phone,
              'Phone',
              _profileData?['phone_number'] ?? 'Not set',
              cs,
            ),
            _buildInfoTile(
              Icons.email,
              'Email',
              _profileData?['email'] ?? SessionManager.email ?? 'N/A',
              cs,
            ),
            _buildInfoTile(
              Icons.location_on,
              'Address',
              _profileData?['address'] ?? 'Not set',
              cs,
            ),
          ], cs),

          const SizedBox(height: 32),

          // Logout Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout),
              label: const Text(
                'Logout',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.error,
                foregroundColor: cs.onError,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Note
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFF9800).withOpacity(0.1), // Warning Fixed
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFFF9800).withOpacity(0.3),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFFFF9800), size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'To update your details, contact your faculty.',
                    style: TextStyle(color: Color(0xFFFF9800), fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildThemeTile(BuildContext context, ColorScheme cs) {
    final current = SmartCampusApp.currentTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Theme Mode',
          style: TextStyle(
            color: cs.onSurface.withOpacity(0.7),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.system,
                label: Text('System'),
                icon: Icon(Icons.brightness_auto, size: 18),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                label: Text('Light'),
                icon: Icon(Icons.light_mode, size: 18),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text('Dark'),
                icon: Icon(Icons.dark_mode, size: 18),
              ),
            ],
            selected: {current},
            onSelectionChanged: (val) => SmartCampusApp.setTheme(val.first),
            style: ButtonStyle(
              visualDensity: VisualDensity.comfortable,
              side: WidgetStateProperty.all(
                BorderSide(color: cs.outline.withOpacity(0.2)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHeader(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: cs.onPrimary.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: cs.onPrimary, width: 3),
            ),
            child: Center(
              child: Text(
                SessionManager.name?.substring(0, 1).toUpperCase() ?? 'S',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: cs.onPrimary,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Name
          Text(
            SessionManager.name ?? 'Student',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: cs.onPrimary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 4),

          // Register Number
          Text(
            SessionManager.registerNumber ?? '',
            style: TextStyle(
              fontSize: 16,
              color: cs.onPrimary.withOpacity(0.9),
            ),
          ),

          const SizedBox(height: 12),

          // Class Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: cs.onPrimary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_profileData?['department'] ?? SessionManager.department ?? ''} • ${_profileData?['year'] ?? SessionManager.year ?? ''} • Section ${_profileData?['section'] ?? SessionManager.section ?? ''}',
              style: TextStyle(
                color: cs.onPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: cs.primary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoTile(
    IconData icon,
    String label,
    String value,
    ColorScheme cs,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: cs.onSurface.withOpacity(0.5), size: 20),
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
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
