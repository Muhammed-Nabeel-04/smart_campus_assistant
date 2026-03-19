// File: lib/screens/faculty/faculty_subject_selection_screen.dart
// Faculty selects subject to teach (with semester support)

import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../core/session.dart';
import '../../core/app_colors.dart';

class FacultySubjectSelectionScreen extends StatefulWidget {
  final Map<String, dynamic> department;
  final Map<String, dynamic> classData;
  final String action;
  final bool isNew;

  const FacultySubjectSelectionScreen({
    super.key,
    required this.department,
    required this.classData,
    required this.action,
    this.isNew = false,
  });

  @override
  State<FacultySubjectSelectionScreen> createState() =>
      _FacultySubjectSelectionScreenState();
}

class _FacultySubjectSelectionScreenState
    extends State<FacultySubjectSelectionScreen> {
  List<Map<String, dynamic>> _subjects = [];
  List<Map<String, dynamic>> _filteredSubjects = [];
  bool _isLoading = true;
  late String _selectedSemester;

  @override
  void initState() {
    super.initState();
    // ✅ Auto-select the semester HOD set for this class
    _selectedSemester = widget.classData['current_semester'] ?? 'Semester 1';
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getSubjectsByClass(widget.classData['id']);
      final allSubjects = List<Map<String, dynamic>>.from(data);
      setState(() {
        _subjects = allSubjects;
        // ✅ Filter by current semester only
        _filteredSubjects = allSubjects.where((s) {
          return s['semester'] == _selectedSemester;
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // ✅ Updated _selectSubject with fixed routing
  Future<void> _selectSubject(Map<String, dynamic> subject) async {
    final completeData = {
      'department': widget.department,
      'class': widget.classData,
      'subject': subject,
      'semester': _selectedSemester,
    };

    switch (widget.action) {
      case 'attendance':
        // Check if session already active for this subject
        final facultyId = SessionManager.facultyId!;
        try {
          final activeSessions = await ApiService.getActiveSessions(facultyId);
          final existing = activeSessions.firstWhere(
            (s) => s['subject_name'] == subject['name'],
            orElse: () => {},
          );
          if (!mounted) return;
          if (existing.isNotEmpty) {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppColors.bgCard,
                title: const Text(
                  'Session Already Active',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                content: Text(
                  '${subject['name']} already has an ongoing session.\nDo you want to rejoin it?',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pushNamed(
                        context,
                        '/facultyStartAttendance',
                        arguments: completeData,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: const Text('Rejoin'),
                  ),
                ],
              ),
            );
          } else {
            Navigator.pushNamed(
              context,
              '/facultyStartAttendance',
              arguments: completeData,
            );
          }
        } catch (_) {
          Navigator.pushNamed(
            context,
            '/facultyStartAttendance',
            arguments: completeData,
          );
        }
        break;
      case 'classroom':
        Navigator.pushNamed(
          context,
          '/facultyClassroomManagement',
          arguments: completeData,
        );
        break;
      case 'reports':
        Navigator.pushNamed(
          context,
          '/facultyAttendanceReports',
          arguments: completeData,
        );
        break;
      case 'manual':
        Navigator.pushNamed(
          context,
          '/facultyManualAttendance',
          arguments: completeData,
        );
        break;
      default:
        Navigator.pushNamed(
          context,
          '/facultyClassroomManagement',
          arguments: completeData,
        );
    }
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
              '${widget.classData['year']} - Section ${widget.classData['section']}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.department['name'] ?? 'Department',
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
          // ✅ Show only the HOD-assigned semester (no switching)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.bgCard,
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: AppColors.primary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  _selectedSemester,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Subjects list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1565C0)),
                  )
                : _subjects.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadSubjects,
                    color: const Color(0xFF1565C0),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredSubjects.length,
                      itemBuilder: (context, index) {
                        return _buildSubjectCard(_filteredSubjects[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(Map<String, dynamic> subject) {
    final typeColors = {
      'Theory': const Color(0xFF1565C0),
      'Lab': const Color(0xFF00897B),
      'Project': const Color(0xFFE65100),
    };
    final color = typeColors[subject['type']] ?? const Color(0xFF1565C0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectSubject(subject),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getSubjectIcon(subject['type']),
                    color: color,
                    size: 24,
                  ),
                ),

                const SizedBox(width: 16),

                // Subject info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Subject name
                      Text(
                        subject['name'] ?? 'Subject',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Subject code and type
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              subject['code'] ?? '',
                              style: TextStyle(
                                color: color,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${subject['type']} • ${subject['credits']} Credits',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Arrow
                const Icon(Icons.chevron_right, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getSubjectIcon(String? type) {
    switch (type) {
      case 'Lab':
        return Icons.science;
      case 'Project':
        return Icons.assignment;
      case 'Theory':
      default:
        return Icons.book;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book_outlined,
            size: 80,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 20),
          const Text(
            'No subjects found',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'No subjects available for $_selectedSemester',
            style: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.7),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadSubjects,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
