import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../core/app_colors.dart';
// ✅ Added import for Student Details Screen
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

    // Apply search
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

        if (_filterBy == 'hosteler') {
          return type.contains('hostel');
        }

        if (_filterBy == 'day_scholar') {
          return type.contains('day');
        }

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

  // ✅ Updated navigation for View Student Details
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
              '${widget.subject['name']} • ${_students.length} students',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
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
            color: AppColors.bgCard,
            child: Column(
              children: [
                // Search bar
                TextField(
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search by name or register number...',
                    hintStyle: const TextStyle(color: AppColors.textHint),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF1565C0),
                    ),
                    filled: true,
                    fillColor: AppColors.bgInput,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),

                const SizedBox(height: 12),

                // Filter chips
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildFilterChip('All', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Hosteler', 'hosteler'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Day Scholar', 'day_scholar'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Students list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1565C0)),
                  )
                : _filteredStudents.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadStudents,
                    color: const Color(0xFF1565C0),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredStudents.length,
                      itemBuilder: (context, index) {
                        return _buildStudentCard(_filteredStudents[index]);
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
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterBy == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _filterBy = value);
      },
      backgroundColor: AppColors.bgInput,
      selectedColor: const Color(0xFF1565C0),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    final isHosteler = student['residential_type']?.toLowerCase() == 'hosteler';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1565C0).withOpacity(0.3)),
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
                // Avatar
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
                      (student['full_name'] != null &&
                              student['full_name'].toString().isNotEmpty)
                          ? student['full_name'][0].toUpperCase()
                          : 'S',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Student info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student['full_name'] ?? 'Student',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        student['register_number'] ?? '',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            isHosteler ? Icons.home : Icons.directions_walk,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            student['residential_type'] ?? 'Day Scholar',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          if (student['blood_group'] != null) ...[
                            const SizedBox(width: 12),
                            Icon(
                              Icons.bloodtype,
                              size: 14,
                              color: AppColors.danger,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              student['blood_group'],
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Actions menu
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    color: AppColors.textSecondary,
                  ),
                  color: AppColors.bgCard,
                  onSelected: (value) {
                    switch (value) {
                      case 'view':
                        _viewStudent(student);
                        break;
                      case 'edit':
                        Navigator.pushNamed(
                          context,
                          '/facultyEditStudent',
                          arguments: {
                            'studentData': student,
                            'classData': widget.classData,
                          },
                        ).then((_) => _loadStudents());
                        break;
                      case 'qr':
                        Navigator.pushNamed(
                          context,
                          '/facultyGenerateStudentQR',
                          arguments: student,
                        );
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(Icons.visibility, color: Color(0xFF1565C0)),
                          SizedBox(width: 12),
                          Text(
                            'View Details',
                            style: TextStyle(color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: AppColors.warning),
                          SizedBox(width: 12),
                          Text(
                            'Edit',
                            style: TextStyle(color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'qr',
                      child: Row(
                        children: [
                          Icon(Icons.qr_code, color: AppColors.success),
                          SizedBox(width: 12),
                          Text(
                            'Generate QR',
                            style: TextStyle(color: AppColors.textPrimary),
                          ),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 20),
          Text(
            _searchQuery.isEmpty
                ? 'No students added yet'
                : 'No students found',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'Tap + to add your first student'
                : 'Try a different search term',
            style: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
