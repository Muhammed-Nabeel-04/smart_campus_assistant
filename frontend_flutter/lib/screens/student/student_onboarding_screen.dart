// File: lib/screens/student/student_onboarding_screen.dart
// Student details completion after QR verification

import 'package:flutter/material.dart';

class StudentOnboardingScreen extends StatefulWidget {
  const StudentOnboardingScreen({super.key});

  @override
  State<StudentOnboardingScreen> createState() =>
      _StudentOnboardingScreenState();
}

class _StudentOnboardingScreenState extends State<StudentOnboardingScreen> {
  final _nameController = TextEditingController();
  final _rollController = TextEditingController();
  final _classController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _rollController.dispose();
    _classController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Onboarding'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 16),

              // ── QR Verified Banner ─────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: const Color(
                    0xFF4CAF50,
                  ).withOpacity(0.12), // Role Success Fixed
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF4CAF50).withOpacity(0.4),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      color: Color(0xFF4CAF50),
                      size: 22,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'QR Code Verified',
                      style: TextStyle(
                        color: Color(0xFF4CAF50),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ── Section Title ──────────────────────────────
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Complete Your Profile',
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 6),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Fill in your details to finish setup',
                  style: TextStyle(
                    color: cs.onSurface.withOpacity(0.6),
                    fontSize: 13,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ── Fields ────────────────────────────────────
              _buildField(
                controller: _nameController,
                label: 'Full Name',
                hint: 'e.g. Arjun Sharma',
                icon: Icons.person_outline_rounded,
                cs: cs,
              ),

              const SizedBox(height: 14),

              _buildField(
                controller: _rollController,
                label: 'Roll Number',
                hint: 'e.g. CS2021045',
                icon: Icons.badge_outlined,
                cs: cs,
              ),

              const SizedBox(height: 14),

              _buildField(
                controller: _classController,
                label: 'Class / Section',
                hint: 'e.g. 3rd Year - Section B',
                icon: Icons.group_outlined,
                cs: cs,
              ),

              const SizedBox(height: 40),

              // ── Complete Button ────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pushReplacementNamed(
                    context,
                    '/studentDashboard',
                  ),
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: const Text(
                    'Complete Registration',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  // Theme handles color automatically (Orange/Amber CTA)
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required ColorScheme cs,
  }) {
    return TextField(
      controller: controller,
      style: TextStyle(color: cs.onSurface),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: cs.primary),
        // All filling and borders are handled by the theme
      ),
    );
  }
}
