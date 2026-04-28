// File: lib/screens/student/student_performance_tab.dart (FULL REPLACE v3)
// ─────────────────────────────────────────────────────────────────────────────
// Activity-based SSM — student adds entries anytime throughout semester
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../../core/session.dart';
import '../../models/ssm_models.dart';
import '../../services/api_service.dart';
import 'ssm_add_entry_screen.dart';
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

  static const _catColors = [
    Color(0xFF1565C0),
    Color(0xFF2E7D32),
    Color(0xFF6A1B9A),
    Color(0xFFE65100),
    Color(0xFFC62828),
  ];
  static const _catNames = [
    'Academic',
    'Development',
    'Skill & Readiness',
    'Discipline',
    'Leadership',
  ];
  static const _catIcons = [
    Icons.school_outlined,
    Icons.workspace_premium_outlined,
    Icons.rocket_launch_outlined,
    Icons.verified_user_outlined,
    Icons.groups_outlined,
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
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

    if (_isLoading)
      return Center(child: CircularProgressIndicator(color: cs.primary));
    if (_error != null) return _buildError(cs);

    return RefreshIndicator(
      onRefresh: _load,
      color: cs.primary,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Header ──────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Performance Score',
                    style: TextStyle(
                        color: cs.onBackground,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                Text('SSM — AY 2025-26',
                    style: TextStyle(
                        color: cs.onBackground.withOpacity(0.5), fontSize: 12)),
              ]),
              // Add Activity button
              ElevatedButton.icon(
                onPressed: _openAddEntry,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add', style: TextStyle(fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          if (_hasSubmission && _submission != null) ...[
            _buildScoreCard(cs),
            const SizedBox(height: 16),
            _buildStatusCard(cs),
            const SizedBox(height: 20),
            _buildCategoryBars(cs),
            const SizedBox(height: 20),
            _buildEntriesList(cs),
            const SizedBox(height: 20),
            _buildActionButtons(cs),
          ] else
            _buildEmptyState(cs),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  void _openAddEntry() async {
    // If no submission yet, it gets created when first entry is added
    int submissionId;
    if (_submission != null) {
      submissionId = _submission!.id;
    } else {
      // Will be created on backend when entry is added
      // Pass 0 — backend creates submission on first entry
      submissionId = 0;
    }

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
          builder: (_) => SSMAddEntryScreen(
                submissionId: submissionId,
              )),
    );
    if (result == true) _load();
  }

  // ── Score Card ─────────────────────────────────────────────
  Widget _buildScoreCard(ColorScheme cs) {
    final sub = _submission!;
    final score = sub.totalScore.toInt();
    Color scoreColor;
    if (score >= 450)
      scoreColor = const Color(0xFF1B5E20);
    else if (score >= 400)
      scoreColor = const Color(0xFF2E7D32);
    else if (score >= 350)
      scoreColor = const Color(0xFF1565C0);
    else if (score >= 300)
      scoreColor = const Color(0xFFFF9800);
    else if (score >= 250)
      scoreColor = const Color(0xFFE65100);
    else
      scoreColor = cs.error;

    return GestureDetector(
      onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => SSMResultScreen(submission: sub)))
          .then((_) => _load()),
      child: Container(
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [scoreColor, scoreColor.withOpacity(0.75)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: scoreColor.withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 10))
          ],
        ),
        child: Column(children: [
          Text('Your SSM Score',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.85), fontSize: 13)),
          const SizedBox(height: 6),
          Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('$score',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 68,
                        fontWeight: FontWeight.bold,
                        height: 1.0)),
                Padding(
                    padding: const EdgeInsets.only(bottom: 10, left: 4),
                    child: Text('/500',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 20))),
              ]),
          const SizedBox(height: 10),
          Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                  5,
                  (i) => Icon(
                      i < sub.starRating ? Icons.star : Icons.star_border,
                      color: Colors.white,
                      size: 28))),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(sub.categoryLabel,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: score / 500,
            backgroundColor: Colors.white.withOpacity(0.25),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 5,
            borderRadius: BorderRadius.circular(3),
          ),
          const SizedBox(height: 6),
          Text('Tap for full breakdown →',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.6), fontSize: 11)),
        ]),
      ),
    );
  }

  // ── Status Card ─────────────────────────────────────────────
  Widget _buildStatusCard(ColorScheme cs) {
    final sub = _submission!;
    Color color;
    IconData icon;
    switch (sub.status) {
      case 'active':
        color = const Color(0xFF2196F3);
        icon = Icons.edit_note_outlined;
        break;
      case 'submitted':
        color = const Color(0xFFFF9800);
        icon = Icons.hourglass_empty_outlined;
        break;
      case 'mentor_approved':
        color = const Color(0xFF2196F3);
        icon = Icons.verified_outlined;
        break;
      case 'hod_approved':
        color = const Color(0xFF2E7D32);
        icon = Icons.lock_outline;
        break;
      default:
        color = cs.onBackground.withOpacity(0.4);
        icon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(sub.statusLabel,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 13)),
            if (sub.status == 'active')
              Text('You can add more activities anytime',
                  style: TextStyle(
                      color: cs.onBackground.withOpacity(0.45), fontSize: 11)),
            if (sub.reviews.isNotEmpty)
              Text(
                  '${sub.reviews.last.reviewerRole.toUpperCase()}: ${sub.reviews.last.remarks ?? ""}',
                  style: TextStyle(
                      color: cs.onBackground.withOpacity(0.45), fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
          ],
        )),
        if (sub.isFinal)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('FINAL',
                style: TextStyle(
                    color: color, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
      ]),
    );
  }

  // ── 5 Category Bars ──────────────────────────────────────────
  Widget _buildCategoryBars(ColorScheme cs) {
    final sub = _submission!;
    final cats = [sub.cat1, sub.cat2, sub.cat3, sub.cat4, sub.cat5];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Category Scores',
            style: TextStyle(
                color: cs.onBackground,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Row(
            children: List.generate(5, (i) {
          final pts = cats[i];
          final color = _catColors[i];
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i < 4 ? 6 : 0),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Column(children: [
                Icon(_catIcons[i], color: color, size: 18),
                const SizedBox(height: 4),
                Text('$pts',
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                Text('/100',
                    style: TextStyle(
                        color: cs.onSurface.withOpacity(0.3), fontSize: 9)),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: pts / 100,
                  backgroundColor: color.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 3,
                  borderRadius: BorderRadius.circular(2),
                ),
              ]),
            ),
          );
        })),
      ],
    );
  }

  // ── Entries List ─────────────────────────────────────────────
  Widget _buildEntriesList(ColorScheme cs) {
    final entries = _submission!.entries;
    if (entries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.onSurface.withOpacity(0.07)),
        ),
        child: Column(children: [
          Icon(Icons.add_circle_outline,
              size: 44, color: cs.onSurface.withOpacity(0.2)),
          const SizedBox(height: 12),
          Text('No activities added yet',
              style: TextStyle(
                  color: cs.onSurface.withOpacity(0.5),
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Tap "Add" to add your first activity',
              style: TextStyle(
                  color: cs.onSurface.withOpacity(0.35), fontSize: 12)),
        ]),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('My Activities (${entries.length})',
              style: TextStyle(
                  color: cs.onBackground,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 10),
        ...entries.map((entry) => _buildEntryCard(entry, cs)),
      ],
    );
  }

  Widget _buildEntryCard(SSMEntry entry, ColorScheme cs) {
    final catIdx = entry.category - 1;
    final color = catIdx >= 0 && catIdx < _catColors.length
        ? _catColors[catIdx]
        : cs.primary;

    Color proofColor;
    IconData proofIcon;
    switch (entry.proofStatus) {
      case 'valid':
        proofColor = const Color(0xFF2E7D32);
        proofIcon = Icons.check_circle;
        break;
      case 'review':
        proofColor = const Color(0xFFFF9800);
        proofIcon = Icons.rate_review;
        break;
      case 'invalid':
        proofColor = cs.error;
        proofIcon = Icons.cancel;
        break;
      case 'not_required':
        proofColor = cs.onSurface.withOpacity(0.3);
        proofIcon = Icons.check;
        break;
      default:
        proofColor = cs.error;
        proofIcon = Icons.upload_file_outlined;
        break;
    }

    return Dismissible(
      key: Key('entry_${entry.id}'),
      direction: _submission!.isFinal
          ? DismissDirection.none
          : DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: cs.error.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(Icons.delete_outline, color: cs.error),
      ),
      confirmDismiss: (_) => _confirmDelete(entry.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.18)),
        ),
        child: Row(children: [
          // Category color bar
          Container(
              width: 4,
              height: 44,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(4))),
          const SizedBox(width: 12),
          // Info
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry.entryLabel,
                  style: TextStyle(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
              const SizedBox(height: 2),
              Text(
                _formatDetails(entry),
                style: TextStyle(
                    color: cs.onSurface.withOpacity(0.45), fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          )),
          const SizedBox(width: 8),
          // Proof status
          if (entry.proofRequired && entry.proofStatus != 'not_required')
            Icon(proofIcon, color: proofColor, size: 18),
          const SizedBox(width: 8),
          // Score
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('+${entry.score.toInt()}',
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          if (!_submission!.isFinal) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => _editEntry(entry),
              child: Icon(Icons.edit_outlined,
                  size: 16, color: cs.onSurface.withOpacity(0.35)),
            ),
          ],
        ]),
      ),
    );
  }

  String _formatDetails(SSMEntry entry) {
    final d = entry.details;
    if (d.isEmpty) return '';
    final parts = <String>[];
    if (d['gpa'] != null) parts.add('GPA: ${d['gpa']}');
    if (d['percentage'] != null) parts.add('${d['percentage']}%');
    if (d['level'] != null) parts.add(d['level'] as String);
    if (d['duration'] != null) parts.add(d['duration'] as String);
    if (d['result'] != null) parts.add(d['result'] as String);
    if (d['type'] != null) parts.add(d['type'] as String);
    if (d['status'] != null) parts.add(d['status'] as String);
    if (d['title'] != null) parts.add(d['title'] as String);
    if (d['course'] != null) parts.add(d['course'] as String);
    if (d['company'] != null) parts.add(d['company'] as String);
    if (d['platform'] != null) parts.add(d['platform'] as String);
    if (d['event'] != null) parts.add(d['event'] as String);
    return parts.take(2).join(' · ');
  }

  Future<bool> _confirmDelete(int entryId) async {
    final cs = Theme.of(context).colorScheme;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Remove Activity'),
        content: const Text('Remove this activity and recalculate score?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Remove', style: TextStyle(color: cs.error)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await ApiService.ssmDeleteEntry(entryId);
        _load();
        return true;
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(e.toString()), backgroundColor: Colors.red));
      }
    }
    return false;
  }

  void _editEntry(SSMEntry entry) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
          builder: (_) => SSMAddEntryScreen(
                submissionId: _submission!.id,
                existingEntry: {
                  'id': entry.id,
                  'entry_type': entry.entryType,
                  'details': entry.details,
                  'proof_status': entry.proofStatus,
                },
              )),
    );
    if (result == true) _load();
  }

  // ── Action Buttons ──────────────────────────────────────────
  Widget _buildActionButtons(ColorScheme cs) {
    final sub = _submission!;
    if (sub.isFinal) return const SizedBox.shrink();

    final canSubmit = sub.status == 'active' && sub.entries.isNotEmpty;

    return Column(children: [
      if (canSubmit)
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _submitForApproval,
            icon: const Icon(Icons.send_outlined),
            label: const Text('Submit for Mentor Approval'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      if (sub.status == 'submitted') ...[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFF9800).withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFF9800).withOpacity(0.3)),
          ),
          child: Row(children: [
            const Icon(Icons.hourglass_empty,
                color: Color(0xFFFF9800), size: 20),
            const SizedBox(width: 10),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pending Mentor Review',
                    style: TextStyle(
                        color: Color(0xFFFF9800),
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                Text('You can still add more activities while waiting',
                    style: TextStyle(
                        color: const Color(0xFFFF9800).withOpacity(0.7),
                        fontSize: 11)),
              ],
            )),
          ]),
        ),
      ],
    ]);
  }

  Future<void> _submitForApproval() async {
    try {
      await ApiService.ssmSubmitForApproval(_submission!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✓ Submitted for mentor review!'),
          backgroundColor: Color(0xFF2E7D32),
        ));
        _load();
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }

  // ── Empty State ──────────────────────────────────────────────
  Widget _buildEmptyState(ColorScheme cs) {
    return Column(children: [
      Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: cs.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: cs.primary.withOpacity(0.12)),
        ),
        child: Column(children: [
          Icon(Icons.stars_outlined,
              size: 60, color: cs.primary.withOpacity(0.35)),
          const SizedBox(height: 16),
          Text('Start Building Your Score',
              style: TextStyle(
                  color: cs.onBackground,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Add activities one by one throughout the semester. '
            'Each activity you add increases your score instantly.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: cs.onBackground.withOpacity(0.5), fontSize: 13),
          ),
        ]),
      ),
      const SizedBox(height: 20),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _openAddEntry,
          icon: const Icon(Icons.add_circle_outline, size: 22),
          label: const Text('Add First Activity',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: cs.primary,
            foregroundColor: cs.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
      const SizedBox(height: 24),
      _buildStarInfo(cs),
    ]);
  }

  Widget _buildStarInfo(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.onSurface.withOpacity(0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Star Rating Scale (out of 500)',
              style: TextStyle(
                  color: cs.onBackground,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
          const SizedBox(height: 10),
          ...[
            [5, '450–500', const Color(0xFF1B5E20)],
            [4, '400–449', const Color(0xFF2E7D32)],
            [3, '350–399', const Color(0xFF1565C0)],
            [2, '300–349', const Color(0xFFFF9800)],
            [1, '250–299', const Color(0xFFE65100)],
          ].map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(children: [
                  Row(
                      children: List.generate(
                          5,
                          (i) => Icon(
                              i < (r[0] as int)
                                  ? Icons.star
                                  : Icons.star_border,
                              color: r[2] as Color,
                              size: 14))),
                  const SizedBox(width: 10),
                  Text(r[1] as String,
                      style: TextStyle(
                          color: cs.onBackground.withOpacity(0.6),
                          fontSize: 12)),
                ]),
              )),
        ],
      ),
    );
  }

  Widget _buildError(ColorScheme cs) {
    return Center(
        child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.cloud_off, size: 56, color: cs.error.withOpacity(0.5)),
        const SizedBox(height: 16),
        Text(_error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: cs.onBackground.withOpacity(0.6))),
        const SizedBox(height: 24),
        ElevatedButton(onPressed: _load, child: const Text('Retry')),
      ]),
    ));
  }
}
