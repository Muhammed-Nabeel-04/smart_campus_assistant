// File: lib/screens/faculty/faculty_attendance_reports_screen.dart
// View attendance reports with date range and student-wise data

import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../core/app_colors.dart';

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
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate,
      firstDate: DateTime(2020),
      lastDate: _toDate,
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
      setState(() => _fromDate = picked);
      _loadReports();
    }
  }

  Future<void> _selectToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate,
      firstDate: _fromDate,
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
      setState(() => _toDate = picked);
      _loadReports();
    }
  }

  void _exportReport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Export Report',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Export feature coming soon!\nYou will be able to download reports as PDF or Excel.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFF1565C0))),
          ),
        ],
      ),
    );
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
            const Text(
              'Attendance Reports',
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
            color: AppColors.bgCard,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _selectFromDate,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.bgInput,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF1565C0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'From',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_fromDate.day}/${_fromDate.month}/${_fromDate.year}',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(
                        Icons.arrow_forward,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: _selectToDate,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.bgInput,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF1565C0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'To',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_toDate.day}/${_toDate.month}/${_toDate.year}',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
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
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.info, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Showing ${_reports.length} students',
                        style: TextStyle(color: AppColors.info, fontSize: 12),
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
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1565C0)),
                  )
                : _reports.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadReports,
                    color: const Color(0xFF1565C0),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _reports.length,
                      itemBuilder: (context, index) {
                        return _buildReportCard(_reports[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    final present = report['present'] ?? 0;
    final absent = report['absent'] ?? 0;
    final total = present + absent;
    final percentage = total > 0
        ? (present / total * 100).toStringAsFixed(1)
        : '0.0';
    final percentageValue = total > 0 ? (present / total * 100) : 0.0;

    final statusColor = percentageValue >= 75
        ? AppColors.success
        : AppColors.danger;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3)),
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
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    report['name']?.substring(0, 1).toUpperCase() ?? 'S',
                    style: const TextStyle(
                      color: Colors.white,
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
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      report['register_number'] ?? '',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
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
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor),
                ),
                child: Text(
                  '$percentage%',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 16,
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
                  AppColors.success,
                ),
              ),
              Expanded(
                child: _buildStatColumn(
                  'Absent',
                  absent.toString(),
                  AppColors.danger,
                ),
              ),
              Expanded(
                child: _buildStatColumn(
                  'Total',
                  total.toString(),
                  const Color(0xFF1565C0),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assessment_outlined,
            size: 80,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 20),
          const Text(
            'No attendance records found',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try selecting a different date range',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
