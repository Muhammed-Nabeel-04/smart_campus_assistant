// File: lib/screens/student/ssm_activity_dashboard.dart
// Replaces student_performance_tab.dart
// Ported from standalone SSM app — adapted for campus app routing + SessionManager

import 'package:flutter/material.dart';
import '../../core/session.dart';
import '../../services/api_service.dart';

class SSMActivityDashboard extends StatefulWidget {
  const SSMActivityDashboard({super.key});

  @override
  State<SSMActivityDashboard> createState() => _SSMActivityDashboardState();
}

class _SSMActivityDashboardState extends State<SSMActivityDashboard> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;
  String _filter = 'all';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = _data == null; _error = null; });
    try {
      final d = await ApiService.ssmGetMyActivities();
      if (mounted) setState(() { _data = d; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final activities = (_data?['activities'] as List?) ?? [];
    final score = _data?['live_score'] as Map?;
    final status = _data?['status'] as String? ?? 'draft';
    final canEdit = (status == 'draft' || status == 'rejected');

    final filtered = _filter == 'all' ? activities
        : activities.where((a) => _categoryOf(a['activity_type'] ?? '') == _filter).toList();

    if (_loading) return Center(child: CircularProgressIndicator(color: cs.primary));
    if (_error != null) return _errorView(cs);

    return RefreshIndicator(
      onRefresh: _load,
      color: cs.primary,
      child: CustomScrollView(slivers: [

        // ── Score card ──────────────────────────────────────────
        SliverToBoxAdapter(
          child: GestureDetector(
            onTap: _data?['form_id'] != null
                ? () => Navigator.pushNamed(context, '/ssmScore',
                    arguments: _data!['form_id'])
                : null,
            child: _ScoreCard(score: score, status: status),
          ),
        ),

        // ── Timeline Banner ──────────────────────────────
        if (_data?['form_id'] != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: InkWell(
                onTap: () => Navigator.pushNamed(context, '/ssmTimeline',
                    arguments: _data!['form_id']),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cs.primary.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.timeline_rounded, color: cs.primary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'View Performance Timeline',
                          style: TextStyle(
                              color: cs.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          color: cs.primary, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // ── Submit / Status banner ──────────────────────────────
        if (canEdit && activities.isNotEmpty)
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.send_rounded),
              label: const Text('Submit Form to Mentor',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              onPressed: _submitForm,
            ),
          )),

        if (!canEdit)
          SliverToBoxAdapter(child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2E7D32).withOpacity(0.3)),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.lock_rounded, color: const Color(0xFF2E7D32), size: 18),
              const SizedBox(width: 8),
              Text(_statusLabel(status),
                  style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
            ]),
          )),

        // ── Category filter ─────────────────────────────────────
        SliverToBoxAdapter(child: _CategoryFilter(
          selected: _filter,
          onChanged: (v) => setState(() => _filter = v),
        )),

        // ── Activity list ───────────────────────────────────────
        if (filtered.isEmpty)
          SliverToBoxAdapter(child: _emptyState(cs, canEdit))
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverList(delegate: SliverChildBuilderDelegate(
              (_, i) => _ActivityCard(
                activity: filtered[i],
                onDelete: canEdit ? () => _deleteActivity(filtered[i]['id']) : null,
              ),
              childCount: filtered.length,
            )),
          ),
      ]),
    );
  }

  Future<void> _submitForm() async {
    final formId = _data?['form_id'] as int?;
    if (formId == null) return;

    final confirm = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Submit Form?'),
      content: const Text('Once submitted, you cannot add or delete activities until your mentor completes the review. Proceed?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(context, true),
            child: const Text('Submit', style: TextStyle(fontWeight: FontWeight.bold))),
      ],
    ));
    if (confirm != true || !mounted) return;

    try {
      await ApiService.ssmSubmitFormForReview(formId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✓ Form submitted to mentor!'),
          backgroundColor: Color(0xFF2E7D32),
        ));
        _load();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }

  Future<void> _deleteActivity(int id) async {
    final confirm = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Delete Activity?'),
      content: const Text('This activity and its document will be permanently deleted.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red))),
      ],
    ));
    if (confirm != true || !mounted) return;
    try {
      await ApiService.ssmDeleteStudentActivity(id);
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }

  String _categoryOf(String type) {
    const devTypes = ['nptel','online_cert','internship','competition','publication','prof_program'];
    const skillTypes = ['placement','higher_study','industry_int','research'];
    const leadTypes = ['formal_role','event_org','community'];
    if (devTypes.contains(type)) return 'development';
    if (skillTypes.contains(type)) return 'skill';
    if (leadTypes.contains(type)) return 'leadership';
    return 'academic';
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'submitted':     return 'Submitted — Awaiting mentor review';
      case 'mentor_review': return 'Under mentor review';
      case 'hod_review':    return 'Under HOD review';
      case 'approved':      return '✓ Score Approved & Locked';
      case 'rejected':      return 'Returned — Please re-submit after corrections';
      default:              return s;
    }
  }

  Widget _emptyState(ColorScheme cs, bool canEdit) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 32),
    child: Column(children: [
      Icon(Icons.playlist_add_rounded, size: 60,
          color: cs.onBackground.withOpacity(0.2)),
      const SizedBox(height: 16),
      Text(
        _filter == 'all'
            ? 'No activities yet.\nTap + to add your first!'
            : 'No activities in this category.',
        textAlign: TextAlign.center,
        style: TextStyle(color: cs.onBackground.withOpacity(0.5), fontSize: 14),
      ),
      if (canEdit && _filter == 'all') ...[
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _openAddActivity,
          icon: const Icon(Icons.add),
          label: const Text('Add First Activity'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ]
    ]),
  );

  void _openAddActivity() async {
    final added = await Navigator.pushNamed(context, '/ssmAddActivity');
    if (added == true) _load();
  }

  Widget _errorView(ColorScheme cs) => Center(child: Padding(
    padding: const EdgeInsets.all(32),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.cloud_off, size: 56, color: cs.error.withOpacity(0.4)),
      const SizedBox(height: 16),
      Text(_error!, textAlign: TextAlign.center,
          style: TextStyle(color: cs.onBackground.withOpacity(0.6))),
      const SizedBox(height: 24),
      ElevatedButton(onPressed: _load, child: const Text('Retry')),
    ]),
  ));
}


