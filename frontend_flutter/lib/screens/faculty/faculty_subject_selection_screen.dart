// File: lib/screens/faculty/faculty_subject_selection_screen.dart
// Faculty selects subject to teach (with semester support)

import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/skeleton.dart';
import '../../core/session.dart';

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
  List<String> _availableSemesters = [];
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

      // Extract unique semesters
      final semesters = allSubjects
          .map((s) => s['semester']?.toString() ?? 'Semester 1')
          .toSet()
          .toList();

      // Numerical sort (Semester 1, Semester 2, ...)
      semesters.sort((a, b) {
        int getNum(String s) {
          final match = RegExp(r'\d+').firstMatch(s);
          return int.tryParse(match?.group(0) ?? '0') ?? 0;
        }

        return getNum(a).compareTo(getNum(b));
      });

      setState(() {
        _subjects = allSubjects;
        _availableSemesters = semesters;

        // If current selected semester is not in the list, pick the first one
        if (!_availableSemesters.contains(_selectedSemester) &&
            _availableSemesters.isNotEmpty) {
          // But only if we are in 'reports' mode. For attendance, we should stick to what's expected.
          if (widget.action == 'reports') {
            _selectedSemester = _availableSemesters.first;
          }
        }

        _filterSubjects();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _filterSubjects() {
    setState(() {
      _filteredSubjects = _subjects.where((s) {
        return s['semester'] == _selectedSemester;
      }).toList();
    });
  }

  Future<void> _selectSubject(Map<String, dynamic> subject) async {
    final cs = Theme.of(context).colorScheme;
    final completeData = {
      'department': widget.department,
      'class': widget.classData,
      'subject': subject,
      'semester': _selectedSemester,
    };

    switch (widget.action) {
      case 'attendance':
        final facultyId = SessionManager.facultyId ?? SessionManager.userId;
        if (facultyId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Session expired. Please log in again.'),
              backgroundColor: cs.error,
            ),
          );
          return;
        }
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
                backgroundColor: cs.surface,
                title: Text(
                  'Session Already Active',
                  style: TextStyle(color: cs.onSurface),
                ),
                content: Text(
                  '${subject['name']} already has an ongoing session.\nDo you want to rejoin it?',
                  style: TextStyle(color: cs.onSurface.withOpacity(0.7)),
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
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.classData['year']} - Section ${widget.classData['section']}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.department['name'] ?? 'Department',
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
          // Semester Selection Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border(
                bottom: BorderSide(color: cs.onSurface.withOpacity(0.05)),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_month_outlined,
                  color: cs.primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Semester:',
                  style: TextStyle(
                    color: cs.onSurface.withOpacity(0.6),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 12),

                // Semester Dropdown
                _availableSemesters.length > 1
                    ? Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value:
                                _availableSemesters.contains(_selectedSemester)
                                    ? _selectedSemester
                                    : (_availableSemesters.isNotEmpty
                                        ? _availableSemesters.first
                                        : null),
                            isDense: true,
                            icon: Icon(
                              Icons.arrow_drop_down,
                              color: cs.primary,
                            ),
                            style: TextStyle(
                              color: cs.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() => _selectedSemester = newValue);
                                _filterSubjects();
                              }
                            },
                            items: _availableSemesters
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          ),
                        ),
                      )
                    : Text(
                        _selectedSemester,
                        style: TextStyle(
                          color: cs.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                if (widget.action == 'reports')
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Reports Mode',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Subjects list
          Expanded(
            child: _isLoading
                ? const AppPageSkeleton()
                : _filteredSubjects.isEmpty
                    ? _buildEmptyState(cs)
                    : RefreshIndicator(
                        onRefresh: _loadSubjects,
                        color: cs.primary,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredSubjects.length,
                          itemBuilder: (context, index) {
                            return _buildSubjectCard(
                                _filteredSubjects[index], cs);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(Map<String, dynamic> subject, ColorScheme cs) {
    final String type = subject['type'] ?? 'Theory';
    final Color typeColor = type == 'Lab'
        ? const Color(0xFF00897B)
        : type == 'Project'
            ? const Color(0xFFE65100)
            : cs.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: typeColor.withOpacity(0.2)),
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
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getSubjectIcon(type),
                    color: typeColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject['name'] ?? 'Subject',
                        style: TextStyle(
                          color: cs.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: typeColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              subject['code'] ?? '',
                              style: TextStyle(
                                color: typeColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$type • ${subject['credits']} Credits',
                            style: TextStyle(
                              color: cs.onSurface.withOpacity(0.5),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: cs.onSurface.withOpacity(0.3)),
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
        return Icons.science_outlined;
      case 'Project':
        return Icons.assignment_outlined;
      case 'Theory':
      default:
        return Icons.menu_book_outlined;
    }
  }

  Widget _buildEmptyState(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book_outlined,
            size: 80,
            color: cs.onSurface.withOpacity(0.1),
          ),
          const SizedBox(height: 20),
          Text(
            'No subjects found',
            style: TextStyle(
              color: cs.onSurface.withOpacity(0.5),
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No subjects available for $_selectedSemester',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: cs.onSurface.withOpacity(0.4),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _loadSubjects,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh List'),
          ),
        ],
      ),
    );
  }
}
