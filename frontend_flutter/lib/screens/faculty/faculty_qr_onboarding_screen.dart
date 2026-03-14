// File: lib/screens/faculty/faculty_qr_onboarding_screen.dart
// Faculty scans admin-generated QR for first-time setup

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:convert';
import '../../services/api_service.dart';
import '../../core/app_colors.dart';

class FacultyQROnboardingScreen extends StatefulWidget {
  const FacultyQROnboardingScreen({super.key});

  @override
  State<FacultyQROnboardingScreen> createState() =>
      _FacultyQROnboardingScreenState();
}

class _FacultyQROnboardingScreenState extends State<FacultyQROnboardingScreen> {
  bool _isProcessing = false;
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
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final data = jsonDecode(qrData);

      // Validate QR structure
      if (!data.containsKey('faculty_id') || !data.containsKey('token')) {
        throw Exception('Invalid faculty onboarding QR code');
      }

      // Validate token with backend
      final response = await ApiService.validateFacultyQR(data['token']);

      // Navigate to password setup
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/facultyPasswordSetup',
          arguments: response,
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        _showError(e.message);
      }
    } catch (e) {
      if (mounted) {
        _showError('Invalid QR code or connection error');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Faculty Onboarding'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // QR Scanner
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

          // Overlay with instructions
          SafeArea(
            child: Column(
              children: [
                const Spacer(),

                // Bottom instruction card
                Container(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: AppColors.cardGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.qr_code_scanner,
                          size: 48,
                          color: AppColors.primary,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Title
                      const Text(
                        'Scan Faculty QR Code',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 12),

                      // Instructions
                      Text(
                        'Get your unique QR code from the admin to complete setup',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 20),

                      // Security badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.success.withOpacity(0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.verified_user,
                              size: 18,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Secure Setup',
                              style: TextStyle(
                                color: AppColors.success.withOpacity(0.2),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 20),
                    Text(
                      'Validating QR Code...',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Scanning frame
          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  _buildCornerDecoration(Alignment.topLeft),
                  _buildCornerDecoration(Alignment.topRight),
                  _buildCornerDecoration(Alignment.bottomLeft),
                  _buildCornerDecoration(Alignment.bottomRight),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCornerDecoration(Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          border: Border(
            top:
                alignment == Alignment.topLeft ||
                    alignment == Alignment.topRight
                ? const BorderSide(color: AppColors.primary, width: 4)
                : BorderSide.none,
            bottom:
                alignment == Alignment.bottomLeft ||
                    alignment == Alignment.bottomRight
                ? const BorderSide(color: AppColors.primary, width: 4)
                : BorderSide.none,
            left:
                alignment == Alignment.topLeft ||
                    alignment == Alignment.bottomLeft
                ? const BorderSide(color: AppColors.primary, width: 4)
                : BorderSide.none,
            right:
                alignment == Alignment.topRight ||
                    alignment == Alignment.bottomRight
                ? const BorderSide(color: AppColors.primary, width: 4)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
