// File: lib/screens/faculty/faculty_department_selection_screen.dart
// Faculty selects department to work with

import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'faculty_class_selection_screen.dart';

class FacultyDepartmentSelectionScreen extends StatefulWidget {
  final String action; // 'attendance', 'classroom', 'reports'

  const FacultyDepartmentSelectionScreen({super.key, required this.action});

  @override
  State<FacultyDepartmentSelectionScreen> createState() =>
      _FacultyDepartmentSelectionScreenState();
}

class _FacultyDepartmentSelectionScreenState
    extends State<FacultyDepartmentSelectionScreen> {
  List<Map<String, dynamic>> _departments = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getFacultyMyDepartments();
      setState(() {
        _departments = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredDepartments {
    if (_searchQuery.isEmpty) return _departments;
    return _departments.where((dept) {
      final name = dept['name'].toString().toLowerCase();
      final code = dept['code'].toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || code.contains(query);
    }).toList();
  }

  void _selectDepartment(Map<String, dynamic> department) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FacultyClassSelectionScreen(
          department: department,
          action: widget.action,
        ),
      ),
    );
  }

  String get _actionTitle {
    switch (widget.action) {
      case 'attendance':
        return 'Start Attendance';
      case 'classroom':
        return 'Manage Classroom';
      case 'reports':
        return 'View Reports';
      default:
        return 'Select Department';
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
              _actionTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Select Department',
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
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border(
                bottom: BorderSide(color: cs.onSurface.withOpacity(0.05)),
              ),
            ),
            child: TextField(
              style: TextStyle(color: cs.onSurface),
              decoration: InputDecoration(
                hintText: 'Search departments...',
                prefixIcon: Icon(Icons.search, color: cs.primary),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          // Departments grid
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: cs.primary))
                : _filteredDepartments.isEmpty
                ? _buildEmptyState(cs)
                : RefreshIndicator(
                    onRefresh: _loadDepartments,
                    color: cs.primary,
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.1,
                          ),
                      itemCount: _filteredDepartments.length,
                      itemBuilder: (context, index) {
                        return _buildDepartmentCard(
                          _filteredDepartments[index],
                          cs,
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentCard(Map<String, dynamic> department, ColorScheme cs) {
    final colors = [
      const Color(0xFF1565C0),
      const Color(0xFF00897B),
      const Color(0xFFE65100),
      const Color(0xFF6A1B9A),
      const Color(0xFFC62828),
      const Color(0xFF2E7D32),
    ];
    final color = colors[department['id'] % colors.length];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: () => _selectDepartment(department),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getDepartmentIcon(department['code']),
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                department['code'] ?? '',
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                department['name'] ?? '',
                style: TextStyle(
                  color: cs.onSurface.withOpacity(0.6),
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getDepartmentIcon(String code) {
    switch (code.toUpperCase()) {
      case 'CSE':
      case 'CS':
        return Icons.computer;
      case 'ECE':
      case 'EEE':
        return Icons.electrical_services;
      case 'MECH':
      case 'ME':
        return Icons.precision_manufacturing;
      case 'CIVIL':
      case 'CE':
        return Icons.architecture;
      case 'IT':
        return Icons.devices;
      case 'AI':
      case 'AIDS':
        return Icons.psychology;
      default:
        return Icons.school;
    }
  }

  Widget _buildEmptyState(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: cs.onSurface.withOpacity(0.1),
          ),
          const SizedBox(height: 20),
          Text(
            'No departments found',
            style: TextStyle(
              color: cs.onSurface.withOpacity(0.5),
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'No departments assigned yet.\nAsk admin to assign your classes.'
                : 'Try a different search term',
            textAlign: TextAlign.center,
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
