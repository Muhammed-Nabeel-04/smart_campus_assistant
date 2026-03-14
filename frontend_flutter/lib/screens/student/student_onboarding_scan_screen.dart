import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/api_service.dart';
import '../../core/app_colors.dart';

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

      // Call correct endpoint with POST JSON body
      final data = await ApiService.validateStudentQR(token: token);

      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/studentPasswordSetup',
          arguments: {
            'token': data['token'],
            'name': data['full_name'],
            'register_number': data['register_number'],
            'department': data['department'],
            'year': data['year'],
            'section': data['section'],
            'student_id': data['student_id'],
          },
        );
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
      appBar: AppBar(title: const Text('Student Login')),
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
