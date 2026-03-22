// File: lib/screens/faculty/faculty_class_selection_screen.dart
// Faculty selects Year + Section for a department

import 'package:flutter/material.dart';
import '../../services/api_service.dart';
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
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.department['name'] ?? 'Department',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Your Classes',
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
          // Info Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border(
                bottom: BorderSide(color: cs.onSurface.withOpacity(0.05)),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.class_outlined, color: cs.primary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Classes assigned to you in ${widget.department['code'] ?? 'this department'}',
                    style: TextStyle(
                      color: cs.onSurface.withOpacity(0.6),
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
                ? Center(child: CircularProgressIndicator(color: cs.primary))
                : _classes.isEmpty
                ? _buildEmptyState(cs)
                : RefreshIndicator(
                    onRefresh: _loadClasses,
                    color: cs.primary,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _classes.length,
                      itemBuilder: (context, index) {
                        return _buildClassCard(_classes[index], cs);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassCard(Map<String, dynamic> classData, ColorScheme cs) {
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
          onTap: () => _selectClass(classData),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.school_outlined,
                    color: cs.primary,
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
                        style: TextStyle(
                          color: cs.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${classData['total_students'] ?? 0} students • ${classData['current_semester'] ?? 'Active Semester'}',
                        style: TextStyle(
                          color: cs.onSurface.withOpacity(0.6),
                          fontSize: 13,
                        ),
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

  Widget _buildEmptyState(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.class_outlined,
            size: 80,
            color: cs.onSurface.withOpacity(0.1),
          ),
          const SizedBox(height: 20),
          Text(
            'No classes found',
            style: TextStyle(
              color: cs.onSurface.withOpacity(0.5),
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'No classes assigned in this department.\nAsk admin to update your assignments.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: cs.onSurface.withOpacity(0.4),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
