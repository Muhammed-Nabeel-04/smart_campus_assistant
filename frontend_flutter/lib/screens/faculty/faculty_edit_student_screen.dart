// File: lib/screens/faculty/faculty_edit_student_screen.dart
// Faculty form to edit existing student basic details

import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class FacultyEditStudentScreen extends StatefulWidget {
  final Map<String, dynamic> studentData;
  final Map<String, dynamic> classData;

  const FacultyEditStudentScreen({
    super.key,
    required this.studentData,
    required this.classData,
  });

  @override
  State<FacultyEditStudentScreen> createState() =>
      _FacultyEditStudentScreenState();
}

class _FacultyEditStudentScreenState extends State<FacultyEditStudentScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;

  bool loading = false;

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(
      text: widget.studentData['full_name'] ?? "",
    );

    emailController = TextEditingController(
      text: widget.studentData['email'] ?? "",
    );

    phoneController = TextEditingController(
      text:
          widget.studentData['phone'] ??
          widget.studentData['phone_number'] ??
          "",
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> updateStudent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      await ApiService.updateStudent(widget.studentData['id'], {
        "full_name": nameController.text.trim(),
        "email": emailController.text.trim(),
        "phone_number": phoneController.text.trim(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Student updated successfully"),
          backgroundColor: Color(0xFF4CAF50), // Success Green
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Edit Student")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Basic Information",
                style: TextStyle(
                  color: cs.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: nameController,
                style: TextStyle(color: cs.onSurface),
                decoration: const InputDecoration(
                  labelText: "Full Name",
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? "Enter name" : null,
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: emailController,
                style: TextStyle(color: cs.onSurface),
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Email Address",
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: phoneController,
                style: TextStyle(color: cs.onSurface),
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Phone Number",
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: loading ? null : updateStudent,
                  child: loading
                      ? SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: cs.onPrimary,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Update Student",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
