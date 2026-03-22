// File: lib/screens/admin/admin_generate_faculty_qr_screen.dart
// Admin generates a secure, one-time JSON QR for faculty onboarding

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:async';
import 'dart:convert';
import '../../services/api_service.dart';

class AdminGenerateFacultyQRScreen extends StatefulWidget {
  final Map<String, dynamic> faculty;

  const AdminGenerateFacultyQRScreen({super.key, required this.faculty});

  @override
  State<AdminGenerateFacultyQRScreen> createState() =>
      _AdminGenerateFacultyQRScreenState();
}

class _AdminGenerateFacultyQRScreenState
    extends State<AdminGenerateFacultyQRScreen> {
  String? _qrToken;
  int _secondsRemaining = 60;
  Timer? _timer;
  bool _isLoading = true;
  bool _isExpired = false;

  // Fixed semantic colors for status/timer
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
    super.dispose();
  }

  Future<void> _generateQR() async {
    setState(() {
      _isLoading = true;
      _isExpired = false;
      _secondsRemaining = 60;
    });

    try {
      final response = await ApiService.generateAdminFacultyQR(
        widget.faculty['id'],
      );

      if (mounted) {
        // Encode as JSON so the faculty scanner app can parse both fields
        final qrData = jsonEncode({
          'faculty_id': widget.faculty['id'],
          'token': response['token'],
        });
        setState(() {
          _qrToken = qrData;
          _secondsRemaining = response['expires_in'] ?? 60;
          _isLoading = false;
        });
        _startTimer();
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _isExpired = true;
          timer.cancel();
        }
      });
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Color _getTimerColor(ColorScheme cs) {
    if (_secondsRemaining > 30) return successGreen;
    if (_secondsRemaining > 10) return warningOrange;
    return cs.error;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Faculty Setup QR')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: cs.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Faculty Info Summary
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cs.onSurface.withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: cs.primary.withOpacity(0.1),
                          child: Text(
                            widget.faculty['name']
                                .toString()
                                .substring(0, 1)
                                .toUpperCase(),
                            style: TextStyle(
                              color: cs.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.faculty['name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                widget.faculty['email'],
                                style: TextStyle(
                                  color: cs.onSurface.withOpacity(0.6),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  if (_isExpired) _buildExpiredState(cs) else _buildQRState(cs),
                ],
              ),
            ),
    );
  }

  Widget _buildQRState(ColorScheme cs) {
    final timerColor = _getTimerColor(cs);

    return Column(
      children: [
        // Timer Widget
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: timerColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: timerColor.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.timer_outlined, color: timerColor, size: 20),
              const SizedBox(width: 10),
              Text(
                'Expires in ${_formatTime(_secondsRemaining)}',
                style: TextStyle(
                  color: timerColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // QR Code Container
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: cs.primary.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: QrImageView(
            data: _qrToken ?? '',
            version: QrVersions.auto,
            size: 260,
            backgroundColor: Colors.white,
            eyeStyle: QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: cs.primary,
            ),
          ),
        ),

        const SizedBox(height: 32),

        // Help Instructions
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.onSurface.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.info_outline, color: infoBlue, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Onboarding Steps',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildInstruction(
                '1. Faculty opens app and chooses "Onboard"',
                cs,
              ),
              _buildInstruction('2. Faculty scans this QR code', cs),
              _buildInstruction('3. QR expires in 1 min for security', cs),
              _buildInstruction('4. One-time setup only', cs),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExpiredState(ColorScheme cs) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cs.error.withOpacity(0.3), width: 2),
          ),
          child: Column(
            children: [
              Icon(Icons.timer_off_outlined, color: cs.error, size: 64),
              const SizedBox(height: 20),
              const Text(
                'QR Code Expired',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              const SizedBox(height: 8),
              Text(
                'For security reasons, this token has expired.',
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurface.withOpacity(0.6)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _generateQR,
            icon: const Icon(Icons.refresh),
            label: const Text('Generate New QR'),
          ),
        ),
      ],
    );
  }

  Widget _buildInstruction(String text, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: successGreen, size: 16),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: cs.onSurface.withOpacity(0.7),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
