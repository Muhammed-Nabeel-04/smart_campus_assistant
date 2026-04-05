// File: lib/screens/principal/principal_generate_hod_qr_screen.dart
// Principal generates a secure, time-limited token for HOD onboarding

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../services/api_service.dart';

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

  @override
  void initState() {
    super.initState();
    _generateQR();
  }

  Future<void> _generateQR() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
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
