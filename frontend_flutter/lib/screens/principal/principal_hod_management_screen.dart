// File: lib/screens/principal/principal_hod_management_screen.dart
// Principal interface to list, edit, delete, and manage all HOD accounts

import 'package:flutter/material.dart';
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
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('HOD Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_outlined),
            onPressed: () async {
              await Navigator.pushNamed(context, '/principalAddHOD');
              _loadHODs();
            },
            tooltip: 'Register HOD',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: cs.primary))
          : _hods.isEmpty
              ? _buildEmptyState(cs)
              : RefreshIndicator(
                  onRefresh: _loadHODs,
                  color: cs.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _hods.length,
                    itemBuilder: (ctx, i) {
                      final hod = _hods[i];
                      return _buildHODCard(hod, cs);
                    },
                  ),
                ),
    );
  }

  Widget _buildHODCard(Map<String, dynamic> hod, ColorScheme cs) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.onSurface.withOpacity(0.08)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 26,
          backgroundColor: cs.primary.withOpacity(0.1),
          child: Text(
            (hod['name'] ?? 'H').toString().substring(0, 1).toUpperCase(),
            style: TextStyle(
              color: cs.primary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        title: Text(
          hod['name'] ?? 'Unknown HOD',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              hod['email'] ?? '',
              style: TextStyle(
                color: cs.onSurface.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: hod['department'] != null
                    ? cs.secondaryContainer
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                hod['department_name'] != null
                    ? hod['department_name']
                    : 'Unassigned',
                style: TextStyle(
                  color: hod['department'] != null
                      ? cs.onSecondaryContainer
                      : Colors.orange.shade800,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: cs.onSurface.withOpacity(0.4)),
          onSelected: (val) async {
            if (val == 'edit') _showEditDialog(hod);
            if (val == 'details' || val == 'qr') {
              final route = val == 'details'
                  ? '/principalHODDetails'
                  : '/principalGenerateHODQR';
              await Navigator.pushNamed(context, route, arguments: hod);
              _loadHODs();
            }
            if (val == 'delete') _confirmDelete(hod);
          },
          itemBuilder: (ctx) => [
            const PopupMenuItem(
              value: 'details',
              child: Row(
                children: [
                  Icon(Icons.visibility_outlined, size: 20),
                  SizedBox(width: 10),
                  Text('View Details'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit_outlined, size: 20),
                  SizedBox(width: 10),
                  Text('Edit Account'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'qr',
              child: Row(
                children: [
                  Icon(Icons.qr_code_2_rounded, size: 20),
                  SizedBox(width: 10),
                  Text('Generate QR'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, size: 20, color: cs.error),
                  SizedBox(width: 10),
                  Text('Remove HOD', style: TextStyle(color: cs.error)),
                ],
              ),
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
  }

  Future<void> _showEditDialog(Map<String, dynamic> hod) async {
    final cs = Theme.of(context).colorScheme;
    final nameCtrl = TextEditingController(text: hod['name']);
    final emailCtrl = TextEditingController(text: hod['email']);
    List<Map<String, dynamic>> departments = [];
    int? selectedDeptId = hod['department']?['id'];

    try {
      final data = await ApiService.getPrincipalDepartments();
      departments = List<Map<String, dynamic>>.from(data);
    } catch (_) {}

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: cs.surface,
          title: const Text('Update HOD Account'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: Icon(Icons.alternate_email),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: selectedDeptId,
                  dropdownColor: cs.surface,
                  decoration: const InputDecoration(
                    labelText: 'Department Assignment',
                    prefixIcon: Icon(Icons.business_outlined),
                  ),
                  items: departments
                      .map(
                        (d) => DropdownMenuItem<int>(
                          value: d['id'] as int,
                          child: Text(
                            '${d['code']} · ${d['name']}',
                            style: const TextStyle(fontSize: 13),
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
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await ApiService.updateHOD(
                    id: hod['id'],
                    name: nameCtrl.text.trim(),
                    email: emailCtrl.text.trim(),
                    departmentId: selectedDeptId,
                  );
                  _loadHODs();
                } on ApiException catch (e) {
                  if (mounted) _showSnack(e.message, isError: true);
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> hod) async {
    final cs = Theme.of(context).colorScheme;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surface,
        title: const Text('Remove HOD'),
        content: Text(
          'Are you sure you want to remove ${hod['name']}? This will deauthorize their access.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: cs.error),
            child: const Text(
              'Remove Account',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiService.deleteHOD(hod['id']);
        _loadHODs();
      } on ApiException catch (e) {
        if (mounted) _showSnack(e.message, isError: true);
      }
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : const Color(0xFF4CAF50),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.manage_accounts_outlined,
            size: 80,
            color: cs.onSurface.withOpacity(0.1),
          ),
          const SizedBox(height: 16),
          Text(
            'No HODs registered yet',
            style: TextStyle(color: cs.onSurface.withOpacity(0.4)),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () async {
              await Navigator.pushNamed(context, '/principalAddHOD');
              _loadHODs();
            },
            icon: const Icon(Icons.add),
            label: const Text('Add First HOD'),
          ),
        ],
      ),
    );
  }
}
