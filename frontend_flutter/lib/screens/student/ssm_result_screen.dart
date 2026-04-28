// File: lib/screens/student/ssm_result_screen.dart  (v3 — FULL REPLACE)
import 'package:flutter/material.dart';
import '../../models/ssm_models.dart';

class SSMResultScreen extends StatelessWidget {
  final SSMSubmission submission;
  const SSMResultScreen({super.key, required this.submission});

  static const _catColors = [
    Color(0xFF1565C0), Color(0xFF2E7D32), Color(0xFF6A1B9A),
    Color(0xFFE65100), Color(0xFFC62828),
  ];
  static const _catNames = [
    'Academic Performance', 'Student Development',
    'Skill & Readiness', 'Discipline & Contribution',
    'Leadership & Initiatives',
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final score = submission.totalScore.toInt();

    Color scoreColor;
    if (score >= 450) scoreColor = const Color(0xFF1B5E20);
    else if (score >= 400) scoreColor = const Color(0xFF2E7D32);
    else if (score >= 350) scoreColor = const Color(0xFF1565C0);
    else if (score >= 300) scoreColor = const Color(0xFFFF9800);
    else if (score >= 250) scoreColor = const Color(0xFFE65100);
    else scoreColor = cs.error;

    return Scaffold(
      appBar: AppBar(title: const Text('Score Breakdown'), centerTitle: false),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [

          // ── Main Score Card ──────────────────────────────
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [scoreColor, scoreColor.withOpacity(0.75)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: scoreColor.withOpacity(0.35),
                  blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: Column(children: [
              Text('SSM Total Score',
                  style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14)),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$score', style: const TextStyle(color: Colors.white,
                        fontSize: 72, fontWeight: FontWeight.bold, height: 1.0)),
                    Padding(padding: const EdgeInsets.only(bottom: 12, left: 4),
                      child: Text('/500', style: TextStyle(
                          color: Colors.white.withOpacity(0.7), fontSize: 22))),
                  ]),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) => Icon(
                      i < submission.starRating ? Icons.star : Icons.star_border,
                      color: Colors.white, size: 30))),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(submission.categoryLabel, style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const SizedBox(height: 14),
              LinearProgressIndicator(
                value: score / 500,
                backgroundColor: Colors.white.withOpacity(0.25),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 6, borderRadius: BorderRadius.circular(3),
              ),
            ]),
          ),

          const SizedBox(height: 20),

          // ── Status ───────────────────────────────────────
          _buildStatusCard(cs),
          const SizedBox(height: 20),

          // ── Category Scores ───────────────────────────────
          Text('Category Scores', style: TextStyle(
              color: cs.onBackground, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildCategoryBars(cs),
          const SizedBox(height: 20),

          // ── Activities / Entries ──────────────────────────
          if (submission.entries.isNotEmpty) ...[
            Text('Activities (${submission.entries.length})',
                style: TextStyle(color: cs.onBackground,
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...submission.entries.map((e) => _buildEntryTile(e, cs)),
            const SizedBox(height: 20),
          ],

          // ── Mentor Input ──────────────────────────────────
          if (submission.mentorInput != null) ...[
            Text('Mentor Evaluation', style: TextStyle(
                color: cs.onBackground, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildMentorInput(cs),
            const SizedBox(height: 20),
          ],

          // ── Review History ────────────────────────────────
          if (submission.reviews.isNotEmpty) ...[
            Text('Review History', style: TextStyle(
                color: cs.onBackground, fontSize: 18, fontWeight: FontWeight.bold)),
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
      case 'active':          color = const Color(0xFF2196F3); icon = Icons.edit_note_outlined; break;
      case 'submitted':       color = const Color(0xFFFF9800); icon = Icons.hourglass_empty; break;
      case 'mentor_approved': color = const Color(0xFF2196F3); icon = Icons.verified_outlined; break;
      case 'hod_approved':    color = const Color(0xFF2E7D32); icon = Icons.lock_outline; break;
      default:                color = cs.onBackground.withOpacity(0.4); icon = Icons.info_outline;
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
        Expanded(child: Text(submission.statusLabel,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14))),
        if (submission.isFinal)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
            child: Text('FINAL', style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
      ]),
    );
  }

  Widget _buildCategoryBars(ColorScheme cs) {
    final cats = [submission.cat1, submission.cat2, submission.cat3,
                  submission.cat4, submission.cat5];
    return Column(
      children: List.generate(5, (i) {
        final pts = cats[i];
        final color = _catColors[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.surface, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [
                Container(width: 10, height: 10,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text('${i + 1}. ${_catNames[i]}',
                    style: TextStyle(color: cs.onSurface,
                        fontWeight: FontWeight.w600, fontSize: 13)),
              ]),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                child: Text('$pts / 100', style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ]),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: pts / 100,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6, borderRadius: BorderRadius.circular(3),
            ),
          ]),
        );
      }),
    );
  }

  Widget _buildEntryTile(SSMEntry entry, ColorScheme cs) {
    final catIdx = (entry.category - 1).clamp(0, 4);
    final color = _catColors[catIdx];

    Color proofColor;
    IconData proofIcon;
    switch (entry.proofStatus) {
      case 'valid':        proofColor = const Color(0xFF2E7D32); proofIcon = Icons.check_circle; break;
      case 'review':       proofColor = const Color(0xFFFF9800); proofIcon = Icons.rate_review; break;
      case 'invalid':      proofColor = cs.error; proofIcon = Icons.cancel; break;
      case 'not_required': proofColor = cs.onSurface.withOpacity(0.3); proofIcon = Icons.check; break;
      default:             proofColor = const Color(0xFFFF9800); proofIcon = Icons.upload_file_outlined; break;
    }

    // Build a short detail summary
    final d = entry.details;
    final detailParts = <String>[];
    for (final key in ['gpa', 'percentage', 'level', 'duration', 'result',
                       'type', 'status', 'title', 'course', 'company',
                       'platform', 'event']) {
      if (d[key] != null && d[key].toString().isNotEmpty) {
        detailParts.add(d[key].toString());
        if (detailParts.length >= 2) break;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(children: [
        Container(width: 4, height: 40,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(entry.entryLabel, style: TextStyle(
              color: cs.onSurface, fontWeight: FontWeight.w600, fontSize: 13)),
          if (detailParts.isNotEmpty)
            Text(detailParts.join(' · '), style: TextStyle(
                color: cs.onSurface.withOpacity(0.45), fontSize: 11),
                maxLines: 1, overflow: TextOverflow.ellipsis),
        ])),
        const SizedBox(width: 8),
        if (entry.proofRequired && entry.proofStatus != 'not_required')
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Icon(proofIcon, color: proofColor, size: 16),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Text('+${entry.score.toInt()}',
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ]),
    );
  }

  Widget _buildMentorInput(ColorScheme cs) {
    final mi = submission.mentorInput!;
    final fields = <Map<String, String>>[];

    void add(String label, String? value) {
      if (value != null && value.isNotEmpty) {
        fields.add({'label': label, 'value': value});
      }
    }

    add('Mentor Feedback', mi['mentor_feedback']);
    add('HoD Feedback', mi['hod_feedback']);
    add('Technical Skill', mi['tech_skill_level']);
    add('Soft Skills', mi['soft_skill_level']);
    add('Placement Outcome', mi['placement_outcome']);
    add('Discipline & Conduct', mi['discipline_conduct']);
    add('Attendance & Punctuality', mi['punctuality_level']);
    add('Dress Code', mi['dress_code']);
    add('Dept Events Contribution', mi['dept_event_contribution']);
    add('Social Media', mi['social_media_level']);

    if (fields.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2196F3).withOpacity(0.2)),
      ),
      child: Column(
        children: fields.map((f) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            Expanded(child: Text(f['label']!,
                style: TextStyle(color: cs.onSurface.withOpacity(0.6), fontSize: 12))),
            Text(f['value']!, style: TextStyle(
                color: cs.onSurface, fontWeight: FontWeight.w600, fontSize: 12)),
          ]),
        )).toList(),
      ),
    );
  }

  Widget _buildReviewCard(SSMReview review, ColorScheme cs) {
    final isApproved = review.status == 'approved';
    final color = isApproved ? const Color(0xFF2E7D32) : cs.error;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07), borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(isApproved ? Icons.check_circle_outline : Icons.cancel_outlined,
            color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${review.reviewerRole.toUpperCase()} — ${review.reviewerName ?? "Reviewer"}',
              style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.bold, fontSize: 13)),
          if (review.remarks != null && review.remarks!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(review.remarks!, style: TextStyle(
                color: cs.onSurface.withOpacity(0.6), fontSize: 12)),
          ],
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
          child: Text(isApproved ? 'Approved' : 'Rejected',
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
      ]),
    );
  }
}
