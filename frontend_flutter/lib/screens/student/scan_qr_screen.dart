// lib/screens/student/scan_qr_screen.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/session.dart';
import '../../services/api_service.dart';

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
    final cs = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: cs.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (isError ? cs.error : cs.primary).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isError
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_rounded,
                size: 52,
                color: isError ? cs.error : cs.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurface, fontSize: 15),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                ),
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
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Scan Attendance QR'),
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
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
                border: Border.all(color: cs.primary, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  _corner(Alignment.topLeft, cs.primary),
                  _corner(Alignment.topRight, cs.primary),
                  _corner(Alignment.bottomLeft, cs.primary),
                  _corner(Alignment.bottomRight, cs.primary),
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
                color: cs.surface.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withOpacity(0.25),
                    blurRadius: 24,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.qr_code_scanner_rounded,
                    size: 44,
                    color: cs.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Point camera at the QR code',
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Make sure the QR fits inside the frame',
                    style: TextStyle(
                      color: cs.onSurface.withOpacity(0.6),
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
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: cs.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Processing...',
                      style: TextStyle(color: cs.onPrimary),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _corner(Alignment alignment, Color color) {
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
                ? BorderSide(color: color, width: 4)
                : BorderSide.none,
            bottom:
                (alignment == Alignment.bottomLeft ||
                    alignment == Alignment.bottomRight)
                ? BorderSide(color: color, width: 4)
                : BorderSide.none,
            left:
                (alignment == Alignment.topLeft ||
                    alignment == Alignment.bottomLeft)
                ? BorderSide(color: color, width: 4)
                : BorderSide.none,
            right:
                (alignment == Alignment.topRight ||
                    alignment == Alignment.bottomRight)
                ? BorderSide(color: color, width: 4)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
