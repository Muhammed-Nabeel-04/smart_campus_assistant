// File: lib/screens/student/ssm_result_screen.dart
// ─────────────────────────────────────────────────────────
// SSM Result Screen — full breakdown of score
// ─────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../../models/ssm_models.dart';

class SSMResultScreen extends StatelessWidget {
  final SSMSubmission submission;

  const SSMResultScreen({super.key, required this.submission});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final score = submission.totalScore;

    Color scoreColor;
    if (score >= 85) scoreColor = const Color(0xFF4CAF50);
    else if (score >= 70) scoreColor = const Color(0xFF2196F3);
    else if (score >= 55) scoreColor = const Color(0xFFFF9800);
    else scoreColor = cs.error;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Score Breakdown'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Main Score Card ────────────────────────────────
          Container(
            padding: const EdgeInsets.all(32),
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
                  'Your Performance Score',
                  style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  score.toStringAsFixed(1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 72,
                    fontWeight: FontWeight.bold,
                    height: 1.0,
                  ),
                ),
                Text(
                  'out of 100',
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) => Icon(
                    i < submission.starRating ? Icons.star : Icons.star_border,
                    color: Colors.white,
                    size: 30,
                  )),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    submission.categoryLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Status ─────────────────────────────────────────
          _buildStatusRow(cs),

          const SizedBox(height: 24),

          // ── Score Breakdown ────────────────────────────────
          Text(
            'Score Breakdown',
            style: TextStyle(
              color: cs.onBackground,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildBreakdown(cs, scoreColor),

          const SizedBox(height: 24),

          // ── Reviews ────────────────────────────────────────
          if (submission.reviews.isNotEmpty) ...[
            Text(
              'Review History',
              style: TextStyle(
                color: cs.onBackground,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...submission.reviews.map((r) => _buildReviewCard(r, cs)),
          ],

          // ── Activities List ────────────────────────────────
          if (submission.activities.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Activities (${submission.activities.length})',
              style: TextStyle(
                color: cs.onBackground,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...submission.activities.map((a) => _buildActivityTile(a, cs)),
          ],

          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildStatusRow(ColorScheme cs) {
    Color color;
    IconData icon;
    switch (submission.status) {
      case 'hod_approved':
        color = const Color(0xFF4CAF50); icon = Icons.verified;
        break;
      case 'mentor_approved':
        color = const Color(0xFF2196F3); icon = Icons.verified_outlined;
        break;
      case 'submitted':
        color = const Color(0xFFFF9800); icon = Icons.hourglass_top;
        break;
      case 'mentor_rejected':
      case 'hod_rejected':
        color = cs.error; icon = Icons.cancel_outlined;
        break;
      default:
        color = cs.onBackground.withOpacity(0.4); icon = Icons.edit_note;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Text(
            submission.statusLabel,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15),
          ),
          if (submission.isFinal) ...[
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('FINAL', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBreakdown(ColorScheme cs, Color mainColor) {
    final bd = submission.scoreBreakdown;
    if (bd.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.onSurface.withOpacity(0.08)),
        ),
        child: const Text('Score breakdown not available.'),
      );
    }

    final rows = <_BreakdownItem>[
      if (bd['gpa'] != null) _BreakdownItem(
        label: 'GPA (${(bd['gpa']['value'] as num).toStringAsFixed(1)})',
        pts: (bd['gpa']['pts'] ?? bd['gpa']['points'] ?? 0) as num,
        max: 15,
        icon: Icons.school_outlined,
        color: const Color(0xFF4CAF50),
      ),
      if (bd['attendance'] != null) _BreakdownItem(
        label: 'Attendance (${(bd['attendance']['value'] as num).toStringAsFixed(1)}%)',
        pts: (bd['attendance']['pts'] ?? bd['attendance']['points'] ?? 0) as num,
        max: 15,
        icon: Icons.how_to_reg_outlined,
        color: const Color(0xFF2196F3),
      ),
      if (bd['internship'] != null) _BreakdownItem(
        label: 'Internship (${bd['internship']['count']})',
        pts: (bd['internship']['pts'] ?? bd['internship']['points'] ?? 0) as num,
        max: 20,
        icon: Icons.work_outline,
        color: const Color(0xFF9C27B0),
      ),
      if (bd['project'] != null) _BreakdownItem(
        label: 'Projects (${bd['project']['count']})',
        pts: (bd['project']['pts'] ?? bd['project']['points'] ?? 0) as num,
        max: 30,
        icon: Icons.code_outlined,
        color: const Color(0xFF4CAF50),
      ),
      if (bd['certificate'] != null) _BreakdownItem(
        label: 'Certificates (${bd['certificate']['count']})',
        pts: (bd['certificate']['pts'] ?? bd['certificate']['points'] ?? 0) as num,
        max: 15,
        icon: Icons.card_membership_outlined,
        color: const Color(0xFFFF9800),
      ),
      if (bd['achievement'] != null) _BreakdownItem(
        label: 'Achievements (${bd['achievement']['count']})',
        pts: (bd['achievement']['pts'] ?? bd['achievement']['points'] ?? 0) as num,
        max: 15,
        icon: Icons.emoji_events_outlined,
        color: const Color(0xFFFF5722),
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.onSurface.withOpacity(0.08)),
      ),
      child: Column(
        children: rows.map((item) => _buildBreakdownRow(item, cs)).toList(),
      ),
    );
  }

  Widget _buildBreakdownRow(_BreakdownItem item, ColorScheme cs) {
    final progress = item.max > 0 ? (item.pts.toDouble() / item.max) : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(item.icon, size: 16, color: item.color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(color: cs.onSurface, fontSize: 13),
                ),
              ),
              Text(
                '${item.pts.toInt()} / ${item.max}',
                style: TextStyle(
                  color: item.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: item.color.withOpacity(0.12),
            valueColor: AlwaysStoppedAnimation<Color>(item.color),
            minHeight: 5,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(SSMReview review, ColorScheme cs) {
    final isApproved = review.status == 'approved';
    final color = isApproved ? const Color(0xFF4CAF50) : cs.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isApproved ? Icons.check_circle_outline : Icons.cancel_outlined,
            color: color,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${review.reviewerRole.toUpperCase()} — ${review.reviewerName ?? 'Reviewer'}',
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                if (review.remarks != null && review.remarks!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    review.remarks!,
                    style: TextStyle(
                      color: cs.onSurface.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isApproved ? 'Approved' : 'Rejected',
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTile(SSMActivity activity, ColorScheme cs) {
    final Map<String, Color> typeColors = {
      'internship': const Color(0xFF9C27B0),
      'certificate': const Color(0xFF2196F3),
      'project': const Color(0xFF4CAF50),
      'achievement': const Color(0xFFFF9800),
    };
    final color = typeColors[activity.type] ?? cs.primary;

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
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w600),
                ),
                Text(
                  '${activity.typeLabel}${activity.organization != null ? ' • ${activity.organization}' : ''}',
                  style: TextStyle(color: cs.onSurface.withOpacity(0.5), fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '+${activity.score.toInt()} pts',
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _BreakdownItem {
  final String label;
  final num pts;
  final int max;
  final IconData icon;
  final Color color;

  const _BreakdownItem({
    required this.label,
    required this.pts,
    required this.max,
    required this.icon,
    required this.color,
  });
}
