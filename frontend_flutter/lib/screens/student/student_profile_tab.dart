// File: lib/screens/student/tabs/student_profile_tab.dart
// Student Profile with READ-ONLY data + Logout

import 'package:flutter/material.dart';
import '../../core/session.dart';
import '../../core/app_colors.dart';
import '../../services/api_service.dart';

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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Logout',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
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
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProfile,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Profile Header
          _buildProfileHeader(),

          const SizedBox(height: 24),

          // Academic Information
          _buildSection('Academic Information', [
            _buildInfoTile(
              Icons.school,
              'Department',
              _profileData?['department'] ?? SessionManager.department ?? 'N/A',
            ),
            _buildInfoTile(
              Icons.class_,
              'Year',
              _profileData?['year'] ?? SessionManager.year ?? 'N/A',
            ),
            _buildInfoTile(
              Icons.group,
              'Section',
              _profileData?['section'] ?? SessionManager.section ?? 'N/A',
            ),
            _buildInfoTile(
              Icons.badge,
              'Register Number',
              _profileData?['register_number'] ??
                  SessionManager.registerNumber ??
                  'N/A',
            ),
          ]),

          const SizedBox(height: 16),

          // Personal Information
          _buildSection('Personal Information', [
            _buildInfoTile(
              Icons.cake,
              'Date of Birth',
              _profileData?['date_of_birth'] != null
                  ? _profileData!['date_of_birth'].toString().split('T')[0]
                  : 'Not set',
            ),
            _buildInfoTile(
              Icons.bloodtype,
              'Blood Group',
              _profileData?['blood_group'] ?? 'Not set',
            ),
            _buildInfoTile(
              Icons.wc,
              'Gender',
              _profileData?['gender'] ?? 'Not set',
            ),
            _buildInfoTile(
              Icons.home,
              'Residential Type',
              _profileData?['residential_type'] ?? 'Day Scholar',
            ),
          ]),

          const SizedBox(height: 16),

          // Contact Information
          _buildSection('Contact Information', [
            _buildInfoTile(
              Icons.phone,
              'Phone',
              _profileData?['phone_number'] ?? 'Not set',
            ),
            _buildInfoTile(
              Icons.email,
              'Email',
              _profileData?['email'] ?? SessionManager.email ?? 'N/A',
            ),
            _buildInfoTile(
              Icons.location_on,
              'Address',
              _profileData?['address'] ?? 'Not set',
            ),
          ]),

          const SizedBox(height: 16),

          // Parent Details
          _buildSection('Parent Details', [
            _buildInfoTile(
              Icons.person,
              'Parent Name',
              _profileData?['parent_name'] ?? 'Not set',
            ),
            _buildInfoTile(
              Icons.phone_android,
              'Parent Phone',
              _profileData?['parent_phone'] ?? 'Not set',
            ),
            _buildInfoTile(
              Icons.email_outlined,
              'Parent Email',
              _profileData?['parent_email'] ?? 'Not set',
            ),
          ]),

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
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
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
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warning.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.warning, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'To update your details, contact your faculty.',
                    style: TextStyle(color: AppColors.warning, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 80), // Extra padding for FAB
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
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
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: Center(
              child: Text(
                SessionManager.name?.substring(0, 1).toUpperCase() ?? 'S',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Name
          Text(
            SessionManager.name ?? 'Student',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 4),

          // Register Number
          Text(
            SessionManager.registerNumber ?? '',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
            ),
          ),

          const SizedBox(height: 8),

          // Class Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_profileData?['department'] ?? SessionManager.department ?? ''} - ${_profileData?['year'] ?? SessionManager.year ?? ''} - Section ${_profileData?['section'] ?? SessionManager.section ?? ''}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
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
