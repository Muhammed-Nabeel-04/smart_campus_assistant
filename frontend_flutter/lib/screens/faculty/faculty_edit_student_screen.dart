import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
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
      text: widget.studentData['phone'] ?? "",
    );
  }

  Future<void> updateStudent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      await ApiService.updateStudent(widget.studentData['id'], {
        "full_name": nameController.text,
        "email": emailController.text,
        "phone_number": phoneController.text,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Student updated successfully")),
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Student")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Full Name"),
                validator: (v) => v == null || v.isEmpty ? "Enter name" : null,
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Email"),
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: "Phone"),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: loading ? null : updateStudent,
                  child: loading
                      ? const CircularProgressIndicator()
                      : const Text("Update Student"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
