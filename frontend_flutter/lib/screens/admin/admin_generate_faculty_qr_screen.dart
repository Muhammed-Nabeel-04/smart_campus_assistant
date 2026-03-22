// File: lib/screens/admin/admin_generate_faculty_qr_screen.dart
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:async';
import 'dart:convert';
import '../../core/app_colors.dart';
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
  int _secondsRemaining = 60; // 1 minutes
  Timer? _timer;
  bool _isLoading = true;
  bool _isExpired = false;

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
        widget.faculty['id'], // ✅ Real API
      );

      if (mounted) {
        // ✅ FIX: Encode as JSON so faculty scanner can find both faculty_id and token
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
          SnackBar(content: Text(e.message), backgroundColor: AppColors.danger),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
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

  Color _getTimerColor() {
    if (_secondsRemaining > 30) return AppColors.success;
    if (_secondsRemaining > 10) return AppColors.warning;
    return AppColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(title: const Text('Generate Faculty QR')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Faculty Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: const Color(0xFF1565C0),
                          child: Text(
                            widget.faculty['name'].toString().substring(0, 1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.faculty['name'],
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                widget.faculty['email'],
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  if (_isExpired) _buildExpiredState() else _buildQRState(),
                ],
              ),
            ),
    );
  }

  Widget _buildQRState() {
    return Column(
      children: [
        // Timer
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: _getTimerColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _getTimerColor()),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.timer, color: _getTimerColor(), size: 20),
              const SizedBox(width: 8),
              Text(
                'Expires in ${_formatTime(_secondsRemaining)}',
                style: TextStyle(
                  color: _getTimerColor(),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // QR Code
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: QrImageView(
            data: _qrToken ?? '',
            version: QrVersions.auto,
            size: 280,
          ),
        ),

        const SizedBox(height: 24),

        // Instructions
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.info_outline, color: AppColors.info, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Instructions',
                    style: TextStyle(
                      color: AppColors.info,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildInstruction('Faculty scans this QR code'),
              _buildInstruction('Faculty sets up password'),
              _buildInstruction('QR expires in 5 minutes'),
              _buildInstruction('One-time use only'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExpiredState() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.danger.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.danger),
          ),
          child: Column(
            children: const [
              Icon(Icons.error_outline, color: AppColors.danger, size: 64),
              SizedBox(height: 16),
              Text(
                'QR Code Expired',
                style: TextStyle(
                  color: AppColors.danger,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'This QR code has expired. Generate a new one.',
                style: TextStyle(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _generateQR,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            icon: const Icon(Icons.refresh),
            label: const Text('Generate New QR'),
          ),
        ),
      ],
    );
  }

  Widget _buildInstruction(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.success, size: 16),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
