// File: lib/screens/faculty/faculty_start_attendance_screen.dart
// Live attendance session with rotating QR code
// BUG 7 FIX: _rotateToken() now calls backend to get a real new token
// instead of generating a fake client-side token that backend never knows about.

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:async';
import 'dart:convert';
import '../../services/api_service.dart';
import '../../core/app_colors.dart';

class FacultyStartAttendanceScreen extends StatefulWidget {
  final Map<String, dynamic> department;
  final Map<String, dynamic> classData;
  final Map<String, dynamic> subject;
  final String semester;

  const FacultyStartAttendanceScreen({
    super.key,
    required this.department,
    required this.classData,
    required this.subject,
    required this.semester,
  });

  @override
  State<FacultyStartAttendanceScreen> createState() =>
      _FacultyStartAttendanceScreenState();
}

class _FacultyStartAttendanceScreenState
    extends State<FacultyStartAttendanceScreen> {
  int? _sessionId;
  String? _currentToken;
  bool _isLoading = true;
  bool _isActive = false;
  bool _isRefreshing = false;
  int _sessionDuration = 0;
  int _studentsPresent = 0;
  List<Map<String, dynamic>> _presentStudents = [];

  Timer? _qrTimer;
  Timer? _durationTimer;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  @override
  void dispose() {
    _qrTimer?.cancel();
    _durationTimer?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _startSession() async {
    setState(() => _isLoading = true);

    try {
      final response = await ApiService.startAttendanceSession(
        classId: widget.classData['id'],
        subjectId: widget.subject['id'],
      );

      setState(() {
        _sessionId = response['session_id'];
        _currentToken = response['token'];
        _isActive = true;
        _isLoading = false;
      });

      _startTimers();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.danger,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  void _startTimers() {
    // Rotate QR every 3 seconds by fetching a new token from backend
    _qrTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted && _isActive) {
        _rotateToken();
      }
    });

    // Update session duration every second
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _isActive) {
        setState(() => _sessionDuration++);
      }
    });

    // Poll for attendance updates every 5 seconds
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted && _isActive) {
        _fetchAttendance();
      }
    });
  }

  // BUG 7 FIX: Call backend to generate a new token and save it to DB.
  // Previously this made up a fake token locally that backend never stored,
  // so any student scanning the rotated QR would get "invalid token" error.
  Future<void> _rotateToken() async {
    if (_sessionId == null || _isRefreshing) return;
    _isRefreshing = true;

    try {
      final response = await ApiService.refreshAttendanceToken(_sessionId!);
      if (mounted) {
        setState(() => _currentToken = response['token']);
      }
    } catch (_) {
      // Silent fail — keep showing current token if refresh fails
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> _fetchAttendance() async {
    if (_sessionId == null) return;

    try {
      final data = await ApiService.getSessionAttendance(_sessionId!);
      if (mounted) {
        setState(() {
          _presentStudents = List<Map<String, dynamic>>.from(data);
          _studentsPresent = _presentStudents.length;
        });
      }
    } catch (e) {
      // Silent fail for polling
    }
  }

  Future<void> _endSession() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'End Session?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to end this attendance session?\n\n$_studentsPresent students marked present.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('End Session'),
          ),
        ],
      ),
    );

    if (confirm == true && _sessionId != null) {
      _qrTimer?.cancel();
      _durationTimer?.cancel();
      _pollTimer?.cancel();

      try {
        await ApiService.endAttendanceSession(_sessionId!);
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to end session'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  String get _durationDisplay {
    final hours = _sessionDuration ~/ 3600;
    final minutes = (_sessionDuration % 3600) ~/ 60;
    final seconds = _sessionDuration % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgCard,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.subject['name'] ?? 'Attendance',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              '${widget.classData['year']} - Section ${widget.classData['section']}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1565C0)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Session Status Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(
                              Icons.people,
                              'Present',
                              '$_studentsPresent',
                            ),
                            _buildStatItem(
                              Icons.timer,
                              'Duration',
                              _durationDisplay,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.success,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Session Active',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // QR Code
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1565C0).withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        if (_currentToken != null)
                          QrImageView(
                            data: jsonEncode({
                              'session_id': _sessionId,
                              'token': _currentToken,
                              'type': 'attendance',
                            }),
                            version: QrVersions.auto,
                            size: 280,
                            backgroundColor: Colors.white,
                          )
                        else
                          const SizedBox(
                            height: 280,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.autorenew,
                              color: Color(0xFF1565C0),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'QR rotates every 3 seconds',
                              style: TextStyle(
                                color: Color(0xFF1565C0),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Instructions
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.info.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.info,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Students scan this QR to mark attendance',
                            style: TextStyle(
                              color: AppColors.info,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Present Students List
                  if (_presentStudents.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.success,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Students Present ($_studentsPresent)',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._presentStudents.map(
                      (student) => _buildStudentTile(student),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // End Session Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _endSession,
                      icon: const Icon(Icons.stop_circle),
                      label: const Text(
                        'End Session',
                        style: TextStyle(
                          fontSize: 18,
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

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildStudentTile(Map<String, dynamic> student) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.success, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student['full_name'] ?? student['name'] ?? 'Student',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  student['register_number'] ?? '',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            student['timestamp'] ?? student['time'] ?? '',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
