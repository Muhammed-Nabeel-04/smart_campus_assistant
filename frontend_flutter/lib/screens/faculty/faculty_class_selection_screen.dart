// File: lib/screens/faculty/faculty_class_selection_screen.dart
// Faculty selects Year + Section for a department

import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../core/app_colors.dart';
// ✅ Added import for Subject Selection
import 'faculty_subject_selection_screen.dart';

class FacultyClassSelectionScreen extends StatefulWidget {
  final Map<String, dynamic> department;
  final String action;

  const FacultyClassSelectionScreen({
    super.key,
    required this.department,
    required this.action,
  });

  @override
  State<FacultyClassSelectionScreen> createState() =>
      _FacultyClassSelectionScreenState();
}

class _FacultyClassSelectionScreenState
    extends State<FacultyClassSelectionScreen> {
  List<Map<String, dynamic>> _classes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getFacultyMyClasses(
        departmentId: widget.department['id'],
      );
      setState(() {
        _classes = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _selectClass(Map<String, dynamic> classData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FacultySubjectSelectionScreen(
          department: widget.department,
          classData: classData,
          action: widget.action,
        ),
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
            Text(
              widget.department['name'] ?? 'Department',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Your Classes',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.bgCard,
            child: Row(
              children: [
                const Icon(Icons.class_, color: AppColors.primary, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Showing classes assigned to you in ${widget.department['name'] ?? widget.department['code']}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Classes list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1565C0)),
                  )
                : _classes.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadClasses,
                    color: const Color(0xFF1565C0),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _classes.length,
                      itemBuilder: (context, index) {
                        return _buildClassCard(_classes[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassCard(Map<String, dynamic> classData) {
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
          onTap: () => _selectClass(classData),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.class_,
                    color: Color(0xFF1565C0),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${classData['year']} - Section ${classData['section']}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${classData['total_students'] ?? 0} students • ${classData['current_semester'] ?? 'Semester 1'}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textSecondary),
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
            Icons.class_,
            size: 80,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 20),
          const Text(
            'No classes found',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'No classes assigned in this department.\nAsk admin to update your assignments.',
            style: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.7),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
