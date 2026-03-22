// File: lib/screens/faculty/faculty_qr_onboarding_screen.dart
// Faculty scans admin-generated QR for first-time setup

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:convert';
import '../../services/api_service.dart';

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
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: cs.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Faculty Onboarding'),
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
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
                    color: cs.surface.withOpacity(0.9),
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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cs.primary.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.qr_code_scanner,
                          size: 48,
                          color: cs.primary,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Title
                      Text(
                        'Scan Faculty QR Code',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 12),

                      // Instructions
                      Text(
                        'Get your unique QR code from the admin to complete setup',
                        style: TextStyle(
                          fontSize: 14,
                          color: cs.onSurface.withOpacity(0.7),
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
                          color: const Color(
                            0xFF4CAF50,
                          ).withOpacity(0.2), // Success Green
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF4CAF50).withOpacity(0.5),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified_user,
                              size: 18,
                              color: Color(0xFF4CAF50),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Secure Setup',
                              style: TextStyle(
                                color: Color(0xFF4CAF50),
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
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: cs.primary),
                    const SizedBox(height: 20),
                    const Text(
                      'Validating QR Code...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

          // Scanning frame overlay
          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                border: Border.all(color: cs.primary, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  _buildCornerDecoration(Alignment.topLeft, cs.primary),
                  _buildCornerDecoration(Alignment.topRight, cs.primary),
                  _buildCornerDecoration(Alignment.bottomLeft, cs.primary),
                  _buildCornerDecoration(Alignment.bottomRight, cs.primary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCornerDecoration(Alignment alignment, Color color) {
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
                ? BorderSide(color: color, width: 4)
                : BorderSide.none,
            bottom:
                alignment == Alignment.bottomLeft ||
                    alignment == Alignment.bottomRight
                ? BorderSide(color: color, width: 4)
                : BorderSide.none,
            left:
                alignment == Alignment.topLeft ||
                    alignment == Alignment.bottomLeft
                ? BorderSide(color: color, width: 4)
                : BorderSide.none,
            right:
                alignment == Alignment.topRight ||
                    alignment == Alignment.bottomRight
                ? BorderSide(color: color, width: 4)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
