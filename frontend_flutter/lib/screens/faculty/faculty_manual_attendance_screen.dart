// File: lib/screens/faculty/faculty_manual_attendance_screen.dart
// Manually mark attendance for a past date

import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../core/app_colors.dart';

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
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadStudents();
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
        // Initialize all as absent
        for (var student in _students) {
          _attendance[student['id']] = false;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF1565C0),
              surface: AppColors.bgCard,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
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
    final presentCount = _attendance.values.where((v) => v).length;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Submit Attendance?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Mark attendance for ${widget.subject['name']} on ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}?\n\n'
          'Present: $presentCount\n'
          'Absent: ${_students.length - presentCount}',
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
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
            ),
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
          SnackBar(
            content: Text('Attendance marked for $presentCount students'),
            backgroundColor: AppColors.success,
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
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final presentCount = _attendance.values.where((v) => v).length;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgCard,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Manual Attendance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.subject['name'] ?? 'Subject',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Date & Stats Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.bgCard,
            child: Column(
              children: [
                // Date Selector
                InkWell(
                  onTap: _selectDate,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.bgInput,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF1565C0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          color: Color(0xFF1565C0),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Attendance Date',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_drop_down,
                          color: Color(0xFF1565C0),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Stats
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.success.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '$presentCount',
                              style: const TextStyle(
                                color: AppColors.success,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'Present',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.danger.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${_students.length - presentCount}',
                              style: const TextStyle(
                                color: AppColors.danger,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'Absent',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Quick Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _markAllPresent,
                        icon: const Icon(Icons.check_box, size: 18),
                        label: const Text('Mark All Present'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.success,
                          side: const BorderSide(color: AppColors.success),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _markAllAbsent,
                        icon: const Icon(Icons.cancel, size: 18),
                        label: const Text('Mark All Absent'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          side: const BorderSide(color: AppColors.danger),
                          padding: const EdgeInsets.symmetric(vertical: 12),
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
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1565C0)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _students.length,
                    itemBuilder: (context, index) {
                      return _buildStudentTile(_students[index]);
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: AppColors.bgCard,
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submitAttendance,
              icon: const Icon(Icons.check_circle),
              label: Text(
                _isSubmitting ? 'Submitting...' : 'Submit Attendance',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStudentTile(Map<String, dynamic> student) {
    final isPresent = _attendance[student['id']] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPresent
              ? AppColors.success.withOpacity(0.3)
              : AppColors.bgSeparator,
        ),
      ),
      child: CheckboxListTile(
        value: isPresent,
        onChanged: (value) {
          setState(() {
            _attendance[student['id']] = value ?? false;
          });
        },
        title: Text(
          student['full_name'] ?? 'Student',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          student['register_number'] ?? '',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        secondary: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isPresent
                  ? [AppColors.success, AppColors.successDark]
                  : [const Color(0xFF1565C0), const Color(0xFF1976D2)],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              student['full_name']?.substring(0, 1).toUpperCase() ?? 'S',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        activeColor: AppColors.success,
        checkColor: Colors.white,
        controlAffinity: ListTileControlAffinity.trailing,
      ),
    );
  }
}
