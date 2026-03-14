// File: lib/screens/admin/admin_faculty_details_screen.dart
import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

class AdminFacultyDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> faculty;
  
  const AdminFacultyDetailsScreen({super.key, required this.faculty});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Faculty Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.pushNamed(
              context,
              '/adminEditFaculty',
              arguments: faculty,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
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
                    faculty['name'].toString().substring(0, 1),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1565C0),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  faculty['name'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  faculty['email'],
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Details Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Faculty Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                
                _buildInfoRow('Employee ID', faculty['employee_id']),
                _buildInfoRow('Department', faculty['department']),
                _buildInfoRow('Phone', faculty['phone'] ?? 'Not provided'),
                _buildInfoRow('Email', faculty['email']),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Action Buttons
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(
                context,
                '/adminGenerateFacultyQR',
                arguments: faculty,
              ),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
              icon: const Icon(Icons.qr_code),
              label: const Text('Generate QR Code'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
