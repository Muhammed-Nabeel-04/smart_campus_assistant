// lib/screens/principal/principal_generate_hod_qr_screen.dart
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/app_colors.dart';
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
  int _expiresIn = 600; // seconds

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
          // ✅ Build QR data from token
          _qrData = res['token'];
          _expiresIn = res['expires_in_minutes'] != null
              ? (res['expires_in_minutes'] as int) * 60
              : 300;
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted)
        setState(() {
          _error = e.message;
          _isLoading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(title: const Text('HOD Onboarding QR')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _isLoading
              ? const CircularProgressIndicator()
              : _error != null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.danger,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: const TextStyle(color: AppColors.danger),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _generateQR,
                      child: const Text('Retry'),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.hod['name'] ?? '',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.hod['department_name'] ?? '',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 32),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: QrImageView(
                        data: _qrData ?? '',
                        version: QrVersions.auto,
                        size: 220,
                      ),
                    ),

                    const SizedBox(height: 24),

                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.warning.withOpacity(0.3),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            color: AppColors.warning,
                            size: 18,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'QR expires in 10 minutes. HOD must scan this to set their password.',
                              style: TextStyle(
                                color: AppColors.warning,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    OutlinedButton.icon(
                      onPressed: _generateQR,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Regenerate QR'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1565C0),
                        side: const BorderSide(color: Color(0xFF1565C0)),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
