// lib/screens/student/scan_qr_screen.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/session.dart';
import '../../services/api_service.dart';
import '../../core/app_colors.dart';

class ScanQRScreen extends StatefulWidget {
  const ScanQRScreen({super.key});

  @override
  State<ScanQRScreen> createState() => _ScanQRScreenState();
}

class _ScanQRScreenState extends State<ScanQRScreen> {
  bool _isProcessing = false;
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _validateQR(String qrRawData) async {
    if (_isProcessing) return;

    if (SessionManager.studentId == null) {
      _showResult('Session missing. Please log in again.', isError: true);
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // ✅ QR data is now just the token string directly
      final data = await ApiService.markAttendance(
        token: qrRawData,
        studentId: SessionManager.studentId!,
      );

      if (mounted) {
        _showResult(
          'Attendance Marked ✓\n${data['message'] ?? ''}',
          isError: false,
        );
      }
    } on ApiException catch (e) {
      if (mounted) _showResult(e.message, isError: true);
    } catch (_) {
      if (mounted) _showResult('Invalid QR code', isError: true);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showResult(String message, {required bool isError}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (isError ? AppColors.danger : AppColors.primary)
                    .withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isError
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_rounded,
                size: 52,
                color: isError ? AppColors.danger : AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Scan Attendance QR'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // ── Camera ──────────────────────────────────────────
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (_isProcessing) return;
              for (final barcode in capture.barcodes) {
                if (barcode.rawValue != null) {
                  _validateQR(barcode.rawValue!);
                  break;
                }
              }
            },
          ),

          // ── Scan Frame ───────────────────────────────────────
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  _corner(Alignment.topLeft),
                  _corner(Alignment.topRight),
                  _corner(Alignment.bottomLeft),
                  _corner(Alignment.bottomRight),
                ],
              ),
            ),
          ),

          // ── Bottom Info Card ──────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: AppColors.cardGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.25),
                    blurRadius: 24,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.qr_code_scanner_rounded,
                    size: 44,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Point camera at the QR code',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Make sure the QR fits inside the frame',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Processing Overlay ────────────────────────────────
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.65),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 16),
                    Text(
                      'Processing...',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _corner(Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          border: Border(
            top:
                (alignment == Alignment.topLeft ||
                    alignment == Alignment.topRight)
                ? const BorderSide(color: AppColors.primary, width: 4)
                : BorderSide.none,
            bottom:
                (alignment == Alignment.bottomLeft ||
                    alignment == Alignment.bottomRight)
                ? const BorderSide(color: AppColors.primary, width: 4)
                : BorderSide.none,
            left:
                (alignment == Alignment.topLeft ||
                    alignment == Alignment.bottomLeft)
                ? const BorderSide(color: AppColors.primary, width: 4)
                : BorderSide.none,
            right:
                (alignment == Alignment.topRight ||
                    alignment == Alignment.bottomRight)
                ? const BorderSide(color: AppColors.primary, width: 4)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
