import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:http/http.dart' as http;

import '../../core/app_config.dart'; // ✅ Added AppConfig import
import '../../core/session.dart';

class StudentOnboardingQRScreen extends StatefulWidget {
  const StudentOnboardingQRScreen({super.key});

  @override
  State<StudentOnboardingQRScreen> createState() =>
      _StudentOnboardingQRScreenState();
}

class _StudentOnboardingQRScreenState extends State<StudentOnboardingQRScreen> {
  String? qrData;
  bool loading = false;

  Future<void> generateQR() async {
    setState(() {
      loading = true;
    });

    try {
      // ✅ Using dynamic AppConfig
      final uri = Uri.parse("${AppConfig.backendUrl}/onboarding/generate-qr")
          .replace(
            queryParameters: {"faculty_id": SessionManager.userId.toString()},
          );

      final response = await http.post(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            qrData = data["token"];
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to generate QR")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error generating QR. Check connection."),
          ),
        );
      }
    } finally {
      // ✅ Ensures loading always stops, even on error
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    generateQR();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Student Onboarding QR")),

      body: Center(
        child: loading
            ? const CircularProgressIndicator()
            : qrData == null
            ? const Text("QR not generated")
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  QrImageView(data: qrData!, size: 250),

                  const SizedBox(height: 20),

                  const Text(
                    "Students scan this QR to register",
                    style: TextStyle(fontSize: 16),
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: generateQR,
                    child: const Text("Generate New QR"),
                  ),
                ],
              ),
      ),
    );
  }
}
