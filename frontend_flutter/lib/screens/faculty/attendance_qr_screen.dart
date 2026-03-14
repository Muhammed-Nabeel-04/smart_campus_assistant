import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/session.dart';
import '../../core/app_colors.dart';
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
        // QR data = token string — student scans this
        qrData = token;
        _isLoading = false;
      });

      // Start live session timer
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
            backgroundColor: AppColors.danger,
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

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End Session?'),
        content: const Text(
          'Students will no longer be able to mark attendance.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('End Session'),
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
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.danger),
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
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        title: const Text('Attendance QR'),
        centerTitle: true,
        actions: [
          if (!_sessionEnded && sessionId != null)
            TextButton.icon(
              onPressed: _endSession,
              icon: const Icon(Icons.stop_circle_outlined, color: Colors.red),
              label: const Text('End', style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Class + subject info
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          subjectName,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          className,
                          style: TextStyle(
                            color: AppColors.textSecondary,
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
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: QrImageView(data: qrData!, size: 220),
                    )
                  else
                    const SizedBox(
                      height: 250,
                      child: Center(child: CircularProgressIndicator()),
                    ),

                  const SizedBox(height: 24),

                  // Timer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.timer_outlined, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        'Session Time: ${_formatTime(_seconds)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Session ID: $sessionId',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),

                  const Spacer(),

                  // End session button
                  if (!_sessionEnded)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
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
                          backgroundColor: AppColors.danger,
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
