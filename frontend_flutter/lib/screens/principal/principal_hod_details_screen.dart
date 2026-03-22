// File: lib/screens/principal/principal_hod_details_screen.dart
// Principal's detailed view of a specific HOD's profile and department assignment

import 'package:flutter/material.dart';

class PrincipalHODDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> hod;
  const PrincipalHODDetailsScreen({super.key, required this.hod});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('HOD Profile'), elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Profile Header Card
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: cs.primary,
              borderRadius: BorderRadius.circular(24),
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
                    (hod['name'] ?? 'H')
                        .toString()
                        .substring(0, 1)
                        .toUpperCase(),
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: cs.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  hod['name'] ?? 'Unknown HOD',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: cs.onPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  hod['email'] ?? '',
                  style: TextStyle(
                    color: cs.onPrimary.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                if (hod['department_name'] != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: cs.onPrimary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      '${hod['department_code']} — ${hod['department_name']}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: cs.onPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Information Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: cs.onSurface.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.badge_outlined, color: cs.primary, size: 20),
                    const SizedBox(width: 10),
                    const Text(
                      'Professional Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _infoRow(
                  'Employee ID',
                  hod['employee_id'] ?? 'Not Assigned',
                  cs,
                ),
                _infoRow('Contact Number', hod['phone'] ?? 'Not Provided', cs),
                _infoRow(
                  'Department',
                  hod['department_name'] ?? 'Unassigned',
                  cs,
                ),
                _infoRow(
                  'Account Status',
                  hod['has_password'] == true
                      ? 'Active & Verified'
                      : 'Setup Required',
                  cs,
                  isStatus: true,
                  statusValue: hod['has_password'] == true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Action: Generate QR
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(
                context,
                '/principalGenerateHODQR',
                arguments: hod,
              ),
              icon: const Icon(Icons.qr_code_2_rounded),
              label: const Text(
                'Generate Setup QR Code',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _infoRow(
    String label,
    String value,
    ColorScheme cs, {
    bool isStatus = false,
    bool statusValue = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                color: cs.onSurface.withOpacity(0.5),
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isStatus
                    ? (statusValue ? const Color(0xFF4CAF50) : Colors.orange)
                    : cs.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
