// lib/screens/principal/principal_hod_details_screen.dart
import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

class PrincipalHODDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> hod;
  const PrincipalHODDetailsScreen({super.key, required this.hod});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(title: const Text('HOD Details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile header
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
                    (hod['name'] ?? 'H')
                        .toString()
                        .substring(0, 1)
                        .toUpperCase(),
                    style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1565C0)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(hod['name'] ?? '',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(hod['email'] ?? '',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 8),
                if (hod['department_name'] != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${hod['department_code']} — ${hod['department_name']}',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 13),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('HOD Information',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _infoRow('Employee ID', hod['employee_id'] ?? 'N/A'),
                _infoRow('Phone',
                    hod['phone'] ?? 'Not provided'),
                _infoRow('Department',
                    hod['department_name'] ?? 'Not assigned'),
                _infoRow('Status',
                    hod['has_password'] == true ? 'Active' : 'Pending Setup'),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Generate QR button
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(
                context,
                '/principalGenerateHODQR',
                arguments: hod,
              ),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0)),
              icon: const Icon(Icons.qr_code),
              label: const Text('Generate QR Code',
                  style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 14)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
