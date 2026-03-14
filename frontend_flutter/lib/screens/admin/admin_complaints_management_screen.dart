// File: lib/screens/admin/admin_complaints_management_screen.dart
import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
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

  @override
  void initState() {
    super.initState();
    _loadComplaints();
  }

  Future<void> _loadComplaints() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getAllComplaints(
        // ✅ Real API
        status: _filterStatus == 'all' ? null : _filterStatus,
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
          SnackBar(content: Text(e.message), backgroundColor: AppColors.danger),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredComplaints {
    if (_filterStatus == 'all') return _complaints;
    return _complaints.where((c) => c['status'] == _filterStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(title: const Text('Complaints Management')),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildFilterChip('All', 'all'),
                _buildFilterChip('Pending', 'pending'),
                _buildFilterChip('In Progress', 'in_progress'),
                _buildFilterChip('Resolved', 'resolved'),
              ],
            ),
          ),

          // Complaints List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredComplaints.isEmpty
                ? const Center(
                    child: Text(
                      'No complaints found',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadComplaints,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredComplaints.length,
                      itemBuilder: (context, index) {
                        return _buildComplaintCard(_filteredComplaints[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterStatus == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _filterStatus = value);
          _loadComplaints(); // ✅ Added this
        },
        backgroundColor: AppColors.bgCard,
        selectedColor: AppColors.danger,
      ),
    );
  }

  Widget _buildComplaintCard(Map<String, dynamic> complaint) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.bgCard,
      child: InkWell(
        onTap: () => _showComplaintDialog(complaint),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.priorityColor(
                        complaint['priority'],
                      ).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      complaint['priority'],
                      style: TextStyle(
                        color: AppColors.priorityColor(complaint['priority']),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.complaintStatusColor(
                        complaint['status'],
                      ).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      complaint['status']
                          .toString()
                          .replaceAll('_', ' ')
                          .toUpperCase(),
                      style: TextStyle(
                        color: AppColors.complaintStatusColor(
                          complaint['status'],
                        ),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    complaint['date'],
                    style: const TextStyle(
                      color: AppColors.textHint,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                complaint['title'],
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                complaint['description'],
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person, size: 14, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text(
                    complaint['student_name'],
                    style: const TextStyle(
                      color: AppColors.textHint,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.category,
                    size: 14,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    complaint['category'],
                    style: const TextStyle(
                      color: AppColors.textHint,
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

  void _showComplaintDialog(Map<String, dynamic> complaint) {
    final responseController = TextEditingController();
    String selectedStatus = complaint['status'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(complaint['title']),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Student: ${complaint['student_name']}'),
                const SizedBox(height: 8),
                Text('Category: ${complaint['category']}'),
                const SizedBox(height: 8),
                Text('Priority: ${complaint['priority']}'),
                const SizedBox(height: 16),
                Text(complaint['description']),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: const InputDecoration(labelText: 'Status'),
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
                  onChanged: (v) => setState(() => selectedStatus = v!),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: responseController,
                  decoration: const InputDecoration(
                    labelText: 'Admin Response',
                    hintText: 'Enter your response...',
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
                  await ApiService.adminUpdateComplaint(
                    // ✅ Real API
                    complaint['id'],
                    {
                      'status': selectedStatus,
                      'admin_response': responseController.text.trim(),
                    },
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(
                      content: Text('Complaint updated successfully'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  _loadComplaints();
                } on ApiException catch (e) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(
                      content: Text(e.message),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
              ),
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
