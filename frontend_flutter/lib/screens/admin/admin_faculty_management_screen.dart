// File: lib/screens/admin/admin_faculty_management_screen.dart
// List and manage all faculty members

import 'package:flutter/material.dart';
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
      final data = await ApiService.getAllFaculty();
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
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Faculty Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_outlined),
            onPressed: () async {
              await Navigator.pushNamed(context, '/adminAddFaculty');
              _loadFaculty();
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
              style: TextStyle(color: cs.onSurface),
              decoration: InputDecoration(
                hintText: 'Search faculty...',
                prefixIcon: Icon(Icons.search, color: cs.primary),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          // Faculty List
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: cs.primary))
                : _filteredFaculty.isEmpty
                ? _buildEmptyState(cs)
                : RefreshIndicator(
                    onRefresh: _loadFaculty,
                    color: cs.primary,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredFaculty.length,
                      itemBuilder: (context, index) {
                        final faculty = _filteredFaculty[index];
                        return _buildFacultyCard(faculty, cs);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFacultyCard(Map<String, dynamic> faculty, ColorScheme cs) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.onSurface.withOpacity(0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: cs.primary.withOpacity(0.1),
          child: Text(
            faculty['name'].toString().substring(0, 1).toUpperCase(),
            style: TextStyle(
              color: cs.primary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        title: Text(
          faculty['name'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              faculty['email'],
              style: TextStyle(
                color: cs.onSurface.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${faculty['department']} • ID: ${faculty['employee_id']}',
              style: TextStyle(
                color: cs.primary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: cs.onSurface.withOpacity(0.4)),
          onSelected: (value) => _handleMenuAction(value, faculty),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: Row(
                children: [
                  Icon(Icons.visibility_outlined, size: 20),
                  SizedBox(width: 12),
                  Text('View'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit_outlined, size: 20),
                  SizedBox(width: 12),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'qr',
              child: Row(
                children: [
                  Icon(Icons.qr_code_outlined, size: 20),
                  SizedBox(width: 12),
                  Text('Setup QR'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, size: 20, color: cs.error),
                  SizedBox(width: 12),
                  Text('Delete', style: TextStyle(color: cs.error)),
                ],
              ),
            ),
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
        Navigator.pushNamed(
          context,
          '/adminEditFaculty',
          arguments: faculty,
        ).then((_) => _loadFaculty());
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
    final cs = Theme.of(context).colorScheme;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cs.surface,
        title: const Text('Delete Faculty'),
        content: Text(
          'Are you sure you want to delete ${faculty['name']}?\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: cs.error),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiService.deleteFaculty(faculty['id']);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Faculty deleted successfully'),
              backgroundColor: Color(0xFF4CAF50),
            ),
          );
          _loadFaculty();
        }
      } on ApiException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message), backgroundColor: cs.error),
          );
        }
      }
    }
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
          const SizedBox(height: 16),
          Text(
            'No faculty found',
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
