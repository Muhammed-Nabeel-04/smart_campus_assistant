// File: lib/screens/principal/principal_generate_hod_qr_screen.dart
// Principal generates a secure, time-limited token for HOD onboarding

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:async';
import '../../services/api_service.dart';
import '../../core/notification_service.dart';

class PrincipalGenerateHODQRScreen extends StatefulWidget {
  final Map<String, dynamic> hod;
  const PrincipalGenerateHODQRScreen({super.key, required this.hod});

  @override
  State<PrincipalGenerateHODQRScreen> createState() =>
      _PrincipalGenerateHODQRScreenState();
}

class _PrincipalGenerateHODQRScreenState
    extends State<PrincipalGenerateHODQRScreen> {
  bool _isLoading = false;
  String? _qrData;
  String? _error;
  int _expiresIn = 60; // seconds — matches backend 1-minute expiry
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
      _error = null;
      _isUsed = false;
      _usedByName = null;
    });

    _timer?.cancel();
    _statusTimer?.cancel();

    try {
      final res = await ApiService.generateHODQR(widget.hod['id']);
      if (mounted) {
        setState(() {
          // Token string to be scanned by the HOD onboarding screen
          _qrData = res['token'];
          _expiresIn = res['expires_in_minutes'] != null
              ? (res['expires_in_minutes'] as int) * 60
              : 300;
          _isLoading = false;
        });
        _startTimer();
        _startStatusPolling();
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _isLoading = false;
        });
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_expiresIn > 0) {
          _expiresIn--;
        } else {
          timer.cancel();
          _statusTimer?.cancel();
        }
      });
    });
  }

  void _startStatusPolling() {
    if (_qrData == null) return;
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!mounted || _isUsed || _qrData == null || _expiresIn <= 0) {
        timer.cancel();
        return;
      }

      try {
        final status = await ApiService.getOnboardingStatus(_qrData!);
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
              title: '✅ HOD Onboarded',
              body:
                  'HOD ${_usedByName ?? widget.hod['name']} has completed onboarding.',
            );
            _showSuccessDialog();
          }
        }
      } catch (e) {
        debugPrint('Error polling HOD onboarding status: $e');
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
          'HOD ${_usedByName ?? widget.hod['name']} has completed onboarding successfully.',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to HOD management
            },
            child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('HOD Onboarding QR')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _isLoading
              ? CircularProgressIndicator(color: cs.primary)
              : _error != null
                  ? _buildErrorState(cs)
                  : _buildQRContent(cs),
        ),
      ),
    );
  }

  Widget _buildQRContent(ColorScheme cs) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          widget.hod['name'] ?? 'HOD',
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.hod['department_name'] ?? 'Department',
          style: TextStyle(color: cs.onSurface.withOpacity(0.6), fontSize: 14),
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
            data: _qrData ?? '',
            version: QrVersions.auto,
            size: 240,
            eyeStyle: QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: cs.primary,
            ),
          ),
        ),

        const SizedBox(height: 32),

        // Expiry Warning
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.timer_outlined, color: Colors.orange, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'This QR code is valid for setup only. HOD must scan this now to authorize their account.',
                  style: TextStyle(
                    color: Colors.orange.shade800,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        OutlinedButton.icon(
          onPressed: _generateQR,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Regenerate Token'),
          style: OutlinedButton.styleFrom(
            foregroundColor: cs.primary,
            side: BorderSide(color: cs.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(ColorScheme cs) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline_rounded, color: cs.error, size: 64),
        const SizedBox(height: 16),
        Text(
          _error!,
          style: TextStyle(color: cs.error, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _generateQR,
          child: const Text('Retry Generation'),
        ),
      ],
    );
  }
}
