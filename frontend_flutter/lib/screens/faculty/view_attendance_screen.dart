// File: lib/screens/faculty/view_attendance_screen.dart

import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class ViewAttendanceScreen extends StatefulWidget {
  const ViewAttendanceScreen({super.key});

  @override
  State<ViewAttendanceScreen> createState() => _ViewAttendanceScreenState();
}

class _ViewAttendanceScreenState extends State<ViewAttendanceScreen> {
  List<dynamic> _students = [];
  bool _loading = true;
  String? _subjectName;
  String? _className;
  int? _classId;
  int? _subjectId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final classData = args?['class'] as Map<String, dynamic>?;
    final subject = args?['subject'] as Map<String, dynamic>?;

    _classId = classData?['id'];
    _subjectId = subject?['id'];
    _subjectName = subject?['name'] ?? 'Subject';
    _className = classData != null
        ? '${classData['year']} - Section ${classData['section']}'
        : null;

    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    if (_classId == null || _subjectId == null) {
      setState(() => _loading = false);
      return;
    }

    setState(() => _loading = true);

    try {
      final data = await ApiService.getAttendanceReports(
        classId: _classId!,
        subjectId: _subjectId!,
      );

      if (mounted) {
        setState(() {
          _students = data['students'] ?? [];
          _loading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _getAttendanceColor(dynamic percentage, ColorScheme cs) {
    final pct = (percentage ?? 0).toDouble();
    if (pct >= 75) return const Color(0xFF4CAF50); // Success Green
    if (pct >= 60) return const Color(0xFFFF9800); // Warning Orange
    return cs.error; // Danger Red
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
              _subjectName ?? 'Attendance',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (_className != null)
              Text(
                _className!,
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withOpacity(0.6),
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _loadAttendance,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: cs.primary))
          : _students.isEmpty
          ? _buildEmptyState(cs)
          : RefreshIndicator(
              onRefresh: _loadAttendance,
              color: cs.primary,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _students.length,
                itemBuilder: (context, index) {
                  final s = _students[index];
                  final percentage = s['attendance_percentage'] ?? 0;
                  final statusColor = _getAttendanceColor(percentage, cs);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cs.onSurface.withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: statusColor.withOpacity(0.1),
                          child: Text(
                            (s['full_name'] ?? '?')[0].toUpperCase(),
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s['full_name'] ?? 'Unknown',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                s['register_number'] ?? '',
                                style: TextStyle(
                                  color: cs.onSurface.withOpacity(0.6),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${percentage.toStringAsFixed(1)}%',
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '${s['attended']}/${s['total']} days',
                              style: TextStyle(
                                color: cs.onSurface.withOpacity(0.4),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }

  Widget _buildEmptyState(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart_outlined,
            size: 80,
            color: cs.onSurface.withOpacity(0.1),
          ),
          const SizedBox(height: 16),
          Text(
            'No attendance records yet',
            style: TextStyle(
              color: cs.onSurface.withOpacity(0.5),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
