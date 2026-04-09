// File: lib/screens/admin/hod_ssm_approval_screen.dart
// ─────────────────────────────────────────────────────────
// HOD Final Approval Screen
// HOD sees mentor-approved submissions and locks final score
// ─────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class HODSSMApprovalScreen extends StatefulWidget {
  const HODSSMApprovalScreen({super.key});

  @override
  State<HODSSMApprovalScreen> createState() => _HODSSMApprovalScreenState();
}

class _HODSSMApprovalScreenState extends State<HODSSMApprovalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _error;

  List<Map<String, dynamic>> _pendingHOD = []; // mentor_approved
  List<Map<String, dynamic>> _finalApproved = []; // hod_approved
  List<Map<String, dynamic>> _finalRejected = []; // hod_rejected

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
          _pendingHOD = all
              .where((s) => s['status'] == 'mentor_approved')
              .map((s) => Map<String, dynamic>.from(s))
              .toList();
          _finalApproved = all
              .where((s) => s['status'] == 'hod_approved')
              .map((s) => Map<String, dynamic>.from(s))
              .toList();
          _finalRejected = all
              .where((s) => s['status'] == 'hod_rejected')
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
        title: const Text('SSM Final Approval'),
        centerTitle: false,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Pending'),
                  if (_pendingHOD.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2196F3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('${_pendingHOD.length}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Locked ✓'),
            const Tab(text: 'Rejected'),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: cs.primary))
          : _error != null
              ? _buildError(cs)
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildList(_pendingHOD, isPending: true),
                    _buildList(_finalApproved, isFinal: true),
                    _buildList(_finalRejected),
                  ],
                ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> items,
      {bool isPending = false, bool isFinal = false}) {
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
        itemBuilder: (_, i) =>
            _buildCard(items[i], isPending: isPending, isFinal: isFinal),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> sub,
      {bool isPending = false, bool isFinal = false}) {
    final cs = Theme.of(context).colorScheme;
    final score = (sub['total_score'] as num?)?.toDouble() ?? 0.0;
    final stars = sub['star_rating'] as int? ?? 0;

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
              ? const Color(0xFF2196F3).withOpacity(0.35)
              : isFinal
                  ? const Color(0xFF4CAF50).withOpacity(0.3)
                  : cs.onSurface.withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
              color: cs.shadow.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    // Avatar
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: scoreColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          (sub['student_name'] as String? ?? 'S')[0]
                              .toUpperCase(),
                          style: TextStyle(
                              color: scoreColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(sub['student_name'] ?? 'Unknown',
                              style: TextStyle(
                                  color: cs.onSurface,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                          Text(
                            '${sub['register_number'] ?? ''} • ${sub['department'] ?? ''} ${sub['year'] ?? ''}',
                            style: TextStyle(
                                color: cs.onSurface.withOpacity(0.5),
                                fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    // Final score badge
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: scoreColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            score.toStringAsFixed(1),
                            style: TextStyle(
                                color: scoreColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 18),
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

                const SizedBox(height: 12),

                // Stats row
                Row(children: [
                  _statBox(
                      'GPA',
                      sub['gpa'] != null
                          ? (sub['gpa'] as num).toStringAsFixed(1)
                          : '—',
                      const Color(0xFF4CAF50),
                      cs),
                  const SizedBox(width: 8),
                  _statBox(
                      'Attend.',
                      sub['attendance_input'] != null
                          ? '${(sub['attendance_input'] as num).toStringAsFixed(0)}%'
                          : '—',
                      const Color(0xFF2196F3),
                      cs),
                  const SizedBox(width: 8),
                  _statBox(
                      'Activities',
                      '${(sub['activities'] as List?)?.length ?? 0}',
                      const Color(0xFF9C27B0),
                      cs),
                  const SizedBox(width: 8),
                  if (isFinal)
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text('FINAL ✓',
                              style: TextStyle(
                                  color: Color(0xFF4CAF50),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11)),
                        ),
                      ),
                    ),
                ]),

                // Mentor approval indicator
                if (!isFinal) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2196F3).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_outlined,
                            color: Color(0xFF2196F3), size: 16),
                        const SizedBox(width: 6),
                        Text('Mentor approved — awaiting HOD final decision',
                            style: TextStyle(
                                color: const Color(0xFF2196F3).withOpacity(0.8),
                                fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Action buttons
          if (isPending)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showDetails(sub),
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
                          _finalReviewDialog(sub['id'] as int, 'rejected'),
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
                          _finalReviewDialog(sub['id'] as int, 'approved'),
                      icon: const Icon(Icons.lock_outline, size: 16),
                      label: const Text('Lock Score'),
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
                  onPressed: () => _showDetails(sub),
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

  Widget _statBox(String label, String value, Color color, ColorScheme cs) {
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

  Future<void> _finalReviewDialog(int submissionId, String status) async {
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
              isApprove ? Icons.lock : Icons.block,
              color: isApprove ? const Color(0xFF4CAF50) : cs.error,
            ),
            const SizedBox(width: 10),
            Text(isApprove ? 'Lock Final Score' : 'Reject Submission'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isApprove
                  ? 'This will LOCK the student\'s final performance score. This cannot be undone.'
                  : 'The submission will be sent back to the student for revision.',
              style: TextStyle(
                  color: cs.onBackground.withOpacity(0.6), fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: remarksController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'HOD Remarks (optional)',
                hintText: isApprove
                    ? 'e.g. Excellent student — approved'
                    : 'e.g. Certificate proofs are missing',
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
            child: Text(isApprove ? 'Lock Score' : 'Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiService.ssmHODReview(
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
                ? '🔒 Score locked successfully!'
                : '✓ Submission rejected.'),
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

  void _showDetails(Map<String, dynamic> sub) {
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
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        builder: (ctx, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.all(20),
          children: [
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
            Text(sub['student_name'] ?? '',
                style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
            Text(
                '${sub['register_number']} • ${sub['department']} ${sub['year']}',
                style: TextStyle(color: cs.onSurface.withOpacity(0.5))),
            const SizedBox(height: 20),

            // Score breakdown
            if ((sub['score_breakdown'] as Map?)?.isNotEmpty == true) ...[
              Text('Score Breakdown',
                  style: TextStyle(
                      color: cs.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
              const SizedBox(height: 10),
              _buildBreakdownRows(sub['score_breakdown'] as Map, cs),
              const SizedBox(height: 16),
            ],

            // Activities
            if (activities.isNotEmpty) ...[
              Text('Activities (${activities.length})',
                  style: TextStyle(
                      color: cs.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
              const SizedBox(height: 10),
              ...activities.map((a) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: cs.onSurface.withOpacity(0.08)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.circle, size: 8),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text('${a['title']} (${a['type']})',
                              style:
                                  TextStyle(color: cs.onSurface, fontSize: 13)),
                        ),
                        if (a['has_proof'] == true)
                          const Icon(Icons.attach_file, size: 14),
                      ],
                    ),
                  )),
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
              ...reviews.map((r) {
                final approved = r['status'] == 'approved';
                final color = approved ? const Color(0xFF4CAF50) : cs.error;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withOpacity(0.25)),
                  ),
                  child: Text(
                    '${(r['reviewer_role'] as String).toUpperCase()} — ${r['reviewer_name'] ?? ''}: ${r['remarks'] ?? 'No remarks'}',
                    style: TextStyle(
                        color: cs.onSurface.withOpacity(0.7), fontSize: 12),
                  ),
                );
              }),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownRows(Map bd, ColorScheme cs) {
    final items = <Map<String, dynamic>>[];

    void addRow(String key, String label, Color color) {
      if (bd[key] != null) {
        final pts = (bd[key]['pts'] ?? bd[key]['points'] ?? 0) as num;
        final max = (bd[key]['max'] ?? 0) as num;
        items.add({'label': label, 'pts': pts, 'max': max, 'color': color});
      }
    }

    addRow('gpa', 'GPA', const Color(0xFF4CAF50));
    addRow('attendance', 'Attendance', const Color(0xFF2196F3));
    addRow('internship', 'Internship', const Color(0xFF9C27B0));
    addRow('project', 'Projects', const Color(0xFF4CAF50));
    addRow('certificate', 'Certificates', const Color(0xFFFF9800));
    addRow('achievement', 'Achievements', const Color(0xFFFF5722));

    return Column(
      children: items.map((item) {
        final color = item['color'] as Color;
        final pts = (item['pts'] as num).toInt();
        final max = (item['max'] as num).toInt();
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(item['label'] as String,
                    style: TextStyle(color: cs.onSurface, fontSize: 13)),
              ),
              Text('$pts / $max pts',
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        );
      }).toList(),
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
