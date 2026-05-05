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
  bool _sessionStarted = false;

  int _seconds = 0;
  Timer? _sessionTimer;
  Timer? _pollingTimer;
  List<dynamic> _studentsPresent = [];

  // Passed via route arguments
  late int classId;
  late int subjectId;
  late String subjectName;
  late String className;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_sessionStarted) return;
    _sessionStarted = true;
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

      _startPolling();
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

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!mounted || _sessionEnded || sessionId == null) {
        timer.cancel();
        return;
      }

      try {
        final data = await ApiService.getSessionAttendance(sessionId!);
        if (mounted) {
          setState(() {
            _studentsPresent = data;
          });
        }
      } catch (e) {
        debugPrint("Error polling attendance: $e");
      }
    });
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
      _pollingTimer?.cancel();
      setState(() => _sessionEnded = true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session ended successfully'),
            backgroundColor: Color(0xFF4CAF50), // Fixed success green
          ),
        );
        // After ending, we show the final list in a new screen or dialog
        _showFinalAttendanceSummary();
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: cs.error),
        );
      }
    }
  }

  void _showFinalAttendanceSummary() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Text(
              "Final Attendance Summary",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
            ),
            Text("${_studentsPresent.length} Students Present", style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.separated(
                itemCount: _studentsPresent.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final s = _studentsPresent[index];
                  return ListTile(
                    leading: CircleAvatar(child: Text("${index + 1}")),
                    title: Text(s['full_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(s['register_number'] ?? ''),
                    trailing: const Icon(Icons.check_circle, color: Color(0xFF4CAF50)),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close bottom sheet
                  Navigator.pop(context); // Back to previous screen
                },
                child: const Text("Done"),
              ),
            )
          ],
        ),
      ),
    );
  }

  String _formatTime(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance QR'),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: cs.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
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

                  // Main Stack: QR + Live count overlay
                  Stack(
                    alignment: Alignment.center,
                    children: [
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
                        ),
                      
                      // Floating Student Counter
                      Positioned(
                        top: -10,
                        right: -10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: cs.primary,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.people, color: Colors.white, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                '${_studentsPresent.length}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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

                  const SizedBox(height: 24),

                  // Live Student List (Show one-by-one)
                  if (_studentsPresent.isNotEmpty) ...[
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Recently Joined:",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: cs.onSurface.withOpacity(0.05)),
                      ),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _studentsPresent.length,
                        reverse: true, // New names show at top
                        itemBuilder: (context, index) {
                          final s = _studentsPresent[index];
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)],
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.person, color: Color(0xFF4CAF50), size: 18),
                                const SizedBox(width: 10),
                                Expanded(child: Text(s['full_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w500))),
                                Text(s['timestamp'] ?? '', style: TextStyle(color: cs.onSurface.withOpacity(0.4), fontSize: 11)),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

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
