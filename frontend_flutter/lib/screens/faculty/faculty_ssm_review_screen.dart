// File: lib/screens/faculty/faculty_ssm_review_screen.dart
// ─────────────────────────────────────────────────────────
// Faculty Mentor Review Screen
// Faculty can see all submitted SSM forms and approve / reject them
// ─────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../../models/ssm_models.dart';
import '../../services/api_service.dart';

class FacultySSMReviewScreen extends StatefulWidget {
  const FacultySSMReviewScreen({super.key});

  @override
  State<FacultySSMReviewScreen> createState() => _FacultySSMReviewScreenState();
}

class _FacultySSMReviewScreenState extends State<FacultySSMReviewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _error;

  List<Map<String, dynamic>> _submitted = [];
  List<Map<String, dynamic>> _mentorApproved = [];
  List<Map<String, dynamic>> _mentorRejected = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final all = await ApiService.ssmGetSubmissions();
      if (mounted) {
        setState(() {
          _submitted = all
              .where((s) => s['status'] == 'submitted')
              .map((s) => Map<String, dynamic>.from(s))
              .toList();
          _mentorApproved = all
              .where((s) => s['status'] == 'mentor_approved')
              .map((s) => Map<String, dynamic>.from(s))
              .toList();
          _mentorRejected = all
              .where((s) => s['status'] == 'mentor_rejected')
              .map((s) => Map<String, dynamic>.from(s))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SSM Reviews'),
        centerTitle: false,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Pending'),
                  if (_submitted.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF9800),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_submitted.length}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Approved'),
            const Tab(text: 'Rejected'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: cs.primary))
          : _error != null
              ? _buildError(cs)
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildList(_submitted, isPending: true),
                    _buildList(_mentorApproved),
                    _buildList(_mentorRejected),
                  ],
                ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> items,
      {bool isPending = false}) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined,
                size: 56,
                color: Theme.of(context)
                    .colorScheme
                    .onBackground
                    .withOpacity(0.2)),
            const SizedBox(height: 16),
            Text('No submissions here',
                style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onBackground
                        .withOpacity(0.4))),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, i) => _buildCard(items[i], isPending: isPending),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> sub, {bool isPending = false}) {
    final cs = Theme.of(context).colorScheme;
    final score = (sub['total_score'] as num?)?.toDouble() ?? 0.0;
    final stars = sub['star_rating'] as int? ?? 0;
    final status = sub['status'] as String? ?? '';

    Color statusColor;
    switch (status) {
      case 'submitted':
        statusColor = const Color(0xFFFF9800);
        break;
      case 'mentor_approved':
        statusColor = const Color(0xFF4CAF50);
        break;
      case 'mentor_rejected':
        statusColor = cs.error;
        break;
      default:
        statusColor = cs.onSurface.withOpacity(0.4);
    }

    // Score color
    Color scoreColor;
    if (score >= 85)
      scoreColor = const Color(0xFF4CAF50);
    else if (score >= 70)
      scoreColor = const Color(0xFF2196F3);
    else if (score >= 55)
      scoreColor = const Color(0xFFFF9800);
    else
      scoreColor = cs.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isPending
              ? const Color(0xFFFF9800).withOpacity(0.4)
              : cs.onSurface.withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Student avatar
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: scoreColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      (sub['student_name'] as String? ?? 'S')[0].toUpperCase(),
                      style: TextStyle(
                        color: scoreColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sub['student_name'] ?? 'Unknown Student',
                        style: TextStyle(
                          color: cs.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        '${sub['register_number'] ?? ''} • ${sub['department'] ?? ''} ${sub['year'] ?? ''}',
                        style: TextStyle(
                          color: cs.onSurface.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // Score badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: scoreColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        score.toStringAsFixed(1),
                        style: TextStyle(
                          color: scoreColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(
                          5,
                          (i) => Icon(
                                i < stars ? Icons.star : Icons.star_border,
                                color: const Color(0xFFFFB300),
                                size: 12,
                              )),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Quick Stats ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _quickStat(
                    'GPA',
                    sub['gpa'] != null
                        ? (sub['gpa'] as num).toStringAsFixed(1)
                        : '—',
                    const Color(0xFF4CAF50),
                    cs),
                const SizedBox(width: 8),
                _quickStat(
                    'Attend.',
                    sub['attendance_input'] != null
                        ? '${(sub['attendance_input'] as num).toStringAsFixed(0)}%'
                        : '—',
                    const Color(0xFF2196F3),
                    cs),
                const SizedBox(width: 8),
                _quickStat(
                    'Activities',
                    '${(sub['activities'] as List?)?.length ?? 0}',
                    const Color(0xFF9C27B0),
                    cs),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status == 'submitted'
                        ? 'Pending'
                        : status == 'mentor_approved'
                            ? 'Approved'
                            : 'Rejected',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Actions ─────────────────────────────────────
          if (isPending)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showDetailsSheet(sub),
                      icon: const Icon(Icons.visibility_outlined, size: 16),
                      label: const Text('View'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _reviewDialog(sub['id'] as int, 'rejected'),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Reject'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _reviewDialog(sub['id'] as int, 'approved'),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showDetailsSheet(sub),
                  icon: const Icon(Icons.visibility_outlined, size: 16),
                  label: const Text('View Details'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _quickStat(String label, String value, Color color, ColorScheme cs) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 13)),
            Text(label,
                style: TextStyle(
                    color: cs.onSurface.withOpacity(0.5), fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Future<void> _reviewDialog(int submissionId, String status) async {
    final cs = Theme.of(context).colorScheme;
    final remarksController = TextEditingController();
    final isApprove = status == 'approved';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              isApprove ? Icons.check_circle_outline : Icons.cancel_outlined,
              color: isApprove ? const Color(0xFF4CAF50) : cs.error,
            ),
            const SizedBox(width: 10),
            Text(isApprove ? 'Approve Submission' : 'Reject Submission'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isApprove
                  ? 'This will forward to HOD for final approval.'
                  : 'Student will be asked to revise and resubmit.',
              style: TextStyle(
                  color: cs.onBackground.withOpacity(0.6), fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: remarksController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Remarks (optional)',
                hintText: isApprove
                    ? 'e.g. Good performance overall'
                    : 'e.g. Please add certificate proofs',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isApprove ? const Color(0xFF4CAF50) : cs.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(isApprove ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiService.ssmMentorReview(
        submissionId: submissionId,
        status: status,
        remarks: remarksController.text.trim().isEmpty
            ? null
            : remarksController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isApprove
                ? '✓ Approved! Forwarded to HOD.'
                : '✓ Rejected. Student notified.'),
            backgroundColor: isApprove ? const Color(0xFF4CAF50) : cs.error,
          ),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: cs.error),
        );
      }
    }
  }

  void _showDetailsSheet(Map<String, dynamic> sub) {
    final cs = Theme.of(context).colorScheme;
    final activities = (sub['activities'] as List? ?? []);
    final reviews = (sub['reviews'] as List? ?? []);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        builder: (ctx, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.all(20),
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: cs.onSurface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Student info
            Text(sub['student_name'] ?? '',
                style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
            Text(
              '${sub['register_number']} • ${sub['department']} ${sub['year']}',
              style: TextStyle(color: cs.onSurface.withOpacity(0.5)),
            ),

            const SizedBox(height: 20),

            // Score
            Row(children: [
              _detailChip(
                  'Score',
                  '${(sub['total_score'] as num?)?.toStringAsFixed(1) ?? 0}',
                  const Color(0xFF2196F3),
                  cs),
              const SizedBox(width: 10),
              _detailChip(
                  'GPA',
                  '${(sub['gpa'] as num?)?.toStringAsFixed(1) ?? '—'}',
                  const Color(0xFF4CAF50),
                  cs),
              const SizedBox(width: 10),
              _detailChip(
                  'Attend.',
                  '${(sub['attendance_input'] as num?)?.toStringAsFixed(0) ?? '—'}%',
                  const Color(0xFFFF9800),
                  cs),
            ]),

            const SizedBox(height: 20),

            // Activities
            if (activities.isNotEmpty) ...[
              Text('Activities (${activities.length})',
                  style: TextStyle(
                      color: cs.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
              const SizedBox(height: 10),
              ...activities.map((a) => _activityRow(a, cs)),
              const SizedBox(height: 16),
            ],

            // Reviews
            if (reviews.isNotEmpty) ...[
              Text('Review History',
                  style: TextStyle(
                      color: cs.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
              const SizedBox(height: 10),
              ...reviews.map((r) => _reviewRow(r, cs)),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _detailChip(String label, String value, Color color, ColorScheme cs) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 16)),
            Text(label,
                style: TextStyle(
                    color: cs.onSurface.withOpacity(0.5), fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _activityRow(dynamic a, ColorScheme cs) {
    final Map<String, Color> typeColors = {
      'internship': const Color(0xFF9C27B0),
      'certificate': const Color(0xFF2196F3),
      'project': const Color(0xFF4CAF50),
      'achievement': const Color(0xFFFF9800),
    };
    final color = typeColors[a['type']] ?? cs.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
              width: 3,
              height: 36,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a['title'] ?? '',
                    style: TextStyle(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                Text(
                    '${(a['type'] as String?)?.toUpperCase() ?? ''}${a['organization'] != null ? ' • ${a['organization']}' : ''}',
                    style: TextStyle(
                        color: cs.onSurface.withOpacity(0.4), fontSize: 11)),
              ],
            ),
          ),
          if (a['has_proof'] == true)
            Icon(Icons.attach_file,
                size: 14, color: cs.onSurface.withOpacity(0.4)),
        ],
      ),
    );
  }

  Widget _reviewRow(dynamic r, ColorScheme cs) {
    final isApproved = r['status'] == 'approved';
    final color = isApproved ? const Color(0xFF4CAF50) : cs.error;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(isApproved ? Icons.check_circle_outline : Icons.cancel_outlined,
              color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${(r['reviewer_role'] as String?)?.toUpperCase() ?? ''}: ${r['reviewer_name'] ?? ''}${r['remarks'] != null ? ' — "${r['remarks']}"' : ''}',
              style:
                  TextStyle(color: cs.onSurface.withOpacity(0.7), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off, size: 56, color: cs.error.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(_error!,
              style: TextStyle(color: cs.onBackground.withOpacity(0.6))),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _load, child: const Text('Retry')),
        ],
      ),
    );
  }
}
