// File: lib/screens/student/student_performance_tab.dart
// ─────────────────────────────────────────────────────────
// Performance Tab — shown in Student Dashboard bottom nav
// Shows score overview, activities, status, and entry to SSM form
// ─────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../../core/session.dart';
import '../../models/ssm_models.dart';
import '../../services/api_service.dart';
import 'ssm_form_screen.dart';
import 'ssm_add_activity_screen.dart';
import 'ssm_result_screen.dart';

class StudentPerformanceTab extends StatefulWidget {
  const StudentPerformanceTab({super.key});

  @override
  State<StudentPerformanceTab> createState() => _StudentPerformanceTabState();
}

class _StudentPerformanceTabState extends State<StudentPerformanceTab> {
  bool _isLoading = true;
  String? _error;
  SSMSubmission? _submission;
  bool _hasSubmission = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await ApiService.ssmGetResult(SessionManager.studentId!);
      if (mounted) {
        setState(() {
          _hasSubmission = data['has_submission'] == true;
          _submission = _hasSubmission
              ? SSMSubmission.fromJson(data['submission'])
              : null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: cs.primary));
    }
    if (_error != null) {
      return _buildError(cs);
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: cs.primary,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Header ────────────────────────────────────────
          Text(
            'Performance Score',
            style: TextStyle(
              color: cs.onBackground,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'SSM — Student Score Management',
            style: TextStyle(color: cs.onBackground.withOpacity(0.5), fontSize: 13),
          ),

          const SizedBox(height: 20),

          // ── Score Card ────────────────────────────────────
          if (_hasSubmission && _submission != null)
            _buildScoreCard(cs)
          else
            _buildNoSubmissionCard(cs),

          const SizedBox(height: 20),

          // ── Status + Actions ──────────────────────────────
          if (_hasSubmission && _submission != null) ...[
            _buildStatusCard(cs),
            const SizedBox(height: 20),
            _buildActivitiesList(cs),
            const SizedBox(height: 20),
            _buildActionButtons(cs),
          ] else ...[
            _buildStartCard(cs),
          ],

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ── Score Card ─────────────────────────────────────────
  Widget _buildScoreCard(ColorScheme cs) {
    final sub = _submission!;
    final score = sub.totalScore;
    final stars = sub.starRating;

    // Color based on score
    Color scoreColor;
    if (score >= 85) scoreColor = const Color(0xFF4CAF50);
    else if (score >= 70) scoreColor = const Color(0xFF2196F3);
    else if (score >= 55) scoreColor = const Color(0xFFFF9800);
    else if (score >= 40) scoreColor = const Color(0xFFFF5722);
    else scoreColor = cs.error;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SSMResultScreen(submission: sub)),
      ).then((_) => _load()),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [scoreColor, scoreColor.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: scoreColor.withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              'Your Score',
              style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              '${score.toStringAsFixed(1)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 64,
                fontWeight: FontWeight.bold,
                height: 1.0,
              ),
            ),
            Text(
              '/ 100',
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16),
            ),
            const SizedBox(height: 12),
            // Stars
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) => Icon(
                i < stars ? Icons.star : Icons.star_border,
                color: Colors.white,
                size: 26,
              )),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                sub.categoryLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: score / 100,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 6,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap to view full breakdown →',
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // ── Status Card ────────────────────────────────────────
  Widget _buildStatusCard(ColorScheme cs) {
    final sub = _submission!;
    Color statusColor;
    IconData statusIcon;

    switch (sub.status) {
      case 'draft':
        statusColor = cs.onBackground.withOpacity(0.5);
        statusIcon = Icons.edit_note_outlined;
        break;
      case 'submitted':
        statusColor = const Color(0xFFFF9800);
        statusIcon = Icons.hourglass_empty;
        break;
      case 'mentor_approved':
        statusColor = const Color(0xFF2196F3);
        statusIcon = Icons.verified_outlined;
        break;
      case 'mentor_rejected':
        statusColor = cs.error;
        statusIcon = Icons.cancel_outlined;
        break;
      case 'hod_approved':
        statusColor = const Color(0xFF4CAF50);
        statusIcon = Icons.verified;
        break;
      case 'hod_rejected':
        statusColor = cs.error;
        statusIcon = Icons.block;
        break;
      default:
        statusColor = cs.onBackground.withOpacity(0.4);
        statusIcon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status',
                  style: TextStyle(
                    color: cs.onBackground.withOpacity(0.5),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sub.statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (sub.reviews.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Last review: ${sub.reviews.last.reviewerName ?? 'Reviewer'} — ${sub.reviews.last.remarks ?? 'No remarks'}',
                    style: TextStyle(
                      color: cs.onBackground.withOpacity(0.5),
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Activities List ────────────────────────────────────
  Widget _buildActivitiesList(ColorScheme cs) {
    final activities = _submission!.activities;

    final Map<String, IconData> typeIcons = {
      'internship': Icons.work_outline,
      'certificate': Icons.card_membership_outlined,
      'project': Icons.code_outlined,
      'achievement': Icons.emoji_events_outlined,
    };
    final Map<String, Color> typeColors = {
      'internship': const Color(0xFF9C27B0),
      'certificate': const Color(0xFF2196F3),
      'project': const Color(0xFF4CAF50),
      'achievement': const Color(0xFFFF9800),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Activities (${activities.length})',
              style: TextStyle(
                color: cs.onBackground,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_submission!.canEdit)
              TextButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SSMAddActivityScreen(
                      submissionId: _submission!.id,
                    ),
                  ),
                ).then((_) => _load()),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
              ),
          ],
        ),
        const SizedBox(height: 8),

        if (activities.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.onSurface.withOpacity(0.08)),
            ),
            child: Column(
              children: [
                Icon(Icons.inbox_outlined, size: 44,
                    color: cs.onSurface.withOpacity(0.25)),
                const SizedBox(height: 12),
                Text(
                  'No activities added yet.\nAdd internships, certificates, or projects!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: cs.onSurface.withOpacity(0.4)),
                ),
              ],
            ),
          )
        else
          ...activities.map((activity) {
            final color = typeColors[activity.type] ?? cs.primary;
            final icon = typeIcons[activity.type] ?? Icons.star_outline;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                activity.title,
                                style: TextStyle(
                                  color: cs.onSurface,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            if (activity.hasProof)
                              Icon(Icons.attach_file, size: 14,
                                  color: cs.onSurface.withOpacity(0.4)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${activity.typeLabel}${activity.organization != null ? ' • ${activity.organization}' : ''}',
                          style: TextStyle(
                            color: cs.onSurface.withOpacity(0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '+${activity.score.toInt()}',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (_submission!.canEdit) ...[
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => _deleteActivity(activity),
                      child: Icon(Icons.close, size: 18,
                          color: cs.onSurface.withOpacity(0.3)),
                    ),
                  ],
                ],
              ),
            );
          }),
      ],
    );
  }

  Future<void> _deleteActivity(SSMActivity activity) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Activity'),
        content: Text('Remove "${activity.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await ApiService.ssmDeleteActivity(activity.id);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ── Action Buttons ─────────────────────────────────────
  Widget _buildActionButtons(ColorScheme cs) {
    final sub = _submission!;

    return Column(
      children: [
        // Edit GPA/Attendance
        if (sub.canEdit)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SSMFormScreen(submission: sub),
                ),
              ).then((_) => _load()),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit GPA & Attendance'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),

        const SizedBox(height: 10),

        // Submit button
        if (sub.canSubmit && sub.status != 'submitted')
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _submitForApproval,
              icon: const Icon(Icons.send_outlined),
              label: const Text('Submit for Approval'),
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _submitForApproval() async {
    final sub = _submission!;
    if (sub.gpa == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your GPA before submitting.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await ApiService.ssmSubmitForApproval(sub.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Submitted for mentor review!'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ── No Submission Card ─────────────────────────────────
  Widget _buildNoSubmissionCard(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: cs.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.primary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(Icons.stars_outlined, size: 56, color: cs.primary.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'No Performance Data Yet',
            style: TextStyle(
              color: cs.onBackground,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Fill your SSM form to calculate your\nperformance score and star rating.',
            textAlign: TextAlign.center,
            style: TextStyle(color: cs.onBackground.withOpacity(0.5), fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ── Start New Card ─────────────────────────────────────
  Widget _buildStartCard(ColorScheme cs) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SSMFormScreen()),
        ).then((_) => _load()),
        icon: const Icon(Icons.add_chart_outlined, size: 22),
        label: const Text('Start My SSM Form', style: TextStyle(fontSize: 16)),
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  // ── Error State ────────────────────────────────────────
  Widget _buildError(ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 56, color: cs.error.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center,
                style: TextStyle(color: cs.onBackground.withOpacity(0.6))),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
