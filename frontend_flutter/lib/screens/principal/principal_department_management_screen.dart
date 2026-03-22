// File: lib/screens/principal/principal_department_management_screen.dart
// Principal interface to list, edit, and manage all academic departments

import 'package:flutter/material.dart';
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
    final cs = Theme.of(context).colorScheme;
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surface,
        title: const Text('Add New Department'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: TextStyle(color: cs.onSurface),
              decoration: const InputDecoration(
                labelText: 'Department Name',
                hintText: 'e.g. Computer Science',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codeCtrl,
              style: TextStyle(color: cs.onSurface),
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Department Code',
                hintText: 'e.g. CSE',
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
            onPressed: () async {
              if (nameCtrl.text.isEmpty || codeCtrl.text.isEmpty) return;
              Navigator.pop(ctx);
              try {
                await ApiService.createDepartment(
                  name: nameCtrl.text.trim(),
                  code: codeCtrl.text.trim().toUpperCase(),
                );
                _loadDepartments();
              } on ApiException catch (e) {
                if (mounted) _showError(e.message);
              }
            },
            child: const Text('Register'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> dept) {
    final cs = Theme.of(context).colorScheme;
    final nameCtrl = TextEditingController(text: dept['name']);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surface,
        title: Text('Edit ${dept['code']}'),
        content: TextField(
          controller: nameCtrl,
          style: TextStyle(color: cs.onSurface),
          decoration: const InputDecoration(
            labelText: 'Updated Department Name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ApiService.updateDepartment(
                  id: dept['id'],
                  name: nameCtrl.text.trim(),
                );
                _loadDepartments();
              } on ApiException catch (e) {
                if (mounted) _showError(e.message);
              }
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteDepartment(Map<String, dynamic> dept) async {
    final cs = Theme.of(context).colorScheme;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surface,
        title: const Text('Delete Department'),
        content: Text(
          'Are you sure you want to delete ${dept['name']}? This will affect linked HODs and faculty.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: cs.error),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiService.deleteDepartment(dept['id']);
        _loadDepartments();
      } on ApiException catch (e) {
        if (mounted) _showError(e.message);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Departments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_business_outlined),
            onPressed: _showAddDepartmentDialog,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: cs.primary))
          : _departments.isEmpty
          ? _buildEmptyState(cs)
          : RefreshIndicator(
              onRefresh: _loadDepartments,
              color: cs.primary,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _departments.length,
                itemBuilder: (ctx, i) {
                  final dept = _departments[i];
                  final hasHOD = dept['hod'] != null;

                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: cs.onSurface.withOpacity(0.1)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: cs.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.account_tree_outlined,
                          color: cs.primary,
                        ),
                      ),
                      title: Text(
                        dept['name'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            'Code: ${dept['code']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurface.withOpacity(0.5),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                hasHOD
                                    ? Icons.check_circle_outline
                                    : Icons.error_outline,
                                size: 14,
                                color: hasHOD ? Colors.green : Colors.orange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                hasHOD
                                    ? 'HOD: ${dept['hod']['name']}'
                                    : 'No HOD Assigned',
                                style: TextStyle(
                                  color: hasHOD ? Colors.green : Colors.orange,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert,
                          color: cs.onSurface.withOpacity(0.4),
                        ),
                        onSelected: (val) {
                          if (val == 'edit') _showEditDialog(dept);
                          if (val == 'delete') _deleteDepartment(dept);
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined, size: 20),
                                SizedBox(width: 10),
                                Text('Edit Name'),
                              ],
                            ),
                          ),

                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_outline,
                                  size: 20,
                                  color: cs.error,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Delete',
                                  style: TextStyle(color: cs.error),
                                ),
                              ],
                            ),
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

  void _showEditSectionsDialog(Map<String, dynamic> dept) async {
    final cs = Theme.of(context).colorScheme;
    final List<String> allSections = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];
    final customCtrl = TextEditingController();

    // Load current sections
    List<String> selected = [];
    try {
      selected = await ApiService.getDepartmentSections(dept['id']);
    } catch (_) {}
    if (selected.isEmpty) selected = ['A', 'B'];

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text('Sections — ${dept['code']}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...allSections.map((s) {
                      final isSelected = selected.contains(s);
                      return GestureDetector(
                        onTap: () => setD(() {
                          isSelected ? selected.remove(s) : selected.add(s);
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? cs.primary.withOpacity(0.15)
                                : cs.surfaceVariant.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? cs.primary
                                  : cs.onSurface.withOpacity(0.1),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Text(
                            'Sec $s',
                            style: TextStyle(
                              color: isSelected
                                  ? cs.primary
                                  : cs.onSurface.withOpacity(0.7),
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }),
                    // Show custom sections not in allSections
                    ...selected
                        .where((s) => !allSections.contains(s))
                        .map(
                          (s) => GestureDetector(
                            onTap: () => setD(() => selected.remove(s)),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: cs.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: cs.primary),
                              ),
                              child: Text(
                                'Sec $s',
                                style: TextStyle(color: cs.primary),
                              ),
                            ),
                          ),
                        ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: customCtrl,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Custom section',
                          hintText: 'e.g. Z',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        final s = customCtrl.text.trim().toUpperCase();
                        if (s.isNotEmpty && !selected.contains(s)) {
                          setD(() {
                            selected.add(s);
                            customCtrl.clear();
                          });
                        }
                      },
                      icon: Icon(Icons.add_circle_outline, color: cs.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await ApiService.updateDepartmentSections(
                    dept['id'],
                    selected,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Sections updated'),
                        backgroundColor: Color(0xFF4CAF50),
                      ),
                    );
                    _loadDepartments();
                  }
                } on ApiException catch (e) {
                  if (mounted) _showError(e.message);
                }
              },
              child: const Text('Save Sections'),
            ),
          ],
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
            Icons.business_outlined,
            size: 80,
            color: cs.onSurface.withOpacity(0.1),
          ),
          const SizedBox(height: 16),
          Text(
            'No departments registered',
            style: TextStyle(color: cs.onSurface.withOpacity(0.4)),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _showAddDepartmentDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add First Department'),
          ),
        ],
      ),
    );
  }
}
