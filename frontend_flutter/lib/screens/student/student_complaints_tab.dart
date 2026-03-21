// File: lib/screens/student/tabs/student_complaints_tab.dart
// Complaint submission and tracking with status updates

import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../core/session.dart';
import '../../models/complete_models.dart';

class StudentComplaintsTab extends StatefulWidget {
  const StudentComplaintsTab({super.key});

  @override
  State<StudentComplaintsTab> createState() => _StudentComplaintsTabState();
}

class _StudentComplaintsTabState extends State<StudentComplaintsTab> {
  List<Complaint> _complaints = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadComplaints();
  }

  Future<void> _loadComplaints() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getStudentComplaints(
        SessionManager.studentId!,
      );
      setState(() {
        _complaints = (data as List).map((json) {
          final safeJson = {
            'student_id': 0,
            'handled_by': null,
            'updated_at': null,
            'resolved_at': null,
            ...Map<String, dynamic>.from(json),
          };
          return Complaint.fromJson(safeJson);
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showNewComplaintDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NewComplaintScreen(),
        fullscreenDialog: true,
      ),
    ).then((_) => _loadComplaints());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1419),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00D9FF)),
            )
          : _complaints.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadComplaints,
              color: const Color(0xFF00D9FF),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _complaints.length,
                itemBuilder: (context, index) {
                  return _buildComplaintCard(_complaints[index]);
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showNewComplaintDialog,
        icon: const Icon(Icons.add),
        label: const Text('New Complaint'),
        backgroundColor: const Color(0xFF00D9FF),
        foregroundColor: const Color(0xFF0F1419),
      ),
    );
  }

  Widget _buildComplaintCard(Complaint complaint) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2332),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: complaint.statusColor.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showComplaintDetails(complaint),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Category badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D9FF).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        complaint.category,
                        style: const TextStyle(
                          color: Color(0xFF00D9FF),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: complaint.statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        complaint.statusDisplay,
                        style: TextStyle(
                          color: complaint.statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Title
                Text(
                  complaint.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 6),

                // Description preview
                Text(
                  complaint.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),

                // Admin response preview
                if (complaint.adminResponse != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: complaint.statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: complaint.statusColor.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.admin_panel_settings,
                          color: complaint.statusColor,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            complaint.adminResponse!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: complaint.statusColor,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 12),
                // Footer row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.white.withOpacity(0.4),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTime(complaint.createdAt),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),

                    // Priority
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(
                          complaint.priority,
                        ).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        complaint.priority,
                        style: TextStyle(
                          color: _getPriorityColor(complaint.priority),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showComplaintDetails(Complaint complaint) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A2332),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: complaint.statusColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          complaint.statusDisplay,
                          style: TextStyle(
                            color: complaint.statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00D9FF).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          complaint.category,
                          style: const TextStyle(
                            color: Color(0xFF00D9FF),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Title
                  Text(
                    complaint.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Description
                  Text(
                    complaint.description,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Escalated to principal banner
                  if (complaint.escalatedToPrincipal) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF9C27B0).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF9C27B0).withOpacity(0.4),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.escalator_warning,
                            color: Color(0xFF9C27B0),
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'This complaint has been forwarded to the Principal',
                              style: TextStyle(
                                color: Color(0xFF9C27B0),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Admin response
                  if (complaint.adminResponse != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: complaint.escalatedToPrincipal
                            ? const Color(0xFF9C27B0).withOpacity(0.1)
                            : const Color(0xFF00D9FF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: complaint.escalatedToPrincipal
                              ? const Color(0xFF9C27B0).withOpacity(0.3)
                              : const Color(0xFF00D9FF).withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                complaint.escalatedToPrincipal
                                    ? Icons.account_balance
                                    : Icons.admin_panel_settings,
                                color: complaint.escalatedToPrincipal
                                    ? const Color(0xFF9C27B0)
                                    : const Color(0xFF00D9FF),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                complaint.escalatedToPrincipal
                                    ? 'Principal Response'
                                    : 'HOD Response',
                                style: TextStyle(
                                  color: complaint.escalatedToPrincipal
                                      ? const Color(0xFF9C27B0)
                                      : const Color(0xFF00D9FF),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            complaint.adminResponse!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Meta info
                  _buildInfoRow(
                    Icons.schedule,
                    'Submitted',
                    _formatFullTime(complaint.createdAt),
                  ),

                  if (complaint.resolvedAt != null) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      Icons.check_circle,
                      'Resolved',
                      _formatFullTime(complaint.resolvedAt!),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Close button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00D9FF),
                        foregroundColor: const Color(0xFF0F1419),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white.withOpacity(0.5)),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
        ),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.report_problem_outlined,
            size: 80,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 20),
          Text(
            'No complaints submitted',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the button below to submit a complaint',
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'critical':
        return const Color(0xFFFF5722);
      case 'high':
        return const Color(0xFFFF9800);
      case 'medium':
        return const Color(0xFFFFC107);
      case 'low':
        return const Color(0xFF4CAF50);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }

  String _formatFullTime(DateTime time) {
    return '${time.day}/${time.month}/${time.year} at ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
}

// ============================================================================
// NEW COMPLAINT SCREEN
// ============================================================================

class NewComplaintScreen extends StatefulWidget {
  const NewComplaintScreen({super.key});

  @override
  State<NewComplaintScreen> createState() => _NewComplaintScreenState();
}

class _NewComplaintScreenState extends State<NewComplaintScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _category = 'Academic';
  String _priority = 'Medium';
  bool _isSubmitting = false;

  final List<String> _categories = [
    'Academic',
    'Infrastructure',
    'Hostel',
    'Transport',
    'Canteen',
    'Library',
    'Other',
  ];

  final List<String> _priorities = ['Low', 'Medium', 'High', 'Critical'];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitComplaint() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await ApiService.submitComplaint(
        studentId: SessionManager.studentId!,
        category: _category,
        priority: _priority,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Complaint submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1419),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2332),
        title: const Text('Submit Complaint'),
        actions: [
          if (_isSubmitting)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Color(0xFF00D9FF),
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category dropdown
              const Text(
                'Category',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _category,
                dropdownColor: const Color(0xFF1A2332),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF1A2332),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _category = value!),
              ),

              const SizedBox(height: 20),

              // Priority dropdown
              const Text(
                'Priority',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _priority,
                dropdownColor: const Color(0xFF1A2332),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF1A2332),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                items: _priorities.map((priority) {
                  return DropdownMenuItem(
                    value: priority,
                    child: Text(priority),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _priority = value!),
              ),

              const SizedBox(height: 20),

              // Title field
              const Text(
                'Title',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Brief title for your complaint',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                  filled: true,
                  fillColor: const Color(0xFF1A2332),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Description field
              const Text(
                'Description',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                style: const TextStyle(color: Colors.white),
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: 'Describe your complaint in detail...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                  filled: true,
                  fillColor: const Color(0xFF1A2332),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  if (value.trim().length < 20) {
                    return 'Description must be at least 20 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitComplaint,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00D9FF),
                    foregroundColor: const Color(0xFF0F1419),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Submit Complaint',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
