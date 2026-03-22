// File: lib/screens/admin/hod_qr_onboarding_screen.dart
// HOD scans Principal-generated QR for first-time secure onboarding

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/api_service.dart';

class HODQROnboardingScreen extends StatefulWidget {
  const HODQROnboardingScreen({super.key});

  @override
  State<HODQROnboardingScreen> createState() => _HODQROnboardingScreenState();
}

class _HODQROnboardingScreenState extends State<HODQROnboardingScreen> {
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
      // Token is the raw QR data string from Principal
      final response = await ApiService.validateHODQR(qrData.trim());

      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/hodPasswordSetup',
          arguments: response,
        );
      }
    } on ApiException catch (e) {
      if (mounted) _showError(e.message);
    } catch (e) {
      if (mounted) _showError('Invalid QR code or connection error');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
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
        title: const Text('HOD Onboarding'),
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
                  _buildCorner(Alignment.topLeft, cs.primary),
                  _buildCorner(Alignment.topRight, cs.primary),
                  _buildCorner(Alignment.bottomLeft, cs.primary),
                  _buildCorner(Alignment.bottomRight, cs.primary),
                ],
              ),
            ),
          ),

          // Bottom UI Card
          SafeArea(
            child: Column(
              children: [
                const Spacer(),
                Container(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: cs.surface.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(24),
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
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cs.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.qr_code_scanner_rounded,
                          size: 48,
                          color: cs.primary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Secure Setup',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Scan the unique QR code provided by the Principal to authorize your HOD account.',
                        style: TextStyle(
                          fontSize: 14,
                          color: cs.onSurface.withOpacity(0.6),
                        ),
                        textAlign: TextAlign.center,
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
                      'Verifying Authorization...',
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

  Widget _buildCorner(Alignment alignment, Color color) {
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
