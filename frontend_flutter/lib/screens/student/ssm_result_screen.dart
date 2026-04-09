// File: lib/screens/student/ssm_result_screen.dart
// ─────────────────────────────────────────────────────────
// SSM Full Result Screen — score out of 500, 5 category bars,
// detailed per-criteria breakdown, review history
// ─────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../../models/ssm_models.dart';

class SSMResultScreen extends StatelessWidget {
  final SSMSubmission submission;
  const SSMResultScreen({super.key, required this.submission});

  static const _catColors = [
    Color(0xFF1565C0),
    Color(0xFF2E7D32),
    Color(0xFF6A1B9A),
    Color(0xFFE65100),
    Color(0xFFC62828),
  ];
  static const _catNames = [
    'Academic Performance',
    'Student Development',
    'Skill & Readiness',
    'Discipline & Contribution',
    'Leadership & Initiatives',
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final score = submission.totalScore.toInt();

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Score Breakdown'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Main Score Card ──────────────────────────────
          Container(
            padding: const EdgeInsets.all(32),
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
              Text('SSM Total Score',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.85), fontSize: 14)),
              const SizedBox(height: 8),
              Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$score',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 72,
                            fontWeight: FontWeight.bold,
                            height: 1.0)),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12, left: 4),
                      child: Text('/500',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 22)),
                    ),
                  ]),
              const SizedBox(height: 12),
              Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                      5,
                      (i) => Icon(
                          i < submission.starRating
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.white,
                          size: 32))),
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(submission.categoryLabel,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: score / 500,
                backgroundColor: Colors.white.withOpacity(0.25),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 7,
                borderRadius: BorderRadius.circular(4),
              ),
            ]),
          ),

          const SizedBox(height: 20),

          // ── Status ───────────────────────────────────────
          _buildStatusCard(cs),

          const SizedBox(height: 24),

          // ── Category Summary bars ─────────────────────────
          Text('Category Scores',
              style: TextStyle(
                  color: cs.onBackground,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildCategorySummary(cs),

          const SizedBox(height: 24),

          // ── Detailed Breakdown ────────────────────────────
          Text('Detailed Breakdown',
              style: TextStyle(
                  color: cs.onBackground,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildDetailedBreakdown(cs),

          // ── Review History ────────────────────────────────
          if (submission.reviews.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Review History',
                style: TextStyle(
                    color: cs.onBackground,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...submission.reviews.map((r) => _buildReviewCard(r, cs)),
          ],

          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildStatusCard(ColorScheme cs) {
    Color color;
    IconData icon;
    switch (submission.status) {
      case 'hod_approved':
        color = const Color(0xFF2E7D32);
        icon = Icons.lock_outline;
        break;
      case 'mentor_approved':
        color = const Color(0xFF2196F3);
        icon = Icons.verified_outlined;
        break;
      case 'submitted':
        color = const Color(0xFFFF9800);
        icon = Icons.hourglass_empty;
        break;
      case 'mentor_rejected':
      case 'hod_rejected':
        color = cs.error;
        icon = Icons.cancel_outlined;
        break;
      default:
        color = cs.onBackground.withOpacity(0.4);
        icon = Icons.edit_note;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Text(submission.statusLabel,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 14)),
        ),
        if (submission.isFinal)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20)),
            child: Text('FINAL',
                style: TextStyle(
                    color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
      ]),
    );
  }

  Widget _buildCategorySummary(ColorScheme cs) {
    final cats = [
      submission.cat1,
      submission.cat2,
      submission.cat3,
      submission.cat4,
      submission.cat5,
    ];
    return Column(
      children: List.generate(5, (i) {
        final pts = cats[i];
        final color = _catColors[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [
                Container(
                    width: 10,
                    height: 10,
                    decoration:
                        BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text('${i + 1}. ${_catNames[i]}',
                    style: TextStyle(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ]),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10)),
                child: Text('$pts / 100',
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ),
            ]),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: pts / 100,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
          ]),
        );
      }),
    );
  }

  Widget _buildDetailedBreakdown(ColorScheme cs) {
    final bd = submission.scoreBreakdown;
    if (bd.isEmpty || bd.keys.every((k) => k.startsWith('_'))) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.onSurface.withOpacity(0.08)),
        ),
        child: Text('Detailed breakdown not available.',
            style: TextStyle(color: cs.onSurface.withOpacity(0.5))),
      );
    }

    // Group criteria by category prefix
    final groups = <String, List<MapEntry<String, dynamic>>>{
      '1': [],
      '2': [],
      '3': [],
      '4': [],
      '5': [],
    };

    for (final entry in bd.entries) {
      if (entry.key.startsWith('_')) continue;
      final prefix = entry.key[0];
      if (groups.containsKey(prefix)) {
        groups[prefix]!.add(entry);
      }
    }

    return Column(
      children: List.generate(5, (catIdx) {
        final prefix = '${catIdx + 1}';
        final items = groups[prefix] ?? [];
        if (items.isEmpty) return const SizedBox.shrink();

        final color = _catColors[catIdx];

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(children: [
            // Category header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Text('${catIdx + 1}. ${_catNames[catIdx]}',
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
            // Criteria rows
            ...items.map((entry) {
              final data = entry.value as Map<String, dynamic>?;
              if (data == null) return const SizedBox.shrink();
              final label = data['label'] as String? ?? entry.key;
              final pts = (data['points'] as num?)?.toInt() ?? 0;
              final max = (data['max'] as num?)?.toInt() ?? 0;
              final value = data['value'];

              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                          child: Text(label,
                              style:
                                  TextStyle(color: cs.onSurface, fontSize: 13)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: pts > 0
                                ? color.withOpacity(0.12)
                                : cs.onSurface.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('$pts / $max',
                              style: TextStyle(
                                  color: pts > 0
                                      ? color
                                      : cs.onSurface.withOpacity(0.4),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12)),
                        ),
                      ]),
                      if (value != null &&
                          value.toString().isNotEmpty &&
                          value.toString() != '0' &&
                          value.toString() != '0.0') ...[
                        const SizedBox(height: 2),
                        Text('Value: $value',
                            style: TextStyle(
                                color: cs.onSurface.withOpacity(0.45),
                                fontSize: 11)),
                      ],
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: max > 0 ? (pts / max).clamp(0.0, 1.0) : 0,
                        backgroundColor: color.withOpacity(0.08),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 4,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      const SizedBox(height: 4),
                    ]),
              );
            }),
            const SizedBox(height: 8),
          ]),
        );
      }),
    );
  }

  Widget _buildReviewCard(SSMReview review, ColorScheme cs) {
    final isApproved = review.status == 'approved';
    final color = isApproved ? const Color(0xFF2E7D32) : cs.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(isApproved ? Icons.check_circle_outline : Icons.cancel_outlined,
            color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
              '${review.reviewerRole.toUpperCase()} — ${review.reviewerName ?? "Reviewer"}',
              style: TextStyle(
                  color: cs.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
          if (review.remarks != null && review.remarks!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(review.remarks!,
                style: TextStyle(
                    color: cs.onSurface.withOpacity(0.6), fontSize: 12)),
          ],
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8)),
          child: Text(isApproved ? 'Approved' : 'Rejected',
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
      ]),
    );
  }
}
