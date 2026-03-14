// File: lib/screens/faculty/faculty_department_selection_screen.dart
// Faculty selects department to work with

import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../core/app_colors.dart';
// ✅ Added import for Class Selection
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

  // ✅ Updated navigation to use MaterialPageRoute
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
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgCard,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _actionTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Select Department',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.bgCard,
            child: TextField(
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search departments...',
                hintStyle: const TextStyle(color: AppColors.textHint),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF1565C0)),
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
          ),

          // Departments grid
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1565C0)),
                  )
                : _filteredDepartments.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadDepartments,
                    color: const Color(0xFF1565C0),
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.2,
                          ),
                      itemCount: _filteredDepartments.length,
                      itemBuilder: (context, index) {
                        return _buildDepartmentCard(
                          _filteredDepartments[index],
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentCard(Map<String, dynamic> department) {
    final colors = [
      const Color(0xFF1565C0),
      const Color(0xFF00897B),
      const Color(0xFFE65100),
      const Color(0xFF6A1B9A),
      const Color(0xFFC62828),
      const Color(0xFF2E7D32),
    ];
    final color = colors[department['id'] % colors.length];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _selectDepartment(department),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getDepartmentIcon(department['code']),
                  color: color,
                  size: 32,
                ),
              ),

              const SizedBox(height: 12),

              // Department code
              Text(
                department['code'] ?? '',
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),

              const SizedBox(height: 4),

              // Department name
              Text(
                department['name'] ?? '',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              if (department['total_classes'] != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${department['total_classes']} classes',
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 20),
          const Text(
            'No departments found',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'No departments assigned yet.\nAsk admin to assign your classes.'
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
