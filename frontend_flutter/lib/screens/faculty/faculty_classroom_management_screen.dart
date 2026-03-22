// File: lib/screens/faculty/faculty_classroom_management_screen.dart
// Classroom management with student list, search, and filtering

import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'faculty_student_details_screen.dart';

class FacultyClassroomManagementScreen extends StatefulWidget {
  final Map<String, dynamic> department;
  final Map<String, dynamic> classData;
  final Map<String, dynamic> subject;
  final String semester;

  const FacultyClassroomManagementScreen({
    super.key,
    required this.department,
    required this.classData,
    required this.subject,
    required this.semester,
  });

  @override
  State<FacultyClassroomManagementScreen> createState() =>
      _FacultyClassroomManagementScreenState();
}

class _FacultyClassroomManagementScreenState
    extends State<FacultyClassroomManagementScreen> {
  List<Map<String, dynamic>> _students = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _filterBy = 'all'; // 'all', 'hosteler', 'day_scholar'

  // Fixed Role/Status Colors
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color errorRed = Color(0xFFF44336);

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
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  List<Map<String, dynamic>> get _filteredStudents {
    var filtered = _students;
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((student) {
        final name = student['full_name'].toString().toLowerCase();
        final regno = student['register_number'].toString().toLowerCase();
        final query = _searchQuery.toLowerCase();
        return name.contains(query) || regno.contains(query);
      }).toList();
    }
    if (_filterBy != 'all') {
      filtered = filtered.where((student) {
        final type = student['residential_type']?.toLowerCase() ?? '';
        if (_filterBy == 'hosteler') return type.contains('hostel');
        if (_filterBy == 'day_scholar') return type.contains('day');
        return true;
      }).toList();
    }
    return filtered;
  }

  void _addStudent() {
    Navigator.pushNamed(
      context,
      '/facultyAddStudent',
      arguments: {
        'department': widget.department,
        'classData': widget.classData,
      },
    ).then((_) => _loadStudents());
  }

  void _viewStudent(Map<String, dynamic> student) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FacultyStudentDetailsScreen(
          student: student,
          classData: widget.classData,
        ),
      ),
    ).then((_) => _loadStudents());
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
              '${widget.subject['name']} • ${_students.length} students',
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadStudents),
        ],
      ),
      body: Column(
        children: [
          // Search and filter bar
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
                TextField(
                  style: TextStyle(color: cs.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Search by name or register number...',
                    prefixIcon: Icon(Icons.search, color: cs.primary),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildFilterChip('All', 'all', cs),
                      const SizedBox(width: 8),
                      _buildFilterChip('Hosteler', 'hosteler', cs),
                      const SizedBox(width: 8),
                      _buildFilterChip('Day Scholar', 'day_scholar', cs),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Students list
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: cs.primary))
                : _filteredStudents.isEmpty
                ? _buildEmptyState(cs)
                : RefreshIndicator(
                    onRefresh: _loadStudents,
                    color: cs.primary,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredStudents.length,
                      itemBuilder: (context, index) {
                        return _buildStudentCard(_filteredStudents[index], cs);
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addStudent,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Student'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, ColorScheme cs) {
    final isSelected = _filterBy == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) => setState(() => _filterBy = value),
      selectedColor: cs.primary,
      labelStyle: TextStyle(
        color: isSelected ? cs.onPrimary : cs.onSurface,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student, ColorScheme cs) {
    final isHosteler = student['residential_type']?.toLowerCase() == 'hosteler';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.primary.withOpacity(0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _viewStudent(student),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
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
                      (student['full_name'] != null &&
                              student['full_name'].toString().isNotEmpty)
                          ? student['full_name'][0].toUpperCase()
                          : 'S',
                      style: TextStyle(
                        color: cs.onPrimary,
                        fontSize: 22,
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
                        student['full_name'] ?? 'Student',
                        style: TextStyle(
                          color: cs.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        student['register_number'] ?? '',
                        style: TextStyle(
                          color: cs.onSurface.withOpacity(0.6),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            isHosteler ? Icons.home : Icons.directions_walk,
                            size: 14,
                            color: cs.onSurface.withOpacity(0.5),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            student['residential_type'] ?? 'Day Scholar',
                            style: TextStyle(
                              color: cs.onSurface.withOpacity(0.5),
                              fontSize: 12,
                            ),
                          ),
                          if (student['blood_group'] != null) ...[
                            const SizedBox(width: 12),
                            const Icon(
                              Icons.bloodtype,
                              size: 14,
                              color: errorRed,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              student['blood_group'],
                              style: TextStyle(
                                color: cs.onSurface.withOpacity(0.5),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: cs.onSurface.withOpacity(0.4),
                  ),
                  color: cs.surface,
                  onSelected: (value) {
                    if (value == 'view') _viewStudent(student);
                    if (value == 'edit') {
                      Navigator.pushNamed(
                        context,
                        '/facultyEditStudent',
                        arguments: {
                          'studentData': student,
                          'classData': widget.classData,
                        },
                      ).then((_) => _loadStudents());
                    }
                    if (value == 'qr') {
                      Navigator.pushNamed(
                        context,
                        '/facultyGenerateStudentQR',
                        arguments: student,
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(Icons.visibility),
                          SizedBox(width: 12),
                          Text('View'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: warningOrange),
                          SizedBox(width: 12),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'qr',
                      child: Row(
                        children: [
                          Icon(Icons.qr_code, color: successGreen),
                          SizedBox(width: 12),
                          Text('Login QR'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
            Icons.people_outline,
            size: 80,
            color: cs.onSurface.withOpacity(0.1),
          ),
          const SizedBox(height: 20),
          Text(
            _searchQuery.isEmpty
                ? 'No students added yet'
                : 'No students found',
            style: TextStyle(
              color: cs.onSurface.withOpacity(0.5),
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}
