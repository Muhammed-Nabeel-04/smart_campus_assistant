// File: lib/screens/faculty/faculty_attendance_reports_screen.dart
// View attendance reports with date range and student-wise data

import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class FacultyAttendanceReportsScreen extends StatefulWidget {
  final Map<String, dynamic> department;
  final Map<String, dynamic> classData;
  final Map<String, dynamic> subject;
  final String semester;

  const FacultyAttendanceReportsScreen({
    super.key,
    required this.department,
    required this.classData,
    required this.subject,
    required this.semester,
  });

  @override
  State<FacultyAttendanceReportsScreen> createState() =>
      _FacultyAttendanceReportsScreenState();
}

class _FacultyAttendanceReportsScreenState
    extends State<FacultyAttendanceReportsScreen> {
  List<Map<String, dynamic>> _reports = [];
  bool _isLoading = true;
  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _toDate = DateTime.now();

  // Fixed Role Colors
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color errorRed = Color(0xFFF44336);

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);

    try {
      final data = await ApiService.getAttendanceReports(
        classId: widget.classData['id'],
        subjectId: widget.subject['id'],
        fromDate: _fromDate.toIso8601String().split('T')[0],
        toDate: _toDate.toIso8601String().split('T')[0],
      );

      setState(() {
        _reports = List<Map<String, dynamic>>.from(data['reports'] ?? []);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectFromDate() async {
    final cs = Theme.of(context).colorScheme;
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate,
      firstDate: DateTime(2020),
      lastDate: _toDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: cs.copyWith(
              primary: cs.primary,
              surface: cs.surface,
              onSurface: cs.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _fromDate = picked);
      _loadReports();
    }
  }

  Future<void> _selectToDate() async {
    final cs = Theme.of(context).colorScheme;
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate,
      firstDate: _fromDate,
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: cs.copyWith(
              primary: cs.primary,
              surface: cs.surface,
              onSurface: cs.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _toDate = picked);
      _loadReports();
    }
  }

  void _exportReport() {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cs.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Export Report', style: TextStyle(color: cs.onSurface)),
        content: Text(
          'Export feature coming soon!\nYou will be able to download reports as PDF or Excel.',
          style: TextStyle(color: cs.onSurface.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: cs.primary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Attendance Reports',
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
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportReport,
            tooltip: 'Export',
          ),
        ],
      ),
      body: Column(
        children: [
          // Date Range Selector
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
                      child: InkWell(
                        onTap: _selectFromDate,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cs.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: cs.primary.withOpacity(0.5),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'From',
                                style: TextStyle(
                                  color: cs.onSurface.withOpacity(0.5),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_fromDate.day}/${_fromDate.month}/${_fromDate.year}',
                                style: TextStyle(
                                  color: cs.onSurface,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(
                        Icons.arrow_forward,
                        color: cs.onSurface.withOpacity(0.3),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: _selectToDate,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cs.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: cs.primary.withOpacity(0.5),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'To',
                                style: TextStyle(
                                  color: cs.onSurface.withOpacity(0.5),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_toDate.day}/${_toDate.month}/${_toDate.year}',
                                style: TextStyle(
                                  color: cs.onSurface,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: cs.primary, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Showing ${_reports.length} students',
                        style: TextStyle(
                          color: cs.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Reports List
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: cs.primary))
                : _reports.isEmpty
                ? _buildEmptyState(cs)
                : RefreshIndicator(
                    onRefresh: _loadReports,
                    color: cs.primary,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _reports.length,
                      itemBuilder: (context, index) {
                        return _buildReportCard(_reports[index], cs);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report, ColorScheme cs) {
    final present = report['present'] ?? 0;
    final absent = report['absent'] ?? 0;
    final total = present + absent;
    final percentageValue = total > 0 ? (present / total * 100) : 0.0;
    final percentage = percentageValue.toStringAsFixed(1);

    final statusColor = percentageValue >= 75 ? successGreen : errorRed;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.onSurface.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    report['name']?.substring(0, 1).toUpperCase() ?? 'S',
                    style: TextStyle(
                      color: cs.onPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report['name'] ?? 'Student',
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      report['register_number'] ?? '',
                      style: TextStyle(
                        color: cs.onSurface.withOpacity(0.6),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withOpacity(0.5)),
                ),
                child: Text(
                  '$percentage%',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatColumn(
                  'Present',
                  present.toString(),
                  successGreen,
                  cs,
                ),
              ),
              Expanded(
                child: _buildStatColumn(
                  'Absent',
                  absent.toString(),
                  errorRed,
                  cs,
                ),
              ),
              Expanded(
                child: _buildStatColumn(
                  'Total',
                  total.toString(),
                  cs.primary,
                  cs,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(
    String label,
    String value,
    Color color,
    ColorScheme cs,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: cs.onSurface.withOpacity(0.5), fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assessment_outlined,
            size: 80,
            color: cs.onSurface.withOpacity(0.2),
          ),
          const SizedBox(height: 20),
          Text(
            'No attendance records found',
            style: TextStyle(
              color: cs.onSurface.withOpacity(0.5),
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try selecting a different date range',
            style: TextStyle(
              color: cs.onSurface.withOpacity(0.4),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
