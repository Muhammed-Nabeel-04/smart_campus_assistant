// File: lib/screens/admin/admin_system_reports_screen.dart
// System analytics and reporting interface for Admin and Principal roles

import 'package:flutter/material.dart';
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

  // Semantic Colors
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color infoBlue = Color(0xFF2196F3);

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

  void _exportReport() {
    if (_reportData.isEmpty) return;
    final cs = Theme.of(context).colorScheme;

    final period = _selectedPeriod == 'today'
        ? 'Today'
        : _selectedPeriod == 'week'
        ? 'This Week'
        : 'This Month';

    final dept = _selectedDeptId == null
        ? 'All Departments'
        : _departments.firstWhere(
            (d) => d['id'] == _selectedDeptId,
            orElse: () => {'name': 'Unknown'},
          )['name'];

    final report =
        '''
SMART CAMPUS ASSISTANT - SYSTEM REPORT
=======================================
Period       : $period
Department   : $dept
Generated At : ${DateTime.now().toString().substring(0, 16)}

ATTENDANCE OVERVIEW
-------------------
Total Sessions     : ${_reportData['total_attendance_sessions'] ?? 0}
Average Attendance : ${_reportData['avg_attendance_percentage'] ?? 0}%

STUDENT STATISTICS
------------------
Present : ${_reportData['total_students_present'] ?? 0}
Absent  : ${_reportData['total_students_absent'] ?? 0}

PERFORMANCE INSIGHTS
--------------------
Best Department   : ${_reportData['top_department'] ?? 'N/A'}
Needs Attention   : ${_reportData['lowest_attendance_class'] ?? 'N/A'}

COMPLAINTS SUMMARY
------------------
Resolved : ${_reportData['complaints_resolved'] ?? 0}
Pending  : ${_reportData['complaints_pending'] ?? 0}
''';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surface,
        title: const Text('Export System Report'),
        content: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.onSurface.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SingleChildScrollView(
            child: SelectableText(
              report,
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Report copied to clipboard'),
                  backgroundColor: successGreen,
                ),
              );
            },
            icon: const Icon(Icons.copy_all_outlined, size: 18),
            label: const Text('Copy Text'),
          ),
        ],
      ),
    );
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
          SnackBar(
            content: Text(e.message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('System Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: _exportReport,
            tooltip: 'Export',
          ),
        ],
      ),
      body: Column(
        children: [
          // Time Period Filter
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border(
                bottom: BorderSide(color: cs.onSurface.withOpacity(0.05)),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildPeriodChip('Today', 'today', cs),
                  _buildPeriodChip('This Week', 'week', cs),
                  _buildPeriodChip('This Month', 'month', cs),
                ],
              ),
            ),
          ),

          // Department selector (principal only)
          if (_isPrincipal && _departments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: DropdownButtonFormField<int?>(
                value: _selectedDeptId,
                dropdownColor: cs.surface,
                decoration: const InputDecoration(
                  labelText: 'Filtering by Department',
                  prefixIcon: Icon(Icons.filter_list),
                ),
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
                ? Center(child: CircularProgressIndicator(color: cs.primary))
                : RefreshIndicator(
                    onRefresh: _loadReports,
                    color: cs.primary,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildSectionTitle('Attendance Summary', cs),
                        _buildReportCard(
                          'Active Class Sessions',
                          '${_reportData['total_attendance_sessions'] ?? 0}',
                          Icons.history_toggle_off,
                          infoBlue,
                          cs,
                        ),
                        _buildReportCard(
                          'Average Participation',
                          '${_reportData['avg_attendance_percentage'] ?? 0}%',
                          Icons.analytics_outlined,
                          successGreen,
                          cs,
                        ),

                        const SizedBox(height: 24),

                        _buildSectionTitle('Student Engagement', cs),
                        Row(
                          children: [
                            Expanded(
                              child: _buildReportCard(
                                'Present',
                                '${_reportData['total_students_present'] ?? 0}',
                                Icons.person_add_alt_1_outlined,
                                successGreen,
                                cs,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildReportCard(
                                'Absent',
                                '${_reportData['total_students_absent'] ?? 0}',
                                Icons.person_remove_outlined,
                                cs.error,
                                cs,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        if (_selectedDeptId == null) ...[
                          _buildSectionTitle('Departmental Insights', cs),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cs.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: cs.onSurface.withOpacity(0.1),
                              ),
                            ),
                            child: Column(
                              children: [
                                _buildInsightRow(
                                  'Top Performing Dept',
                                  _reportData['top_department'] ?? 'N/A',
                                  Icons.workspace_premium_outlined,
                                  warningOrange,
                                  cs,
                                ),
                                Divider(
                                  height: 32,
                                  color: cs.onSurface.withOpacity(0.05),
                                ),
                                _buildInsightRow(
                                  'Lowest Attendance Class',
                                  _reportData['lowest_attendance_class'] ??
                                      'N/A',
                                  Icons.trending_down_outlined,
                                  cs.error,
                                  cs,
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        _buildSectionTitle('Student Support', cs),
                        Row(
                          children: [
                            Expanded(
                              child: _buildReportCard(
                                'Resolved Issues',
                                '${_reportData['complaints_resolved'] ?? 0}',
                                Icons.task_alt_outlined,
                                successGreen,
                                cs,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildReportCard(
                                'Pending Tickets',
                                '${_reportData['complaints_pending'] ?? 0}',
                                Icons.hourglass_empty_outlined,
                                warningOrange,
                                cs,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String label, String value, ColorScheme cs) {
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
        selectedColor: cs.primary.withOpacity(0.2),
        checkmarkColor: cs.primary,
        labelStyle: TextStyle(
          color: isSelected ? cs.primary : cs.onSurface.withOpacity(0.7),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: cs.onSurface,
        ),
      ),
    );
  }

  Widget _buildReportCard(
    String label,
    String value,
    IconData icon,
    Color color,
    ColorScheme cs,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: cs.onSurface.withOpacity(0.5),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: cs.onSurface,
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
    String value,
    IconData icon,
    Color color,
    ColorScheme cs,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: cs.onSurface.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
