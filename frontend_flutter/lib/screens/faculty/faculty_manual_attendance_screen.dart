// File: lib/screens/faculty/faculty_manual_attendance_screen.dart
// Manually mark attendance for a past date

import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../core/session.dart';

class FacultyManualAttendanceScreen extends StatefulWidget {
  final Map<String, dynamic> department;
  final Map<String, dynamic> classData;
  final Map<String, dynamic> subject;

  const FacultyManualAttendanceScreen({
    super.key,
    required this.department,
    required this.classData,
    required this.subject,
  });

  @override
  State<FacultyManualAttendanceScreen> createState() =>
      _FacultyManualAttendanceScreenState();
}

class _FacultyManualAttendanceScreenState
    extends State<FacultyManualAttendanceScreen> {
  List<Map<String, dynamic>> _students = [];
  Map<int, bool> _attendance = {}; // student_id -> present/absent
  bool _isLoading = true;
  bool _isSubmitting = false;
  final DateTime _selectedDate = DateTime.now();

  String? _noSessionMessage;

  // Fixed Role/Status Colors
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color errorRed = Color(0xFFF44336);
  static const Color warningOrange = Color(0xFFFF9800);

  @override
  void initState() {
    super.initState();
    _checkSessionAndLoad();
  }

  Future<void> _checkSessionAndLoad() async {
    setState(() => _isLoading = true);
    try {
      final sessions = await ApiService.getActiveSessions(
        SessionManager.facultyId!,
      );
      // Find active session for this class+subject
      final expectedClassName =
          '${widget.classData['year']} Sec ${widget.classData['section']}';
      final match = sessions.firstWhere(
        (s) =>
            s['subject_name'] == widget.subject['name'] &&
            s['class_name'] == expectedClassName,
        orElse: () => {},
      );
      if (match.isEmpty) {
        setState(() {
          _noSessionMessage =
              'No active session for ${widget.subject['name']}.\nStart a session first to mark attendance.';
          _isLoading = false;
        });
        return;
      }
      _loadStudents();
    } catch (e) {
      _loadStudents(); // fallback
    }
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);

    try {
      final data = await ApiService.getClassStudents(
        departmentId: widget.department['id'],
        year: widget.classData['year'],
        section: widget.classData['section'],
      );

      setState(() {
        _students = List<Map<String, dynamic>>.from(data);
        for (var student in _students) {
          _attendance[student['id']] = false;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _markAllPresent() {
    setState(() {
      for (var student in _students) {
        _attendance[student['id']] = true;
      }
    });
  }

  void _markAllAbsent() {
    setState(() {
      for (var student in _students) {
        _attendance[student['id']] = false;
      }
    });
  }

  Future<void> _submitAttendance() async {
    final cs = Theme.of(context).colorScheme;
    final presentCount = _attendance.values.where((v) => v).length;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cs.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Submit Attendance?',
          style: TextStyle(color: cs.onSurface),
        ),
        content: Text(
          'Mark attendance for ${widget.subject['name']} on ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}?\n\n'
          'Present: $presentCount\n'
          'Absent: ${_students.length - presentCount}',
          style: TextStyle(color: cs.onSurface.withOpacity(0.7)),
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
            style: ElevatedButton.styleFrom(backgroundColor: cs.primary),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSubmitting = true);

    try {
      final records = _students.map((student) {
        return {
          'student_id': student['id'],
          'status': _attendance[student['id']] == true ? 'present' : 'absent',
          'date': _selectedDate.toIso8601String().split('T')[0],
        };
      }).toList();

      await ApiService.submitManualAttendance(records);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attendance marked successfully'),
            backgroundColor: successGreen,
          ),
        );
        Navigator.pop(context);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final presentCount = _attendance.values.where((v) => v).length;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Manual Attendance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.subject['name'] ?? 'Subject',
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Stats Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border(
                bottom: BorderSide(color: cs.onSurface.withOpacity(0.05)),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'Present',
                        '$presentCount',
                        successGreen,
                        cs,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        'Absent',
                        '${_students.length - presentCount}',
                        errorRed,
                        cs,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _markAllPresent,
                        icon: const Icon(Icons.check_box, size: 18),
                        label: const Text('All Present'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: successGreen,
                          side: const BorderSide(color: successGreen),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _markAllAbsent,
                        icon: const Icon(Icons.cancel, size: 18),
                        label: const Text('All Absent'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: errorRed,
                          side: const BorderSide(color: errorRed),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Students List
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: cs.primary))
                : _noSessionMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_busy,
                            size: 64,
                            color: warningOrange.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _noSessionMessage!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: cs.onSurface.withOpacity(0.6),
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _students.length,
                    itemBuilder: (context, index) =>
                        _buildStudentTile(_students[index], cs),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting || _noSessionMessage != null
                  ? null
                  : _submitAttendance,
              icon: const Icon(Icons.cloud_upload_outlined),
              label: Text(
                _isSubmitting ? 'Submitting...' : 'Submit Attendance',
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    String label,
    String value,
    Color color,
    ColorScheme cs,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: cs.onSurface.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentTile(Map<String, dynamic> student, ColorScheme cs) {
    final isPresent = _attendance[student['id']] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPresent
              ? successGreen.withOpacity(0.3)
              : cs.onSurface.withOpacity(0.1),
        ),
      ),
      child: CheckboxListTile(
        value: isPresent,
        onChanged: (value) =>
            setState(() => _attendance[student['id']] = value ?? false),
        title: Text(
          student['full_name'] ?? 'Student',
          style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          student['register_number'] ?? '',
          style: TextStyle(color: cs.onSurface.withOpacity(0.6), fontSize: 12),
        ),
        secondary: CircleAvatar(
          backgroundColor: isPresent
              ? successGreen
              : cs.primary.withOpacity(0.1),
          child: Text(
            (student['full_name'] ?? 'S')
                .toString()
                .substring(0, 1)
                .toUpperCase(),
            style: TextStyle(
              color: isPresent ? Colors.white : cs.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        activeColor: successGreen,
        controlAffinity: ListTileControlAffinity.trailing,
      ),
    );
  }
}
