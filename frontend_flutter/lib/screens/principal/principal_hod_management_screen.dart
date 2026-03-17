// lib/screens/principal/principal_hod_management_screen.dart
import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../services/api_service.dart';

class PrincipalHODManagementScreen extends StatefulWidget {
  const PrincipalHODManagementScreen({super.key});

  @override
  State<PrincipalHODManagementScreen> createState() =>
      _PrincipalHODManagementScreenState();
}

class _PrincipalHODManagementScreenState
    extends State<PrincipalHODManagementScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _hods = [];

  @override
  void initState() {
    super.initState();
    _loadHODs();
  }

  Future<void> _loadHODs() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getAllHODs();
      if (mounted) {
        setState(() {
          _hods = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('HOD Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () async {
              await Navigator.pushNamed(context, '/principalAddHOD');
              _loadHODs();
            },
            tooltip: 'Add HOD',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hods.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.manage_accounts,
                    size: 80,
                    color: AppColors.textSecondary.withOpacity(0.4),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No HODs added yet',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.pushNamed(context, '/principalAddHOD');
                      _loadHODs();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Add HOD'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadHODs,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _hods.length,
                itemBuilder: (ctx, i) {
                  final hod = _hods[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    color: AppColors.bgCard,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF1565C0),
                        child: Text(
                          (hod['name'] ?? 'H')
                              .toString()
                              .substring(0, 1)
                              .toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(
                        hod['name'] ?? '',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hod['email'] ?? '',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            hod['department'] != null
                                ? 'Dept: ${hod['department']['name']} (${hod['department']['code']})'
                                : 'No department assigned',
                            style: TextStyle(
                              color: hod['department'] != null
                                  ? AppColors.info
                                  : AppColors.warning,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (val) async {
                          if (val == 'edit') {
                            _showEditDialog(hod);
                          }
                          if (val == 'details') {
                            await Navigator.pushNamed(
                              context,
                              '/principalHODDetails',
                              arguments: hod,
                            );
                            _loadHODs();
                          }
                          if (val == 'qr') {
                            await Navigator.pushNamed(
                              context,
                              '/principalGenerateHODQR',
                              arguments: hod,
                            );
                          }
                          if (val == 'delete') {
                            _confirmDelete(hod);
                          }
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(
                            value: 'details',
                            child: Text('View Details'),
                          ),
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit'),
                          ),
                          const PopupMenuItem(
                            value: 'qr',
                            child: Text('Generate QR'),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete'),
                          ),
                        ],
                      ),
                      onTap: () async {
                        await Navigator.pushNamed(
                          context,
                          '/principalHODDetails',
                          arguments: hod,
                        );
                        _loadHODs();
                      },
                    ),
                  );
                },
              ),
            ),
    );
  }

  Future<void> _showEditDialog(Map<String, dynamic> hod) async {
    final nameCtrl = TextEditingController(text: hod['name']);
    final emailCtrl = TextEditingController(text: hod['email']);
    List<Map<String, dynamic>> departments = [];
    int? selectedDeptId = hod['department']?['id'];

    // Load departments
    try {
      final data = await ApiService.getPrincipalDepartments();
      departments = List<Map<String, dynamic>>.from(data);
    } catch (_) {}

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.bgCard,
          title: const Text(
            'Edit HOD',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 12),
                if (departments.isNotEmpty)
                  DropdownButtonFormField<int>(
                    value: selectedDeptId,
                    decoration: const InputDecoration(
                      labelText: 'Department',
                      prefixIcon: Icon(Icons.account_tree),
                    ),
                    items: departments
                        .map(
                          (d) => DropdownMenuItem<int>(
                            value: d['id'] as int,
                            child: Text(
                              '${d['code']} · ${d['name']}',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setDialogState(() => selectedDeptId = v),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await ApiService.updateHOD(
                    id: hod['id'],
                    name: nameCtrl.text.trim().isEmpty
                        ? null
                        : nameCtrl.text.trim(),
                    email: emailCtrl.text.trim().isEmpty
                        ? null
                        : emailCtrl.text.trim(),
                    departmentId: selectedDeptId,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('HOD updated successfully'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                    _loadHODs();
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
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> hod) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: const Text(
          'Delete HOD',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Delete ${hod['name']}? This cannot be undone.',
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
        await ApiService.deleteHOD(hod['id']);
        _loadHODs();
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
