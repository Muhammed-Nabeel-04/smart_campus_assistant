import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text("Student Details")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// STUDENT CARD
            Card(
              color: AppColors.bgCard,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 35,
                      child: Icon(Icons.person, size: 35),
                    ),

                    const SizedBox(height: 16),

                    Text(
                      student['full_name'] ?? "Unknown",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      student['email'] ?? "",
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),

                    const Divider(height: 30),

                    _infoRow("Register No", student['register_number']),
                    _infoRow("Department", student['department']),
                    _infoRow("Year", student['year']),
                    _infoRow("Section", student['section']),
                    _infoRow("Gender", student['gender']),
                    _infoRow("Blood Group", student['blood_group']),
                    _infoRow("Date of Birth", student['date_of_birth']),
                    _infoRow("Phone", student['phone_number']),
                    _infoRow("Email", student['email']),
                    _infoRow("Address", student['address']),
                    _infoRow("Residential", student['residential_type']),
                    _infoRow("Hostel", student['hostel_name']),
                    _infoRow("Room No", student['room_number']),
                    _infoRow("Parent Name", student['parent_name']),
                    _infoRow("Parent Phone", student['parent_phone']),
                    _infoRow("Parent Email", student['parent_email']),
                    _infoRow("Relationship", student['parent_relationship']),
                    _infoRow(
                      "Emergency Contact",
                      student['emergency_contact_name'],
                    ),
                    _infoRow(
                      "Emergency Phone",
                      student['emergency_contact_phone'],
                    ),
                    _infoRow("Medical Info", student['medical_conditions']),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// ACTION BUTTONS
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.qr_code),
                label: const Text("Generate Student QR"),
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

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.edit),
                label: const Text("Edit Student"),
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/facultyEditStudent',
                    arguments: {'studentData': student, 'classData': classData},
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              title,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? "-",
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
