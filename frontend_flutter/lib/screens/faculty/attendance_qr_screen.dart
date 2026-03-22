// File: lib/screens/faculty/attendance_qr_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../services/api_service.dart';

class AttendanceQRScreen extends StatefulWidget {
  const AttendanceQRScreen({super.key});

  @override
  State<AttendanceQRScreen> createState() => _AttendanceQRScreenState();
}

class _AttendanceQRScreenState extends State<AttendanceQRScreen> {
  String? qrData;
  int? sessionId;
  bool _isLoading = true;
  bool _sessionEnded = false;

  int _seconds = 0;
  Timer? _sessionTimer;

  // Passed via route arguments
  late int classId;
  late int subjectId;
  late String subjectName;
  late String className;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    classId = args?['class_id'] ?? 0;
    subjectId = args?['subject_id'] ?? 0;
    subjectName = args?['subject_name'] ?? 'Subject';
    className = args?['class_name'] ?? 'Class';

    _startSession();
  }

  Future<void> _startSession() async {
    setState(() => _isLoading = true);

    try {
      final data = await ApiService.startAttendanceSession(
        classId: classId,
        subjectId: subjectId,
      );

      sessionId = data['session_id'];
      final token = data['token'];

      setState(() {
        qrData = token;
        _isLoading = false;
      });

      _sessionTimer?.cancel();
      _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) setState(() => _seconds++);
      });
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to start session: ${e.message}"),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Start session error: $e");
    }
  }

  Future<void> _endSession() async {
    if (sessionId == null) return;
    final cs = Theme.of(context).colorScheme;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surface,
        title: Text('End Session?', style: TextStyle(color: cs.onSurface)),
        content: Text(
          'Students will no longer be able to mark attendance.',
          style: TextStyle(color: cs.onSurface.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: cs.error),
            child: const Text(
              'End Session',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ApiService.endAttendanceSession(sessionId!);
      _sessionTimer?.cancel();
      setState(() => _sessionEnded = true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session ended successfully'),
            backgroundColor: Color(0xFF4CAF50), // Fixed success green
          ),
        );
        Navigator.pop(context);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: cs.error),
        );
      }
    }
  }

  String _formatTime(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance QR'),
        centerTitle: true,
        actions: [
          if (!_sessionEnded && sessionId != null)
            TextButton.icon(
              onPressed: _endSession,
              icon: Icon(Icons.stop_circle_outlined, color: cs.error),
              label: Text('End', style: TextStyle(color: cs.error)),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: cs.primary))
            : Column(
                children: [
                  // Info Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cs.onSurface.withOpacity(0.1)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          subjectName,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: cs.onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          className,
                          style: TextStyle(
                            color: cs.onSurface.withOpacity(0.6),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // QR Code
                  if (qrData != null)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: cs.primary.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: QrImageView(
                        data: qrData!,
                        size: 240,
                        backgroundColor: Colors.white,
                      ),
                    )
                  else
                    const SizedBox(
                      height: 280,
                      child: Center(child: CircularProgressIndicator()),
                    ),

                  const SizedBox(height: 32),

                  // Session Timer
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.timer_outlined,
                          color: Color(0xFF4CAF50),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Session Time: ${_formatTime(_seconds)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'Session ID: ${sessionId ?? "..."}',
                    style: TextStyle(
                      color: cs.onSurface.withOpacity(0.4),
                      fontSize: 12,
                    ),
                  ),

                  const Spacer(),

                  // End button
                  if (!_sessionEnded)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _endSession,
                        icon: const Icon(Icons.stop_circle_outlined),
                        label: const Text(
                          'End Session',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cs.error,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
