import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

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
    return Scaffold(
      backgroundColor: AppColors.bgDark,
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
                  color: AppColors.success.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.success.withOpacity(0.4)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      color: AppColors.success,
                      size: 22,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'QR Code Verified',
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ── Section Title ──────────────────────────────
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Complete Your Profile',
                  style: TextStyle(
                    color: AppColors.textPrimary,
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
                    color: AppColors.textSecondary,
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
              ),

              const SizedBox(height: 14),

              _buildField(
                controller: _rollController,
                label: 'Roll Number',
                hint: 'e.g. CS2021045',
                icon: Icons.badge_outlined,
              ),

              const SizedBox(height: 14),

              _buildField(
                controller: _classController,
                label: 'Class / Section',
                hint: 'e.g. 3rd Year - Section B',
                icon: Icons.group_outlined,
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
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primary),
      ),
    );
  }
}
