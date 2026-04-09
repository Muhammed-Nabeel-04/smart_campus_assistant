// File: lib/screens/student/student_performance_tab.dart
// ─────────────────────────────────────────────────────────
// Performance Tab inside Student Dashboard bottom nav
// Shows SSM score out of 500, 5 category breakdown, status, and actions
// ─────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../../core/session.dart';
import '../../models/ssm_models.dart';
import '../../services/api_service.dart';
import 'ssm_form_screen.dart';
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

  // 5 category colors + names
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
          // ── Header ──────────────────────────────────────
          Text('Performance Score',
              style: TextStyle(
                  color: cs.onBackground,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Student Success Matrix (SSM) — AY 2025-26',
              style: TextStyle(
                  color: cs.onBackground.withOpacity(0.5), fontSize: 13)),
          const SizedBox(height: 20),

          if (_hasSubmission && _submission != null) ...[
            _buildScoreCard(cs),
            const SizedBox(height: 16),
            _buildStatusCard(cs),
            const SizedBox(height: 20),
            _buildCategoryBars(cs),
            const SizedBox(height: 20),
            _buildActionButtons(cs),
          ] else ...[
            _buildEmptyCard(cs),
            const SizedBox(height: 20),
            _buildStartButton(cs),
            const SizedBox(height: 24),
            _buildScoringInfo(cs),
          ],

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ── Main Score Card ────────────────────────────────────
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
        padding: const EdgeInsets.all(28),
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
                offset: const Offset(0, 10)),
          ],
        ),
        child: Column(children: [
          Text('Your SSM Score',
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
                          color: Colors.white.withOpacity(0.7), fontSize: 20)),
                ),
              ]),
          const SizedBox(height: 10),
          // Stars
          Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                  5,
                  (i) => Icon(
                      i < sub.starRating ? Icons.star : Icons.star_border,
                      color: Colors.white,
                      size: 30))),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(sub.categoryLabel,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
          ),
          const SizedBox(height: 14),
          // Progress bar
          LinearProgressIndicator(
            value: score / 500,
            backgroundColor: Colors.white.withOpacity(0.25),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
          const SizedBox(height: 8),
          Text('Tap to view full breakdown →',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.7), fontSize: 12)),
        ]),
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
        statusColor = cs.onBackground.withOpacity(0.4);
        statusIcon = Icons.edit_note_outlined;
        break;
      case 'submitted':
        statusColor = const Color(0xFFFF9800);
        statusIcon = Icons.hourglass_empty_outlined;
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
        statusColor = const Color(0xFF2E7D32);
        statusIcon = Icons.lock_outline;
        break;
      case 'hod_rejected':
        statusColor = cs.error;
        statusIcon = Icons.block_outlined;
        break;
      default:
        statusColor = cs.onBackground.withOpacity(0.4);
        statusIcon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.35)),
      ),
      child: Row(children: [
        Icon(statusIcon, color: statusColor, size: 26),
        const SizedBox(width: 14),
        Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(sub.statusLabel,
                style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
            if (sub.reviews.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '${sub.reviews.last.reviewerRole.toUpperCase()}: ${sub.reviews.last.remarks ?? "No remarks"}',
                style: TextStyle(
                    color: cs.onBackground.withOpacity(0.5), fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        )),
        if (sub.isFinal)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('FINAL',
                style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ),
      ]),
    );
  }

  // ── 5 Category Bars ────────────────────────────────────
  Widget _buildCategoryBars(ColorScheme cs) {
    final sub = _submission!;
    final cats = [sub.cat1, sub.cat2, sub.cat3, sub.cat4, sub.cat5];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Category Scores',
            style: TextStyle(
                color: cs.onBackground,
                fontSize: 17,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...List.generate(5, (i) {
          final pts = cats[i];
          final color = _catColors[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Column(children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration:
                          BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
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
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('$pts / 100',
                        style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ),
                ],
              ),
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
      ],
    );
  }

  // ── Action Buttons ─────────────────────────────────────
  Widget _buildActionButtons(ColorScheme cs) {
    final sub = _submission!;
    return Column(children: [
      // Edit button
      if (sub.canEdit)
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            SSMFormScreen(existingFormData: sub.formData)))
                .then((changed) {
              if (changed == true) _load();
            }),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit SSM Form'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),

      if (sub.canEdit) const SizedBox(height: 10),

      // Submit button
      if (sub.canEdit && sub.status != 'submitted')
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _submitForApproval,
            icon: const Icon(Icons.send_outlined),
            label: const Text('Submit for Mentor Approval'),
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
    ]);
  }

  Future<void> _submitForApproval() async {
    final sub = _submission!;
    if (sub.totalScore == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please fill the SSM form first.'),
        backgroundColor: Colors.orange,
      ));
      return;
    }
    try {
      await ApiService.ssmSubmitForApproval(sub.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✓ Submitted for mentor review!'),
          backgroundColor: Color(0xFF4CAF50),
        ));
        _load();
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }

  // ── Empty / Start Card ─────────────────────────────────
  Widget _buildEmptyCard(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cs.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.primary.withOpacity(0.15)),
      ),
      child: Column(children: [
        Icon(Icons.stars_outlined,
            size: 60, color: cs.primary.withOpacity(0.4)),
        const SizedBox(height: 16),
        Text('No SSM Submission Yet',
            style: TextStyle(
                color: cs.onBackground,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(
          'Fill your Student Success Matrix form to calculate your performance score across 5 categories.',
          textAlign: TextAlign.center,
          style:
              TextStyle(color: cs.onBackground.withOpacity(0.5), fontSize: 13),
        ),
      ]),
    );
  }

  Widget _buildStartButton(ColorScheme cs) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SSMFormScreen()))
            .then((changed) {
          if (changed == true) _load();
        }),
        icon: const Icon(Icons.add_chart_outlined, size: 22),
        label: const Text('Start My SSM Form',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _buildScoringInfo(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.onSurface.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Star Rating Scale',
              style: TextStyle(
                  color: cs.onBackground,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
          const SizedBox(height: 12),
          ...[
            [5, '450 – 500', const Color(0xFF1B5E20)],
            [4, '400 – 449', const Color(0xFF2E7D32)],
            [3, '350 – 399', const Color(0xFF1565C0)],
            [2, '300 – 349', const Color(0xFFFF9800)],
            [1, '250 – 299', const Color(0xFFE65100)],
          ].map((row) {
            final stars = row[0] as int;
            final range = row[1] as String;
            final color = row[2] as Color;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Row(
                    children: List.generate(
                        5,
                        (i) => Icon(i < stars ? Icons.star : Icons.star_border,
                            color: color, size: 16))),
                const SizedBox(width: 10),
                Text(range,
                    style: TextStyle(
                        color: cs.onBackground.withOpacity(0.7), fontSize: 13)),
              ]),
            );
          }),
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
      ),
    );
  }
}
