// File: lib/screens/faculty/faculty_generate_student_qr_screen.dart
// Generate one-time login QR for student with expiry timer

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:async';
import 'dart:convert';
import '../../services/api_service.dart';
import '../../core/notification_service.dart';

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
  int _remainingSeconds = 60;
  Timer? _timer;
  Timer? _statusTimer;
  bool _isUsed = false;
  String? _usedByName;

  // Fixed role/status colors - matching AdminGenerateFacultyQRScreen
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color infoBlue = Color(0xFF2196F3);

  @override
  void initState() {
    super.initState();
    _generateQR();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _statusTimer?.cancel();
    super.dispose();
  }

  Future<void> _generateQR() async {
    setState(() {
      _isLoading = true;
      _isExpired = false;
      _isUsed = false;
      _usedByName = null;
      _remainingSeconds = 60;
    });

    _timer?.cancel();
    _statusTimer?.cancel();

    try {
      final response = await ApiService.generateStudentQR(widget.student['id']);

      if (mounted) {
        _token = response['token'];
        final qrPayload = {
          'student_id': widget.student['id'],
          'token': _token,
          'type': 'student_login',
        };

        setState(() {
          _qrData = jsonEncode(qrPayload);
          _remainingSeconds = response['expires_in'] ?? 60;
          _isLoading = false;
        });

        _startTimer();
        _startStatusPolling();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to generate QR code'),
            backgroundColor: Color(0xFFF44336),
          ),
        );
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _isExpired = true;
          timer.cancel();
          _statusTimer?.cancel();
        }
      });
    });
  }

  void _startStatusPolling() {
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!mounted || _isExpired || _isUsed || _token == null) {
        timer.cancel();
        return;
      }

      try {
        final status = await ApiService.getOnboardingStatus(_token!);
        if (status['used'] == true) {
          timer.cancel();
          _timer?.cancel();
          if (mounted) {
            setState(() {
              _isUsed = true;
              _usedByName = status['used_by_name'];
            });
            // Show system notification
            NotificationService.showNotification(
              id: DateTime.now().millisecondsSinceEpoch,
              title: '✅ Student Logged In',
              body:
                  '${_usedByName ?? widget.student['full_name']} has logged in via QR.',
            );
            _showSuccessDialog();
          }
        }
      } catch (e) {
        debugPrint('Error polling student onboarding status: $e');
      }
    });
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: successGreen, size: 30),
            SizedBox(width: 10),
            Text('Success!'),
          ],
        ),
        content: Text(
          'Student ${_usedByName ?? widget.student['full_name']} has completed onboarding successfully.',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to student management
            },
            child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  String get _timeDisplay {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Generate Student QR')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: cs.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Student Info Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: cs.primary.withOpacity(0.3),
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
                            color: cs.onPrimary.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: cs.onPrimary, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              widget.student['full_name']
                                      ?.substring(0, 1)
                                      .toUpperCase() ??
                                  'S',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: cs.onPrimary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.student['full_name'] ?? 'Student',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: cs.onPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.student['register_number'] ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            color: cs.onPrimary.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // QR Code or Expired Message
                  if (_isExpired) _buildExpiredState(cs) else _buildQRCode(cs),

                  const SizedBox(height: 24),

                  // Timer
                  if (!_isExpired) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color:
                            (_remainingSeconds < 30 ? errorRed : successGreen)
                                .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _remainingSeconds < 30
                              ? errorRed
                              : successGreen,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.timer,
                            color: _remainingSeconds < 30
                                ? errorRed
                                : successGreen,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Expires in: $_timeDisplay',
                            style: TextStyle(
                              color: _remainingSeconds < 30
                                  ? errorRed
                                  : successGreen,
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
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cs.onSurface.withOpacity(0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: infoBlue,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Instructions',
                              style: TextStyle(
                                color: cs.onSurface,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildInstruction(
                          '1',
                          'Student opens the campus app',
                          cs,
                        ),
                        _buildInstruction(
                          '2',
                          'Student selects Login via QR',
                          cs,
                        ),
                        _buildInstruction('3', 'Scans this QR code', cs),
                        _buildInstruction(
                          '4',
                          'QR expires in 1 minute for security',
                          cs,
                        ),
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
                    ),
                  ),

                  // Token Display (for backup)
                  if (_token != null) ...[
                    const SizedBox(height: 16),
                    ExpansionTile(
                      title: Text(
                        'Show Backup Token',
                        style: TextStyle(
                          color: cs.onSurface.withOpacity(0.5),
                          fontSize: 14,
                        ),
                      ),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: cs.onSurface.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SelectableText(
                            _token!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: cs.onSurface,
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

  Widget _buildQRCode(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withOpacity(0.3),
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

  Widget _buildExpiredState(ColorScheme cs) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: errorRed.withOpacity(0.5), width: 2),
      ),
      child: Column(
        children: [
          const Icon(Icons.timer_off_outlined, size: 80, color: errorRed),
          const SizedBox(height: 20),
          const Text(
            'QR Code Expired',
            style: TextStyle(
              color: errorRed,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This login QR has expired.\nPlease regenerate a new one.',
            style: TextStyle(
              color: cs.onSurface.withOpacity(0.6),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInstruction(String number, String text, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: infoBlue,
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
              style: TextStyle(
                color: cs.onSurface.withOpacity(0.8),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