// ─── SCORE CARD ───────────────────────────────────────────────────────────────

class _ScoreCard extends StatelessWidget {
  final Map? score;
  final String status;
  const _ScoreCard({this.score, required this.status});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final total = (score?['grand_total'] ?? 0) as num;
    final stars = (score?['star_rating'] ?? 0) as int;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: cs.primary.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Subtle Background Pattern or Glow
            Positioned(
              right: -30,
              top: -30,
              child: CircleAvatar(
                radius: 80,
                backgroundColor: cs.onPrimary.withOpacity(0.08),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: score == null
                  ? Center(
                      child: Text('Add activities to see your live score',
                          style: TextStyle(
                              color: cs.onPrimary.withOpacity(0.7),
                              fontSize: 14)))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('OVERALL SSM SCORE',
                                    style: TextStyle(
                                        color: cs.onPrimary.withOpacity(0.7),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.2)),
                                const SizedBox(height: 4),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text('${total.toStringAsFixed(0)}',
                                        style: TextStyle(
                                            color: cs.onPrimary,
                                            fontSize: 48,
                                            fontWeight: FontWeight.w900,
                                            height: 1)),
                                    Text(' / 500',
                                        style: TextStyle(
                                            color: cs.onPrimary.withOpacity(0.5),
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: cs.onPrimary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                  children: List.generate(
                                      5,
                                      (i) => Icon(
                                          i < stars
                                              ? Icons.star_rounded
                                              : Icons.star_outline_rounded,
                                          color: i < stars
                                              ? Colors.amberAccent
                                              : cs.onPrimary.withOpacity(0.3),
                                          size: 20))),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Categories Grid
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cs.onPrimary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _Pill('Acad', score!['academic'] ?? 0),
                              _Pill('Dev', score!['development'] ?? 0),
                              _Pill('Skill', score!['skill'] ?? 0),
                              _Pill('Disc', score!['discipline'] ?? 0),
                              _Pill('Lead', score!['leadership'] ?? 0),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final num score;
  const _Pill(this.label, this.score);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(score.toStringAsFixed(0),
            style: TextStyle(
                color: cs.onPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 18)),
        const SizedBox(height: 2),
        Text(label.toUpperCase(),
            style: TextStyle(
                color: cs.onPrimary.withOpacity(0.6),
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5)),
      ],
    );
  }
}


