// File: lib/screens/admin/admin_faculty_details_screen.dart
// Admin view of specific faculty profile with detailed assignments and QR actions

import 'package:flutter/material.dart';

class AdminFacultyDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> faculty;

  const AdminFacultyDetailsScreen({super.key, required this.faculty});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Faculty Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.pushNamed(
              context,
              '/adminEditFaculty',
              arguments: faculty,
            ),
            tooltip: 'Edit Profile',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Header Card
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
                      faculty['name'].toString().substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: cs.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    faculty['name'],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: cs.onPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    faculty['email'],
                    style: TextStyle(
                      color: cs.onPrimary.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Information Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.onSurface.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: cs.primary, size: 20),
                      const SizedBox(width: 10),
                      const Text(
                        'Faculty Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildInfoRow('Employee ID', faculty['employee_id'], cs),
                  _buildInfoRow('Department', faculty['department'], cs),
                  _buildInfoRow(
                    'Phone',
                    faculty['phone'] ?? faculty['phone_number'],
                    cs,
                  ),
                  _buildInfoRow('Email', faculty['email'], cs),
                  const Divider(height: 32),
                  const Text(
                    'Teaching Assignments',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildAssignmentsList(faculty['teaching_assignments'], cs),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Primary Action Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(
                  context,
                  '/adminGenerateFacultyQR',
                  arguments: faculty,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(
                    0xFF4CAF50,
                  ), // Role Success Fixed
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text(
                  'Generate Setup QR Code',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, dynamic value, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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
              value?.toString() ?? 'N/A',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentsList(dynamic assignments, ColorScheme cs) {
    if (assignments == null || (assignments as List).isEmpty) {
      return Text(
        'No assignments found',
        style: TextStyle(
          color: cs.onSurface.withOpacity(0.4),
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: (assignments as List).map((a) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: cs.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: cs.primary.withOpacity(0.1)),
          ),
          child: Text(
            '${a['department']} · ${a['year']} · Sec ${a['section']}',
            style: TextStyle(
              color: cs.primary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }
}
