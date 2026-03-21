// File: lib/screens/student/student_mark_attendance_screen.dart
// Scan QR to mark attendance in active session

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:convert';
import '../../services/api_service.dart';
import '../../core/session.dart';

class StudentMarkAttendanceScreen extends StatefulWidget {
  const StudentMarkAttendanceScreen({super.key});

  @override
  State<StudentMarkAttendanceScreen> createState() =>
      _StudentMarkAttendanceScreenState();
}

class _StudentMarkAttendanceScreenState
    extends State<StudentMarkAttendanceScreen> {
  bool _isProcessing = false;
  bool _marked = false;
  Map<String, dynamic>? _attendanceData;
  MobileScannerController? _scannerController;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
    );
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    super.dispose();
  }

  Future<void> _handleQRScan(String qrData) async {
    if (_isProcessing || _marked) return;

    setState(() => _isProcessing = true);

    try {
      // Parse JSON QR to extract token
      String token;
      try {
        final qrJson = jsonDecode(qrData);
        token = qrJson['token'];
      } catch (_) {
        token = qrData;
      }

      final response = await ApiService.markAttendance(
        token: token,
        studentId: SessionManager.studentId!,
      );

      setState(() {
        _marked = true;
        _attendanceData = response;
      });

      _showSuccess();
    } on ApiException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('Invalid QR code or session expired');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A2332),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF00D9FF).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                size: 64,
                color: Color(0xFF00D9FF),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Attendance Marked!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (_attendanceData != null) ...[
              Text(
                _attendanceData!['subject_name'] ?? '',
                style: const TextStyle(color: Color(0xFF00D9FF), fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                DateTime.now().toString().substring(0, 16),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00D9FF),
                  foregroundColor: const Color(0xFF0F1419),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1419),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Mark Attendance'),
      ),
      body: Stack(
        children: [
          // QR Scanner
          if (!_marked)
            MobileScanner(
              controller: _scannerController,
              onDetect: (capture) {
                final barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  if (barcode.rawValue != null) {
                    _handleQRScan(barcode.rawValue!);
                    break;
                  }
                }
              },
            ),

          // Scanning frame
          if (!_marked)
            Center(
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF00D9FF), width: 3),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),

          // Instructions
          if (!_marked)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF16213E).withOpacity(0.95),
                      const Color(0xFF0F3460).withOpacity(0.95),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00D9FF).withOpacity(0.3),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.qr_code_scanner,
                      size: 48,
                      color: Color(0xFF00D9FF),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Scan Attendance QR',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Point your camera at the QR code displayed by your faculty',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

          // Processing overlay
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF00D9FF)),
                    SizedBox(height: 20),
                    Text(
                      'Marking Attendance...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