// ─── CATEGORY FILTER ──────────────────────────────────────────────────────────

class _CategoryFilter extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  const _CategoryFilter({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('all',        'All',      Icons.apps_rounded),
      ('academic',   'Academic', Icons.school_rounded),
      ('development','Dev',      Icons.workspace_premium_outlined),
      ('skill',      'Skill',    Icons.trending_up_rounded),
      ('leadership', 'Lead',     Icons.emoji_events_outlined),
    ];
    return SizedBox(
      height: 48,
      child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12),
        children: items.map((item) {
          final isSelected = selected == item.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(item.$3, size: 14,
                    color: isSelected ? Colors.white : Colors.grey),
                const SizedBox(width: 4),
                Text(item.$2),
              ]),
              selected: isSelected,
              onSelected: (_) => onChanged(item.$1),
              selectedColor: Theme.of(context).colorScheme.primary,
              labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey,
                  fontSize: 12, fontWeight: FontWeight.w500),
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: 6),
            ),
          );
        }).toList(),
      ),
    );
  }
}


// ─── ACTIVITY CARD ────────────────────────────────────────────────────────────

class _ActivityCard extends StatelessWidget {
  final Map<String, dynamic> activity;
  final VoidCallback? onDelete;
  const _ActivityCard({required this.activity, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final type = activity['activity_type'] as String? ?? '';
    final ocrStatus    = activity['ocr_status']    as String? ?? '';
    final mentorStatus = activity['mentor_status'] as String? ?? '';
    final data     = activity['data']     as Map?    ?? {};
    final filename = activity['filename'] as String?;
    final mentorNote = activity['mentor_note'] as String?;
    final ocrNote    = activity['ocr_note']    as String?;

    final (icon, color) = _typeInfo(type);
    final (statusColor, statusLabel) = _statusInfo(ocrStatus, mentorStatus);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: color.withOpacity(0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_typeLabel(type), style: TextStyle(
                  color: cs.onSurface, fontWeight: FontWeight.w700, fontSize: 14)),
              if (activity['submitted_at'] != null)
                Text(_fmtDate(activity['submitted_at']), style: TextStyle(
                    color: cs.onSurface.withOpacity(0.4), fontSize: 11)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor.withOpacity(0.3)),
              ),
              child: Text(statusLabel, style: TextStyle(
                  color: statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ]),

          if (data.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 4,
              children: data.entries.take(3).map((e) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: cs.onSurface.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('${_fieldLabel(e.key)}: ${e.value}',
                    style: TextStyle(fontSize: 11, color: cs.onSurface)),
              )).toList(),
            ),
          ],

          if (filename != null) ...[
            const SizedBox(height: 6),
            Row(children: [
              Icon(Icons.attach_file_rounded, size: 13,
                  color: cs.onSurface.withOpacity(0.4)),
              const SizedBox(width: 4),
              Expanded(child: Text(filename,
                  style: TextStyle(fontSize: 11, color: cs.onSurface.withOpacity(0.4)),
                  overflow: TextOverflow.ellipsis)),
            ]),
          ],

          if (ocrStatus == 'failed') ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 16),
                const SizedBox(width: 6),
                Expanded(child: Text(ocrNote ?? 'Document verification failed. Please re-upload.',
                    style: const TextStyle(color: Colors.red, fontSize: 11))),
              ]),
            ),
          ],

          if (mentorNote != null && mentorNote.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Mentor: $mentorNote',
                style: TextStyle(color: cs.onSurface.withOpacity(0.5),
                    fontSize: 11, fontStyle: FontStyle.italic)),
          ],

          if (mentorStatus != 'approved' && onDelete != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red),
                label: const Text('Delete', style: TextStyle(color: Colors.red, fontSize: 12)),
                style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
              ),
            ),
          ],
        ]),
      ),
    );
  }

  (IconData, Color) _typeInfo(String t) => switch (t) {
    'gpa_update'   => (Icons.school_rounded,             const Color(0xFF1565C0)),
    'project'      => (Icons.code_rounded,               const Color(0xFF1565C0)),
    'nptel'        => (Icons.workspace_premium_rounded,  const Color(0xFF2E7D32)),
    'online_cert'  => (Icons.laptop_rounded,             const Color(0xFF2E7D32)),
    'internship'   => (Icons.work_outline_rounded,       const Color(0xFF2E7D32)),
    'competition'  => (Icons.emoji_events_rounded,       const Color(0xFF2E7D32)),
    'publication'  => (Icons.article_rounded,            const Color(0xFF2E7D32)),
    'prof_program' => (Icons.event_rounded,              const Color(0xFF2E7D32)),
    'placement'    => (Icons.business_center_rounded,    const Color(0xFF6A1B9A)),
    'higher_study' => (Icons.import_contacts_rounded,   const Color(0xFF6A1B9A)),
    'industry_int' => (Icons.factory_rounded,            const Color(0xFF6A1B9A)),
    'research'     => (Icons.biotech_rounded,            const Color(0xFF6A1B9A)),
    'formal_role'  => (Icons.star_rounded,               const Color(0xFFC62828)),
    'event_org'    => (Icons.celebration_rounded,        const Color(0xFFC62828)),
    'community'    => (Icons.group_rounded,              const Color(0xFFC62828)),
    _              => (Icons.task_rounded,               Colors.grey),
  };

  (Color, String) _statusInfo(String ocr, String mentor) {
    if (ocr == 'failed') return (Colors.red, 'Re-upload needed');
    if (mentor == 'approved') return (const Color(0xFF2E7D32), 'Approved ✓');
    if (mentor == 'rejected') return (Colors.red, 'Rejected');
    if (mentor == 'not_required') return (const Color(0xFF2E7D32), 'Auto-verified ✓');
    if (ocr == 'valid') return (const Color(0xFF1565C0), 'Sent to mentor');
    if (ocr == 'review') return (const Color(0xFFFF9800), 'Under review');
    return (Colors.grey, 'Pending');
  }

  String _typeLabel(String t) => switch (t) {
    'gpa_update'   => 'Academic Update (GPA / Attendance)',
    'project'      => 'Project / Beyond Curriculum',
    'nptel'        => 'NPTEL / SWAYAM Certificate',
    'online_cert'  => 'Online Course Certificate',
    'internship'   => 'Internship / In-plant Training',
    'competition'  => 'Competition / Hackathon',
    'publication'  => 'Publication / Patent / Prototype',
    'prof_program' => 'Professional Skill Program',
    'placement'    => 'Placement Offer',
    'higher_study' => 'Higher Studies (GATE / GRE)',
    'industry_int' => 'Industry Interaction',
    'research'     => 'Research Paper',
    'formal_role'  => 'Formal Leadership Role',
    'event_org'    => 'Event Organization',
    'community'    => 'Community / Social Service',
    _              => t,
  };

  String _fieldLabel(String k) => switch (k) {
    'nptel_tier'         => 'Tier',
    'course_name'        => 'Course',
    'platform_name'      => 'Platform',
    'internship_company' => 'Company',
    'internship_duration'=> 'Duration',
    'competition_name'   => 'Event',
    'competition_result' => 'Result',
    'publication_title'  => 'Title',
    'placement_lpa'      => 'LPA',
    'role_level'         => 'Level',
    'internal_gpa'       => 'Int GPA',
    'university_gpa'     => 'Univ GPA',
    'attendance_pct'     => 'Attendance',
    _                    => k,
  };

  String _fmtDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) { return iso; }
  }
}
