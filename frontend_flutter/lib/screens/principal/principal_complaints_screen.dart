// File: lib/screens/principal/principal_complaints_screen.dart
import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/session.dart';
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
      setState(() {
        _departments = List<Map<String, dynamic>>.from(data);
      });
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
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(title: const Text('Escalated Complaints')),
      body: Column(
        children: [
          // Department filter
          if (_departments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: DropdownButtonFormField<int?>(
                value: _selectedDeptId,
                dropdownColor: AppColors.bgCard,
                decoration: InputDecoration(
                  labelText: 'Department',
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.bgCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                style: const TextStyle(color: AppColors.textPrimary),
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

          // Status filter chips
          Container(
            color: AppColors.bgDark,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _buildFilterChip('All', 'all'),
                  _buildFilterChip('Escalated', 'escalated'),
                  _buildFilterChip('In Progress', 'in_progress'),
                  _buildFilterChip('Resolved', 'resolved'),
                ],
              ),
            ),
          ),

          // Complaints list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _complaints.isEmpty
                ? const Center(
                    child: Text(
                      'No escalated complaints',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadComplaints,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _complaints.length,
                      itemBuilder: (context, index) =>
                          _buildComplaintCard(_complaints[index]),
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
        onSelected: (_) {
          setState(() => _filterStatus = value);
          _loadComplaints();
        },
        backgroundColor: AppColors.bgCard,
        selectedColor: const Color(0xFF6A1B9A),
      ),
    );
  }

  Widget _buildComplaintCard(Map<String, dynamic> complaint) {
    final priority = complaint['priority'] ?? 'medium';
    final status = complaint['status'] ?? 'escalated';

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
                      color: AppColors.priorityColor(priority).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      priority.toUpperCase(),
                      style: TextStyle(
                        color: AppColors.priorityColor(priority),
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
                        status,
                      ).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      status.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(
                        color: AppColors.complaintStatusColor(status),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    complaint['created_at']?.toString().substring(0, 10) ?? '',
                    style: const TextStyle(
                      color: AppColors.textHint,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                complaint['title'] ?? 'No Title',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                complaint['description'] ?? '',
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
                    complaint['student_name'] ?? 'Unknown',
                    style: const TextStyle(
                      color: AppColors.textHint,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.warning_amber,
                    size: 14,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Escalated by HOD',
                    style: TextStyle(color: AppColors.warning, fontSize: 12),
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
    final responseController = TextEditingController(
      text: complaint['admin_response'] ?? '',
    );
    String selectedStatus = complaint['status'] ?? 'escalated';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setS) => AlertDialog(
          backgroundColor: AppColors.bgCard,
          title: Text(
            complaint['title'] ?? 'Complaint',
            style: const TextStyle(color: AppColors.textPrimary),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Student: ${complaint['student_name'] ?? 'Unknown'}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  'Category: ${complaint['category'] ?? 'N/A'}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  'Priority: ${complaint['priority'] ?? 'N/A'}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                Text(
                  complaint['description'] ?? '',
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  dropdownColor: AppColors.bgCard,
                  decoration: const InputDecoration(labelText: 'Status'),
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
                  onChanged: (v) => setS(() => selectedStatus = v!),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: responseController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Principal Response',
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
                  await ApiService.adminUpdateComplaint(complaint['id'], {
                    'status': selectedStatus,
                    'admin_response': responseController.text.trim(),
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(
                      content: Text('Complaint updated'),
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
                backgroundColor: const Color(0xFF6A1B9A),
              ),
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
