// File: lib/screens/faculty/faculty_student_details_screen.dart
// Faculty view of full student profile details with action buttons

import 'package:flutter/material.dart';

class FacultyStudentDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> student;
  final Map<String, dynamic> classData;

  const FacultyStudentDetailsScreen({
    super.key,
    required this.student,
    required this.classData,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Student Details")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// STUDENT CARD
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: cs.onSurface.withOpacity(0.1)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: cs.primary.withOpacity(0.1),
                      child: Icon(Icons.person, size: 40, color: cs.primary),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      student['full_name'] ?? "Unknown",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      student['register_number'] ?? "",
                      style: TextStyle(
                        color: cs.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const Divider(height: 40),

                    _infoRow("Department", student['department'], cs),
                    _infoRow("Year", student['year'], cs),
                    _infoRow("Section", student['section'], cs),
                    _infoRow("Gender", student['gender'], cs),
                    _infoRow("Blood Group", student['blood_group'], cs),
                    _infoRow("Date of Birth", student['date_of_birth'], cs),
                    _infoRow("Phone", student['phone_number'], cs),
                    _infoRow("Email", student['email'], cs),
                    _infoRow("Address", student['address'], cs),
                    _infoRow("Residential", student['residential_type'], cs),
                    if (student['residential_type'] != null &&
                        student['residential_type'] != 'Day Scholar') ...[
                      _infoRow("Hostel", student['hostel_name'], cs),
                      _infoRow("Room No", student['room_number'], cs),
                    ],
                    _infoRow("Parent Name", student['parent_name'], cs),
                    _infoRow("Parent Phone", student['parent_phone'], cs),
                    _infoRow("Parent Email", student['parent_email'], cs),
                    _infoRow(
                      "Relationship",
                      student['parent_relationship'],
                      cs,
                    ),
                    _infoRow(
                      "Emergency",
                      student['emergency_contact_name'],
                      cs,
                    ),
                    _infoRow(
                      "Emerg. Phone",
                      student['emergency_contact_phone'],
                      cs,
                    ),
                    _infoRow("Medical Info", student['medical_conditions'], cs),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            /// ACTION BUTTONS
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.qr_code),
                label: const Text("Generate Login QR"),
                onPressed: () {
                  if (student['id'] == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Invalid student data")),
                    );
                    return;
                  }
                  Navigator.pushNamed(
                    context,
                    '/facultyGenerateStudentQR',
                    arguments: student,
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.edit_outlined),
                label: const Text("Edit Student Profile"),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: cs.primary),
                  foregroundColor: cs.primary,
                ),
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/facultyEditStudent',
                    arguments: {'studentData': student, 'classData': classData},
                  );
                },
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String title, dynamic value, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              title,
              style: TextStyle(
                color: cs.onSurface.withOpacity(0.5),
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? "-",
              style: TextStyle(
                color: cs.onSurface,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
