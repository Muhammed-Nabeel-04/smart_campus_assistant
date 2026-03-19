import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/api_service.dart';
import '../../core/app_colors.dart';
import '../../core/session.dart';

class StudentOnboardingScanScreen extends StatefulWidget {
  const StudentOnboardingScanScreen({super.key});

  @override
  State<StudentOnboardingScanScreen> createState() =>
      _StudentOnboardingScanScreenState();
}

class _StudentOnboardingScanScreenState
    extends State<StudentOnboardingScanScreen> {
  bool _scanned = false;
  bool _processing = false;

  Future<void> _validateQR(String rawValue) async {
    if (_processing) return;
    setState(() => _processing = true);

    try {
      // QR contains JSON: {"student_id":..., "register_number":..., "token":...}
      // Extract the token field
      String token;
      try {
        final qrJson = jsonDecode(rawValue);
        token = qrJson['token'];
      } catch (_) {
        // If not JSON, treat rawValue as plain token
        token = rawValue;
      }

      final data = await ApiService.validateStudentQR(token: token);

      // Save session
      await SessionManager.saveSession(
        userId: data['user_id'],
        name: data['name'],
        email: data['email'] ?? data['register_number'],
        role: 'student',
        token: data['token'],
        studentId: data['student_id'],
        department: data['department'],
        year: data['year'],
        section: data['section'],
        registerNumber: data['register_number'],
      );

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/studentDashboard');
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
        setState(() {
          _scanned = false;
          _processing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('QR validation failed. Check connection.'),
          ),
        );
        setState(() {
          _scanned = false;
          _processing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Student Login'),
        actions: [
          IconButton(
            icon: const Icon(Icons.keyboard),
            onPressed: () {
              final ctrl = TextEditingController();
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppColors.bgCard,
                  title: const Text(
                    'Enter QR Token',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                  content: TextField(
                    controller: ctrl,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'Paste token here',
                    ),
                  ),
                  actions: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        if (ctrl.text.isNotEmpty) _validateQR(ctrl.text);
                      },
                      child: const Text('Submit'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (BarcodeCapture capture) {
              if (_scanned) return;
              final barcode = capture.barcodes.first;
              final String? raw = barcode.rawValue;
              if (raw != null) {
                setState(() => _scanned = true);
                _validateQR(raw);
              }
            },
          ),
          if (_processing)
            const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
        ],
      ),
    );
  }
}
