// File: lib/screens/admin/admin_faculty_management_screen.dart
// List and manage all faculty members

import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../services/api_service.dart';

class AdminFacultyManagementScreen extends StatefulWidget {
  const AdminFacultyManagementScreen({super.key});

  @override
  State<AdminFacultyManagementScreen> createState() =>
      _AdminFacultyManagementScreenState();
}

class _AdminFacultyManagementScreenState
    extends State<AdminFacultyManagementScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _facultyList = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadFaculty();
  }

  Future<void> _loadFaculty() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getAllFaculty(); // ✅ Real API
      if (mounted) {
        setState(() {
          _facultyList = List<Map<String, dynamic>>.from(data);
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

  List<Map<String, dynamic>> get _filteredFaculty {
    if (_searchQuery.isEmpty) return _facultyList;
    return _facultyList
        .where(
          (f) =>
              f['name'].toString().toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              f['email'].toString().toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              f['employee_id'].toString().toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Faculty Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () async {
              await Navigator.pushNamed(context, '/adminAddFaculty');
              _loadFaculty(); // Reload after returning
            },
            tooltip: 'Add Faculty',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search faculty...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          // Faculty List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredFaculty.isEmpty
                ? const Center(
                    child: Text(
                      'No faculty found',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadFaculty,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredFaculty.length,
                      itemBuilder: (context, index) {
                        final faculty = _filteredFaculty[index];
                        return _buildFacultyCard(faculty);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFacultyCard(Map<String, dynamic> faculty) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.bgCard,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF1565C0),
          child: Text(
            faculty['name'].toString().substring(0, 1),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          faculty['name'],
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              faculty['email'],
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            Text(
              '${faculty['department']} • ${faculty['employee_id']}',
              style: const TextStyle(color: AppColors.textHint, fontSize: 11),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value, faculty),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'view', child: Text('View Details')),
            const PopupMenuItem(value: 'edit', child: Text('Edit Faculty')),
            const PopupMenuItem(value: 'qr', child: Text('Generate QR')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
        onTap: () => Navigator.pushNamed(
          context,
          '/adminFacultyDetails',
          arguments: faculty,
        ),
      ),
    );
  }

  void _handleMenuAction(String action, Map<String, dynamic> faculty) {
    switch (action) {
      case 'view':
        Navigator.pushNamed(
          context,
          '/adminFacultyDetails',
          arguments: faculty,
        );
        break;
      case 'edit':
        Navigator.pushNamed(context, '/adminEditFaculty', arguments: faculty);
        break;
      case 'qr':
        Navigator.pushNamed(
          context,
          '/adminGenerateFacultyQR',
          arguments: faculty,
        );
        break;
      case 'delete':
        _confirmDelete(faculty);
        break;
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> faculty) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Faculty'),
        content: Text('Are you sure you want to delete ${faculty['name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await ApiService.deleteFaculty(faculty['id']); // ✅ Real API
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${faculty['name']} deleted successfully'),
              backgroundColor: AppColors.success,
            ),
          );
          _loadFaculty();
        }
      } on ApiException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.message),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }
}
