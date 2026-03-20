// File: lib/screens/admin/admin_system_reports_screen.dart
import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../services/api_service.dart';
import '../../core/session.dart';

class AdminSystemReportsScreen extends StatefulWidget {
  const AdminSystemReportsScreen({super.key});

  @override
  State<AdminSystemReportsScreen> createState() =>
      _AdminSystemReportsScreenState();
}

class _AdminSystemReportsScreenState extends State<AdminSystemReportsScreen> {
  String _selectedPeriod = 'today';
  bool _isLoading = true;
  Map<String, dynamic> _reportData = {};
  List<Map<String, dynamic>> _departments = [];
  int? _selectedDeptId;
  bool _isPrincipal = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final role = SessionManager.role;
    _isPrincipal = role == 'principal';
    if (_isPrincipal) {
      try {
        final depts = await ApiService.getPrincipalDepartments();
        setState(() {
          _departments = List<Map<String, dynamic>>.from(depts);
        });
      } catch (_) {}
    }
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getSystemReports(
        period: _selectedPeriod,
        departmentId: _selectedDeptId,
      );
      if (mounted) {
        setState(() {
          _reportData = data;
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.danger),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('System Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Export feature coming soon')),
              );
            },
            tooltip: 'Export Report',
          ),
        ],
      ),
      body: Column(
        children: [
          // Period Selector
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                _buildPeriodChip('Today', 'today'),
                _buildPeriodChip('This Week', 'week'),
                _buildPeriodChip('This Month', 'month'),
              ],
            ),
          ),

          // Department selector (principal only)
          if (_isPrincipal && _departments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: DropdownButtonFormField<int?>(
                value: _selectedDeptId,
                dropdownColor: AppColors.bgCard,
                decoration: InputDecoration(
                  labelText: 'Department',
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.bgCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                style: const TextStyle(color: AppColors.textPrimary),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('All Departments'),
                  ),
                  ..._departments.map(
                    (d) => DropdownMenuItem<int?>(
                      value: d['id'],
                      child: Text(d['name'] ?? ''),
                    ),
                  ),
                ],
                onChanged: (val) {
                  setState(() => _selectedDeptId = val);
                  _loadReports();
                },
              ),
            ),

          // Reports Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadReports,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Attendance Overview
                        _buildSectionTitle('Attendance Overview'),
                        _buildReportCard(
                          'Total Sessions',
                          '${_reportData['total_attendance_sessions']}',
                          Icons.timer,
                          AppColors.info,
                        ),
                        _buildReportCard(
                          'Average Attendance',
                          '${_reportData['avg_attendance_percentage']}%',
                          Icons.assessment,
                          AppColors.success,
                        ),

                        const SizedBox(height: 24),

                        // Student Stats
                        _buildSectionTitle('Student Statistics'),
                        Row(
                          children: [
                            Expanded(
                              child: _buildReportCard(
                                'Present',
                                '${_reportData['total_students_present']}',
                                Icons.check_circle,
                                AppColors.success,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildReportCard(
                                'Absent',
                                '${_reportData['total_students_absent']}',
                                Icons.cancel,
                                AppColors.danger,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Performance Insights — only for All Departments
                        if (_selectedDeptId == null) ...[
                          _buildSectionTitle('Performance Insights'),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.bgCard,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInsightRow(
                                  'Best Department',
                                  _reportData['top_department'] ?? 'N/A',
                                  Icons.emoji_events,
                                  AppColors.warning,
                                ),
                                const Divider(height: 24),
                                _buildInsightRow(
                                  'Needs Attention',
                                  _reportData['lowest_attendance_class'] ??
                                      'N/A',
                                  Icons.warning,
                                  AppColors.danger,
                                ),
                              ],
                            ),
                          ),
                        ], // end performance insights

                        const SizedBox(height: 24),

                        // Complaints Summary
                        _buildSectionTitle('Complaints Summary'),
                        Row(
                          children: [
                            Expanded(
                              child: _buildReportCard(
                                'Resolved',
                                '${_reportData['complaints_resolved']}',
                                Icons.check_circle,
                                AppColors.success,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildReportCard(
                                'Pending',
                                '${_reportData['complaints_pending']}',
                                Icons.pending,
                                AppColors.warning,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String label, String value) {
    final isSelected = _selectedPeriod == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _selectedPeriod = value);
          _loadReports();
        },
        backgroundColor: AppColors.bgCard,
        selectedColor: AppColors.danger,
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildReportCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightRow(
    String label,
    dynamic value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
