// File: lib/screens/admin/admin_complaints_management_screen.dart
// HOD/Admin interface to filter, resolve, and escalate student complaints

import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class AdminComplaintsManagementScreen extends StatefulWidget {
  const AdminComplaintsManagementScreen({super.key});

  @override
  State<AdminComplaintsManagementScreen> createState() =>
      _AdminComplaintsManagementScreenState();
}

class _AdminComplaintsManagementScreenState
    extends State<AdminComplaintsManagementScreen> {
  String _filterStatus = 'all';
  List<Map<String, dynamic>> _complaints = [];
  bool _isLoading = true;

  // Semantic Status Colors
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color infoBlue = Color(0xFF2196F3);

  @override
  void initState() {
    super.initState();
    _loadComplaints();
  }

  Future<void> _loadComplaints() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getHODComplaints(
        status: _filterStatus == 'all' || _filterStatus == 'escalated'
            ? null
            : _filterStatus,
      );
      if (mounted) {
        setState(() {
          _complaints = List<Map<String, dynamic>>.from(data);
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

  List<Map<String, dynamic>> get _filteredComplaints {
    if (_filterStatus == 'all') return _complaints;
    if (_filterStatus == 'escalated') {
      return _complaints
          .where((c) => c['escalated_to_principal'] == true)
          .toList();
    }
    return _complaints.where((c) => c['status'] == _filterStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Complaints Management')),
      body: Column(
        children: [
          // Filter Chips
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border(
                bottom: BorderSide(color: cs.onSurface.withOpacity(0.05)),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  _buildFilterChip('All', 'all', cs),
                  _buildFilterChip('Pending', 'pending', cs),
                  _buildFilterChip('In Progress', 'in_progress', cs),
                  _buildFilterChip('Resolved', 'resolved', cs),
                  _buildFilterChip('Rejected', 'rejected', cs),
                  _buildFilterChip('Escalated', 'escalated', cs),
                ],
              ),
            ),
          ),

          // Complaints List
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: cs.primary))
                : _filteredComplaints.isEmpty
                ? _buildEmptyState(cs)
                : RefreshIndicator(
                    onRefresh: _loadComplaints,
                    color: cs.primary,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredComplaints.length,
                      itemBuilder: (context, index) {
                        return _buildComplaintCard(
                          _filteredComplaints[index],
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

  Widget _buildFilterChip(String label, String value, ColorScheme cs) {
    final isSelected = _filterStatus == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
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
    final priority = (complaint['priority'] ?? 'low').toString().toLowerCase();
    final status = (complaint['status'] ?? 'pending').toString().toLowerCase();

    final Color priorityColor = priority == 'high' || priority == 'urgent'
        ? cs.error
        : priority == 'medium'
        ? warningOrange
        : successGreen;

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
                  if (complaint['escalated_to_principal'] == true)
                    _buildBadge('ESCALATED', cs.error),
                  const Spacer(),
                  Text(
                    _formatDate(complaint['created_at']),
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
                  Icon(Icons.person_outline, size: 14, color: cs.primary),
                  const SizedBox(width: 4),
                  Text(
                    complaint['student_name'] ?? 'Unknown',
                    style: TextStyle(
                      color: cs.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.label_outline,
                    size: 14,
                    color: cs.onSurface.withOpacity(0.4),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    complaint['category'] ?? 'General',
                    style: TextStyle(
                      color: cs.onSurface.withOpacity(0.4),
                      fontSize: 12,
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

  String _formatDate(dynamic date) {
    final str = date?.toString() ?? '';
    return str.length > 10 ? str.substring(0, 10) : str;
  }

  void _showComplaintDialog(Map<String, dynamic> complaint) {
    final cs = Theme.of(context).colorScheme;
    final responseController = TextEditingController();
    String selectedStatus = complaint['status'] ?? 'pending';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: cs.surface,
          title: Text(complaint['title'] ?? 'Complaint Details'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Student: ${complaint['student_name'] ?? 'Unknown'}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  complaint['description'] ?? '',
                  style: TextStyle(color: cs.onSurface.withOpacity(0.7)),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: const InputDecoration(labelText: 'Action Status'),
                  dropdownColor: cs.surface,
                  items: const [
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
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
                  decoration: const InputDecoration(
                    labelText: 'Response to Student',
                    hintText: 'Provide details about the action taken...',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            if (complaint['escalated_to_principal'] != true)
              TextButton(
                onPressed: () async {
                  await ApiService.escalateComplaint(complaint['id']);
                  if (mounted) {
                    Navigator.pop(context);
                    _loadComplaints();
                  }
                },
                child: Text('Escalate', style: TextStyle(color: cs.error)),
              ),
            ElevatedButton(
              onPressed: () async {
                await ApiService.adminUpdateComplaint(complaint['id'], {
                  'status': selectedStatus,
                  'admin_response': responseController.text.trim(),
                });
                if (mounted) {
                  Navigator.pop(context);
                  _loadComplaints();
                }
              },
              child: const Text('Update'),
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
            Icons.inbox_outlined,
            size: 80,
            color: cs.onSurface.withOpacity(0.1),
          ),
          const SizedBox(height: 16),
          Text(
            'No complaints found',
            style: TextStyle(
              color: cs.onSurface.withOpacity(0.5),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
