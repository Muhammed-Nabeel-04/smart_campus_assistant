// lib/screens/principal/principal_department_management_screen.dart
import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../services/api_service.dart';

class PrincipalDepartmentManagementScreen extends StatefulWidget {
  const PrincipalDepartmentManagementScreen({super.key});

  @override
  State<PrincipalDepartmentManagementScreen> createState() =>
      _PrincipalDepartmentManagementScreenState();
}

class _PrincipalDepartmentManagementScreenState
    extends State<PrincipalDepartmentManagementScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _departments = [];

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getAllDepartments();
      if (mounted) {
        setState(() {
          _departments = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddDepartmentDialog() {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: const Text(
          'Add Department',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Department Name',
                hintText: 'Computer Science Engineering',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: codeCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Department Code',
                hintText: 'CSE',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6A1B9A),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ApiService.createDepartment(
                  name: nameCtrl.text.trim(),
                  code: codeCtrl.text.trim().toUpperCase(),
                );
                _loadDepartments();
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
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> dept) {
    final nameCtrl = TextEditingController(text: dept['name']);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: Text(
          'Edit ${dept['code']}',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: nameCtrl,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(labelText: 'Department Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6A1B9A),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ApiService.updateDepartment(
                  id: dept['id'],
                  name: nameCtrl.text.trim(),
                );
                _loadDepartments();
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
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteDepartment(Map<String, dynamic> dept) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: const Text(
          'Delete Department',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Delete ${dept['name']}? This cannot be undone.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await ApiService.deleteDepartment(dept['id']);
        _loadDepartments();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Departments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddDepartmentDialog,
            tooltip: 'Add Department',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _departments.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_tree,
                    size: 80,
                    color: AppColors.textSecondary.withOpacity(0.4),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No departments yet',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _showAddDepartmentDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6A1B9A),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Department'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadDepartments,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _departments.length,
                itemBuilder: (ctx, i) {
                  final dept = _departments[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    color: AppColors.bgCard,
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6A1B9A).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.account_tree,
                          color: Color(0xFF6A1B9A),
                        ),
                      ),
                      title: Text(
                        dept['name'] ?? '',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Code: ${dept['code']}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            dept['hod'] != null
                                ? 'HOD: ${dept['hod']['name']}'
                                : 'No HOD assigned',
                            style: TextStyle(
                              color: dept['hod'] != null
                                  ? AppColors.success
                                  : AppColors.warning,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (val) {
                          if (val == 'edit') _showEditDialog(dept);
                          if (val == 'delete') _deleteDepartment(dept);
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit'),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
