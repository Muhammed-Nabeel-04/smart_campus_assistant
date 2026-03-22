// File: lib/screens/faculty/faculty_start_attendance_screen.dart

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:async';
import 'dart:convert';
import '../../services/api_service.dart';

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
  bool _isLoading = false;
  bool _isActive = false;
  bool _isRefreshing = false;
  int _sessionDuration = 0;
  int _studentsPresent = 0;
  List<Map<String, dynamic>> _presentStudents = [];
  int? _durationMinutes;

  Timer? _qrTimer;
  Timer? _durationTimer;
  Timer? _pollTimer;

  // Fixed Role Colors
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color errorRed = Color(0xFFF44336);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startSession());
  }

  @override
  void dispose() {
    _qrTimer?.cancel();
    _durationTimer?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _startSession() async {
    final duration = await showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        int selected = 60;
        return StatefulBuilder(
          builder: (ctx, setS) => AlertDialog(
            backgroundColor: cs.surface,
            title: Text(
              'Set Class Duration',
              style: TextStyle(color: cs.onSurface),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'How long is this class?',
                  style: TextStyle(color: cs.onSurface.withOpacity(0.6)),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [30, 45, 60, 75, 90, 120]
                      .map(
                        (m) => ChoiceChip(
                          label: Text('$m min'),
                          selected: selected == m,
                          onSelected: (_) => setS(() => selected = m),
                          selectedColor: cs.primary,
                          labelStyle: TextStyle(
                            color: selected == m ? cs.onPrimary : cs.onSurface,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, null),
                child: const Text('No Limit'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, selected),
                child: const Text('Start'),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted) return;
    _durationMinutes = duration;
    setState(() => _isLoading = true);

    try {
      final response = await ApiService.startAttendanceSession(
        classId: widget.classData['id'],
        subjectId: widget.subject['id'],
        durationMinutes: _durationMinutes,
      );

      final isExisting = response['is_existing'] == true;
      final isSameFaculty = response['is_same_faculty'] == true;
      final startedBy = response['started_by'] ?? 'Another faculty';

      if (isExisting && !isSameFaculty && mounted) {
        showDialog(
          context: context,
          builder: (ctx) {
            final cs = Theme.of(ctx).colorScheme;
            return AlertDialog(
              backgroundColor: cs.surface,
              title: const Text('Class Already Ongoing'),
              content: Text(
                '$startedBy is currently taking this class.\nYou cannot start another session.',
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: cs.error),
                  child: const Text(
                    'OK',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
        setState(() => _isLoading = false);
        return;
      }

      if (isExisting && isSameFaculty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rejoining your active session'),
            backgroundColor: Color(0xFFFF9800), // Warning
          ),
        );
      }

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
            backgroundColor: errorRed,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  void _startTimers() {
    _qrTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted && _isActive) _rotateToken();
    });

    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _isActive) {
        setState(() => _sessionDuration++);
        if (_durationMinutes != null &&
            _sessionDuration >= _durationMinutes! * 60) {
          _autoEndSession();
        }
      }
    });

    _pollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted && _isActive) _fetchAttendance();
    });
  }

  Future<void> _rotateToken() async {
    if (_sessionId == null || _isRefreshing) return;
    _isRefreshing = true;
    try {
      final response = await ApiService.refreshAttendanceToken(_sessionId!);
      if (mounted) setState(() => _currentToken = response['token']);
    } catch (_) {
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
    } catch (_) {}
  }

  Future<void> _autoEndSession() async {
    _qrTimer?.cancel();
    _durationTimer?.cancel();
    _pollTimer?.cancel();
    if (_sessionId != null) {
      await ApiService.endAttendanceSession(_sessionId!);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Class time ended. Session closed automatically.'),
          backgroundColor: successGreen,
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _endSession() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return AlertDialog(
          backgroundColor: cs.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('End Session?'),
          content: Text(
            'Are you sure you want to end this attendance session?\n\n$_studentsPresent students marked present.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: TextStyle(color: cs.onSurface.withOpacity(0.6)),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: cs.error),
              child: const Text(
                'End Session',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true && _sessionId != null) {
      _qrTimer?.cancel();
      _durationTimer?.cancel();
      _pollTimer?.cancel();
      try {
        await ApiService.endAttendanceSession(_sessionId!);
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to end session'),
              backgroundColor: errorRed,
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
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.subject['name'] ?? 'Attendance',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              '${widget.classData['year']} - Section ${widget.classData['section']}',
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: cs.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Session Status Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cs.primary,
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
                              cs,
                            ),
                            _buildStatItem(
                              Icons.timer,
                              'Duration',
                              _durationDisplay,
                              cs,
                            ),
                            if (_durationMinutes != null)
                              _buildStatItem(
                                Icons.hourglass_bottom,
                                'Limit',
                                '$_durationMinutes min',
                                cs,
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
                            color: cs.onPrimary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: successGreen,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Session Active',
                                style: TextStyle(
                                  color: cs.onPrimary,
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
                          color: cs.primary.withOpacity(0.2),
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
                            Icon(Icons.autorenew, color: cs.primary, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'QR rotates every 3 seconds',
                              style: TextStyle(
                                color: cs.primary,
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
                      color: const Color(0xFF2196F3).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF2196F3).withOpacity(0.3),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Color(0xFF2196F3),
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Students scan this QR to mark attendance',
                            style: TextStyle(
                              color: Color(0xFF2196F3),
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
                          color: successGreen,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Students Present ($_studentsPresent)',
                          style: TextStyle(
                            color: cs.onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._presentStudents.map(
                      (student) => _buildStudentTile(student, cs),
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
                        backgroundColor: cs.error,
                        foregroundColor: cs.onError,
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

  Widget _buildStatItem(
    IconData icon,
    String label,
    String value,
    ColorScheme cs,
  ) {
    return Column(
      children: [
        Icon(icon, color: cs.onPrimary, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: cs.onPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: cs.onPrimary.withOpacity(0.8), fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildStudentTile(Map<String, dynamic> student, ColorScheme cs) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.onSurface.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: successGreen, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student['full_name'] ?? student['name'] ?? 'Student',
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  student['register_number'] ?? '',
                  style: TextStyle(
                    color: cs.onSurface.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            student['timestamp'] ?? student['time'] ?? '',
            style: TextStyle(
              color: cs.onSurface.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
