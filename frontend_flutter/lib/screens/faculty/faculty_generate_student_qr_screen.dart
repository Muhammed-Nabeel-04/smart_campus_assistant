// File: lib/screens/faculty/faculty_generate_student_qr_screen.dart
// Generate one-time login QR for student with expiry timer

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:async';
import 'dart:convert';
import '../../services/api_service.dart';
import '../../core/app_colors.dart';

class FacultyGenerateStudentQRScreen extends StatefulWidget {
  final Map<String, dynamic> student;

  const FacultyGenerateStudentQRScreen({super.key, required this.student});

  @override
  State<FacultyGenerateStudentQRScreen> createState() =>
      _FacultyGenerateStudentQRScreenState();
}

class _FacultyGenerateStudentQRScreenState
    extends State<FacultyGenerateStudentQRScreen> {
  String? _qrData;
  String? _token;
  bool _isLoading = true;
  bool _isExpired = false;
  int _remainingSeconds = 300; // 5 minutes
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _generateQR();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _generateQR() async {
    setState(() {
      _isLoading = true;
      _isExpired = false;
      _remainingSeconds = 300;
    });

    _timer?.cancel();

    try {
      final response = await ApiService.generateStudentQR(widget.student['id']);

      final qrPayload = {
        'student_id': widget.student['id'],
        'token': response['token'],
        'type': 'student_login',
      };

      setState(() {
        _token = response['token'];
        _qrData = jsonEncode(qrPayload);
        _isLoading = false;
      });

      _startTimer();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to generate QR code'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _isExpired = true;
          timer.cancel();
        }
      });
    });
  }

  String get _timeDisplay {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgCard,
        elevation: 0,
        title: const Text('Generate Student QR'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1565C0)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Student Info Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1565C0).withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              widget.student['full_name']
                                      ?.substring(0, 1)
                                      .toUpperCase() ??
                                  'S',
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.student['full_name'] ?? 'Student',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.student['register_number'] ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // QR Code or Expired Message
                  if (_isExpired) _buildExpiredState() else _buildQRCode(),

                  const SizedBox(height: 24),

                  // Timer
                  if (!_isExpired) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _remainingSeconds < 60
                            ? AppColors.danger.withOpacity(0.1)
                            : AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _remainingSeconds < 60
                              ? AppColors.danger
                              : AppColors.success,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.timer,
                            color: _remainingSeconds < 60
                                ? AppColors.danger
                                : AppColors.success,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Expires in: $_timeDisplay',
                            style: TextStyle(
                              color: _remainingSeconds < 60
                                  ? AppColors.danger
                                  : AppColors.success,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Instructions
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.info.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppColors.info,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Instructions',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildInstruction('1', 'Student opens the app'),
                        _buildInstruction('2', 'Scans this QR code'),
                        _buildInstruction('3', 'Sets up password (first time)'),
                        _buildInstruction('4', 'QR expires in 5 minutes'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Regenerate Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _generateQR,
                      icon: const Icon(Icons.refresh),
                      label: const Text(
                        'Regenerate QR Code',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  // Token Display (for backup)
                  if (_token != null) ...[
                    const SizedBox(height: 16),
                    ExpansionTile(
                      title: const Text(
                        'Show Token (Backup)',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      iconColor: AppColors.textSecondary,
                      collapsedIconColor: AppColors.textSecondary,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.bgCard,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SelectableText(
                            _token!,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildQRCode() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: QrImageView(
        data: _qrData!,
        version: QrVersions.auto,
        size: 280,
        backgroundColor: Colors.white,
        errorCorrectionLevel: QrErrorCorrectLevel.H,
      ),
    );
  }

  Widget _buildExpiredState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.danger, width: 2),
      ),
      child: Column(
        children: [
          Icon(Icons.timer_off, size: 80, color: AppColors.danger),
          const SizedBox(height: 20),
          const Text(
            'QR Code Expired',
            style: TextStyle(
              color: AppColors.danger,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This QR code has expired.\nPlease regenerate a new one.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInstruction(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.info,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: AppColors.info, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
