// File: lib/screens/principal/principal_complaints_screen.dart
// Principal interface to review and resolve complaints escalated from the HOD level

import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class PrincipalComplaintsScreen extends StatefulWidget {
  const PrincipalComplaintsScreen({super.key});

  @override
  State<PrincipalComplaintsScreen> createState() =>
      _PrincipalComplaintsScreenState();
}

class _PrincipalComplaintsScreenState extends State<PrincipalComplaintsScreen> {
  String _filterStatus = 'all';
  int? _selectedDeptId;
  List<Map<String, dynamic>> _complaints = [];
  List<Map<String, dynamic>> _departments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDepartments();
    _loadComplaints();
  }

  Future<void> _loadDepartments() async {
    try {
      final data = await ApiService.getPrincipalDepartments();
      if (mounted) {
        setState(() {
          _departments = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (_) {}
  }

  Future<void> _loadComplaints() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getPrincipalComplaints(
        status: _filterStatus == 'all' ? null : _filterStatus,
        departmentId: _selectedDeptId,
      );
      if (mounted) {
        setState(() {
          _complaints = List<Map<String, dynamic>>.from(data);
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
      appBar: AppBar(title: const Text('Escalated Complaints')),
      body: Column(
        children: [
          // Department Filter
          if (_departments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: DropdownButtonFormField<int?>(
                value: _selectedDeptId,
                dropdownColor: cs.surface,
                decoration: const InputDecoration(
                  labelText: 'Filter by Department',
                  prefixIcon: Icon(Icons.business_outlined),
                ),
                style: TextStyle(color: cs.onSurface),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('All Departments'),
                  ),
                  ..._departments.map(
                    (d) => DropdownMenuItem<int?>(
                      value: d['id'],
                      child: Text(d['name'] ?? ''),
                    ),
                  ),
                ],
                onChanged: (val) {
                  setState(() => _selectedDeptId = val);
                  _loadComplaints();
                },
              ),
            ),

          // Status Filter Chips
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border(
                bottom: BorderSide(color: cs.onSurface.withOpacity(0.05)),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildFilterChip('All', 'all', cs),
                  _buildFilterChip('Escalated', 'escalated', cs),
                  _buildFilterChip('In Progress', 'in_progress', cs),
                  _buildFilterChip('Resolved', 'resolved', cs),
                ],
              ),
            ),
          ),

          // Complaints List
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: cs.primary))
                : _complaints.isEmpty
                ? _buildEmptyState(cs)
                : RefreshIndicator(
                    onRefresh: _loadComplaints,
                    color: cs.primary,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _complaints.length,
                      itemBuilder: (context, index) =>
                          _buildComplaintCard(_complaints[index], cs),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, ColorScheme cs) {
    final isSelected = _filterStatus == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          setState(() => _filterStatus = value);
          _loadComplaints();
        },
        selectedColor: cs.primary.withOpacity(0.2),
        checkmarkColor: cs.primary,
        labelStyle: TextStyle(
          color: isSelected ? cs.primary : cs.onSurface.withOpacity(0.7),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildComplaintCard(Map<String, dynamic> complaint, ColorScheme cs) {
    final priority = (complaint['priority'] ?? 'medium')
        .toString()
        .toLowerCase();
    final status = (complaint['status'] ?? 'escalated')
        .toString()
        .toLowerCase();

    // Priority Colors
    final Color priorityColor = priority == 'high' || priority == 'urgent'
        ? cs.error
        : (priority == 'medium' ? Colors.orange : Colors.green);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.onSurface.withOpacity(0.1)),
      ),
      child: InkWell(
        onTap: () => _showComplaintDialog(complaint),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildBadge(priority.toUpperCase(), priorityColor),
                  const SizedBox(width: 8),
                  _buildBadge('ESCALATED', cs.primary),
                  const Spacer(),
                  Text(
                    complaint['created_at']?.toString().substring(0, 10) ?? '',
                    style: TextStyle(
                      color: cs.onSurface.withOpacity(0.4),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                complaint['title'] ?? 'No Title',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                complaint['description'] ?? '',
                style: TextStyle(
                  color: cs.onSurface.withOpacity(0.6),
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 14,
                    color: cs.onSurface.withOpacity(0.4),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    complaint['student_name'] ?? 'Unknown',
                    style: TextStyle(
                      color: cs.onSurface.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 14,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Higher Authority Action Required',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showComplaintDialog(Map<String, dynamic> complaint) {
    final cs = Theme.of(context).colorScheme;
    final responseController = TextEditingController(
      text: complaint['admin_response'] ?? '',
    );
    String selectedStatus = complaint['status'] ?? 'escalated';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: cs.surface,
          title: Text(complaint['title'] ?? 'Complaint Review'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildModalDetail(
                  'Student',
                  complaint['student_name'] ?? 'Unknown',
                  cs,
                ),
                _buildModalDetail(
                  'Category',
                  complaint['category'] ?? 'N/A',
                  cs,
                ),
                const SizedBox(height: 12),
                Text(
                  complaint['description'] ?? '',
                  style: TextStyle(
                    color: cs.onSurface.withOpacity(0.8),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  dropdownColor: cs.surface,
                  decoration: const InputDecoration(
                    labelText: 'Final Resolution Status',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'escalated',
                      child: Text('Escalated'),
                    ),
                    DropdownMenuItem(
                      value: 'in_progress',
                      child: Text('In Progress'),
                    ),
                    DropdownMenuItem(
                      value: 'resolved',
                      child: Text('Resolved'),
                    ),
                    DropdownMenuItem(
                      value: 'rejected',
                      child: Text('Rejected'),
                    ),
                  ],
                  onChanged: (v) => setModalState(() => selectedStatus = v!),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: responseController,
                  style: TextStyle(color: cs.onSurface),
                  decoration: const InputDecoration(
                    labelText: 'Principal Decision/Response',
                    hintText: 'Enter final remarks for the student...',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await ApiService.adminUpdateComplaint(complaint['id'], {
                    'status': selectedStatus,
                    'admin_response': responseController.text.trim(),
                  });
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Complaint status updated'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    _loadComplaints();
                  }
                } on ApiException catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.message),
                      backgroundColor: cs.error,
                    ),
                  );
                }
              },
              child: const Text('Update Decision'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModalDetail(String label, String value, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: TextStyle(color: cs.onSurface, fontSize: 13),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(
              text: value,
              style: TextStyle(color: cs.onSurface.withOpacity(0.7)),
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
            Icons.assignment_turned_in_outlined,
            size: 80,
            color: cs.onSurface.withOpacity(0.1),
          ),
          const SizedBox(height: 16),
          Text(
            'No escalated complaints',
            style: TextStyle(
              color: cs.onSurface.withOpacity(0.4),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
