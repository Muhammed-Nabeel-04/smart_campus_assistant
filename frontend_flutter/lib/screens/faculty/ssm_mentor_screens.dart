import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../core/session.dart';

// ════════════════════════════════════════════════════════════════
// Mentor Dashboard Screen
// ════════════════════════════════════════════════════════════════

class SSMMentorDashboard extends StatefulWidget {
  const SSMMentorDashboard({super.key});
  @override
  State<SSMMentorDashboard> createState() => _SSMMentorDashboardState();
}

class _SSMMentorDashboardState extends State<SSMMentorDashboard>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _data;
  List<dynamic>? _allStudents;
  List<dynamic>? _activities;
  List<dynamic>? _hodPending;
  bool _loading = true;
  late TabController _tab;
  String _searchQuery = '';
  String _sortBy = 'name';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = (_data == null));
    try {
      final res = await Future.wait([
        ApiService.ssmGetMentorDashboard(),
        ApiService.ssmGetMentorAllStudents(),
        ApiService.ssmGetMentorActivities().catchError((_) => <String, dynamic>{'items': []}),
        ApiService.ssmGetMentorHodPending().catchError((_) => <String, dynamic>{'items': []}),
      ]);
      setState(() {
        _data = res[0];
        _allStudents = (res[1]['items'] as List?) ?? [];
        _activities = (res[2]['items'] as List?) ?? [];
        _hodPending = (res[3]['items'] as List?) ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load: $e')));
      }
    }
  }

  List<dynamic> _filteredStudents() {
    var students = (_allStudents ?? []).where((s) {
      final name = (s['student_name'] ?? '').toLowerCase();
      final reg = (s['register_number'] ?? '').toLowerCase();
      return name.contains(_searchQuery) || reg.contains(_searchQuery);
    }).toList();

    students.sort((a, b) {
      if (_sortBy == 'score') {
        final sa = (a['grand_total'] as num?) ?? 0;
        final sb = (b['grand_total'] as num?) ?? 0;
        return sb.compareTo(sa);
      } else if (_sortBy == 'pending') {
        final pa = (a['pending_activities'] as int?) ?? 0;
        final pb = (b['pending_activities'] as int?) ?? 0;
        return pb.compareTo(pa);
      }
      return (a['student_name'] ?? '').compareTo(b['student_name'] ?? '');
    });
    return students;
  }

  @override
  Widget build(BuildContext context) {
    final pending = (_data?['pending_reviews'] as List?) ?? [];
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mentor Dashboard',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: cs.onPrimary)),
            Text(_data?['mentor'] ?? '',
                style: TextStyle(
                    fontSize: 12, color: cs.onPrimary.withOpacity(0.8))),
          ],
        ),
        actions: [
          IconButton(
              icon: Icon(Icons.refresh_rounded, color: cs.onPrimary),
              onPressed: _load),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(115),
          child: Column(
            children: [
              _SummaryStrip(
                pending: pending.length,
                students: _allStudents?.length ?? 0,
                activities: _activities?.length ?? 0,
              ),
              TabBar(
                controller: _tab,
                indicatorColor: cs.onPrimary,
                indicatorWeight: 4,
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: cs.onPrimary,
                unselectedLabelColor: cs.onPrimary.withOpacity(0.5),
                labelStyle:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                isScrollable: true,
                tabs: [
                  Tab(text: 'Pending (${pending.length})'),
                  Tab(text: 'Students (${_allStudents?.length ?? 0})'),
                  Tab(text: 'Activities (${_activities?.length ?? 0})'),
                  Tab(text: 'With HOD (${_hodPending?.length ?? 0})'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: TabBarView(
                  controller: _tab,
                  children: [
                    // --- Forms Pending Tab ---
                    pending.isEmpty
                        ? const Center(child: Text('No pending reviews 🎉', style: TextStyle(color: Colors.grey)))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: pending.length,
                            itemBuilder: (_, i) => _PendingFormCard(form: pending[i]),
                          ),

                    // --- Students Tab ---
                    Column(children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(children: [
                          Expanded(child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Search...',
                              prefixIcon: const Icon(Icons.search),
                              isDense: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                          )),
                          const SizedBox(width: 8),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.sort),
                            onSelected: (v) => setState(() => _sortBy = v),
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'name', child: Text('Sort by Name')),
                              PopupMenuItem(value: 'score', child: Text('Sort by Score')),
                              PopupMenuItem(value: 'pending', child: Text('Sort by Pending')),
                            ],
                          ),
                        ]),
                      ),
                      Expanded(child: Builder(builder: (_) {
                        final students = _filteredStudents();
                        return students.isEmpty 
                          ? const Center(child: Text('No students found'))
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: students.length,
                              itemBuilder: (_, i) => _StudentCard(student: students[i]),
                            );
                      })),
                    ]),

                    // --- Activities Tab ---
                    _ActivitiesTab(activities: _activities ?? [], onRefresh: _load),

                    // --- With HOD Tab ---
                    (_hodPending ?? []).isEmpty
                        ? const Center(child: Text('No forms with HOD', style: TextStyle(color: Colors.grey)))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _hodPending!.length,
                            itemBuilder: (_, i) => _HodPendingCard(form: _hodPending![i]),
                          ),
                  ],
                ),
              ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// Mentor Review Screen
// ════════════════════════════════════════════════════════════════

class SSMMentorReviewScreen extends StatefulWidget {
  final int formId;
  const SSMMentorReviewScreen({required this.formId, super.key});

  @override
  State<SSMMentorReviewScreen> createState() => _SSMMentorReviewScreenState();
}

class _SSMMentorReviewScreenState extends State<SSMMentorReviewScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  bool _submitting = false;

  String _mentorFeedback = 'good';
  String _technicalSkill = 'good';
  String _softSkill = 'good';
  String _disciplineLevel = 'no_violations';
  String _dressCode = 'consistent';
  String _deptContrib = 'none';
  String _socialMedia = 'none';
  String _innovationInit = 'none';
  String _teamManagement = 'good';
  bool _lateEntries = false;
  final _remarksCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final d = await ApiService.ssmGetMentorFormDetails(widget.formId);
      setState(() { _data = d; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  Future<void> _submitReview() async {
    setState(() => _submitting = true);
    try {
      final payload = {
        'mentor_feedback': _mentorFeedback,
        'technical_skill': _technicalSkill,
        'soft_skill': _softSkill,
        'discipline_level': _disciplineLevel,
        'dress_code_level': _dressCode,
        'dept_contribution': _deptContrib,
        'social_media_level': _socialMedia,
        'late_entries': _lateEntries,
        'innovation_initiative': _innovationInit,
        'team_management_leadership': _teamManagement,
        'remarks': _remarksCtrl.text.trim(),
      };
      final res = await ApiService.ssmSubmitMentorReview(widget.formId, payload);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ Review submitted and forwarded to HOD'), backgroundColor: Colors.green));
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final student = _data?['student'];
    final activities = (_data?['activities'] as List?) ?? [];

    return Scaffold(
      appBar: AppBar(title: Text('Review: ${student?['name'] ?? ''}')),
      body: Stack(children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Student summary card
            Card(child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(student?['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(student?['register_number'] ?? ''),
              trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('${(_data?['current_score']?['grand_total'] ?? 0).toStringAsFixed(0)}', 
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Colors.blue)),
                const Text('Live Score', style: TextStyle(fontSize: 10)),
              ]),
            )),
            const SizedBox(height: 16),

            if (activities.isNotEmpty) ...[
              const Text('Activities to Approve', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...activities.map((a) => Card(child: ListTile(
                title: Text((a['activity_type'] as String).replaceAll('_', ' ').toUpperCase(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                subtitle: Text(a['mentor_status'], style: TextStyle(color: a['mentor_status'] == 'approved' ? Colors.green : Colors.orange)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showActivityActionSheet(a),
              ))),
              const SizedBox(height: 16),
            ],

            const Text('Mentor Evaluation', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            
            _buildDropdown('Academic Feedback', _mentorFeedback, (v) => setState(() => _mentorFeedback = v!), [
              ('average', 'Average (5 pts)'), ('good', 'Good (10 pts)'), ('excellent', 'Excellent (15 pts)')
            ]),
            _buildDropdown('Technical Skills', _technicalSkill, (v) => setState(() => _technicalSkill = v!), [
              ('basic', 'Basic (5 pts)'), ('good', 'Good (10 pts)'), ('excellent', 'Excellent (20 pts)')
            ]),
            _buildDropdown('Soft Skills', _softSkill, (v) => setState(() => _softSkill = v!), [
              ('average', 'Average (5 pts)'), ('good', 'Good (10 pts)'), ('excellent', 'Excellent (20 pts)')
            ]),

            const SizedBox(height: 16),
            TextFormField(
              controller: _remarksCtrl, maxLines: 3,
              decoration: const InputDecoration(labelText: 'Final Remarks', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),

            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: _submitReview,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
              child: const Text('SUBMIT & FORWARD TO HOD'),
            )),
            const SizedBox(height: 40),
          ]),
        ),
        if (_submitting) Container(color: Colors.black26, child: const Center(child: CircularProgressIndicator())),
      ]),
    );
  }

  Widget _buildDropdown(String label, String value, Function(String?) onChanged, List<(String, String)> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: value, decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        items: items.map((i) => DropdownMenuItem(value: i.$1, child: Text(i.$2))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  void _showActivityActionSheet(Map<String, dynamic> a) {
    final noteCtrl = TextEditingController();
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text((a['activity_type'] as String).toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'Note (optional for approval, required for rejection)')),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () async {
            if (noteCtrl.text.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Note required for rejection'))); return; }
            await ApiService.ssmRejectActivity(a['id'], noteCtrl.text);
            Navigator.pop(context); _load();
          }, child: const Text('REJECT', style: TextStyle(color: Colors.red)))),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(onPressed: () async {
            await ApiService.ssmApproveActivity(a['id'], note: noteCtrl.text.isEmpty ? null : noteCtrl.text);
            Navigator.pop(context); _load();
          }, child: const Text('APPROVE'))),
        ]),
      ]),
    ));
  }
}

// ════════════════════════════════════════════════════════════════
// Mentor Activity Detail Screen
// ════════════════════════════════════════════════════════════════

class SSMMentorActivityDetailScreen extends StatefulWidget {
  final int activityId;
  const SSMMentorActivityDetailScreen({required this.activityId, super.key});
  @override
  State<SSMMentorActivityDetailScreen> createState() => _SSMMentorActivityDetailScreenState();
}

class _SSMMentorActivityDetailScreenState extends State<SSMMentorActivityDetailScreen> {
  Map<String, dynamic>? _act;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final d = await ApiService.ssmGetMentorActivityDetail(widget.activityId);
      setState(() { _act = d; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_act == null) return const Scaffold(body: Center(child: Text('Not found')));

    return Scaffold(
      appBar: AppBar(title: const Text('Activity Detail')),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
          Text(_act!['activity_name'] ?? 'Activity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(),
          _row('Student', _act!['student_name']),
          _row('Register No', _act!['register_number']),
          _row('Status', _act!['status']),
          _row('Type', _act!['activity_type']),
        ]))),
      ])),
    );
  }
  Widget _row(String l, dynamic v) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(l), Text('$v', style: const TextStyle(fontWeight: FontWeight.bold))]));
}

// ─── HELPERS ──────────────────────────────────────────────────

class _PendingFormCard extends StatelessWidget {
  final Map<String, dynamic> form;
  const _PendingFormCard({required this.form});
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: ListTile(
      leading: const CircleAvatar(child: Icon(Icons.description)),
      title: Text(form['student_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(form['register_number'] ?? ''),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.pushNamed(context, '/ssmMentorReview', arguments: form['form_id']),
    ),
  );
}

class _StudentCard extends StatelessWidget {
  final Map<String, dynamic> student;
  const _StudentCard({required this.student});
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      title: Text(student['student_name'] ?? ''),
      subtitle: Text(student['register_number'] ?? ''),
      trailing: Text('${(student['grand_total'] ?? 0).toStringAsFixed(0)} pts', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
      onTap: student['form_id'] != null 
        ? () => Navigator.pushNamed(context, '/ssmMentorReview', arguments: student['form_id'])
        : null,
    ),
  );
}

class _HodPendingCard extends StatelessWidget {
  final Map<String, dynamic> form;
  const _HodPendingCard({required this.form});
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: ListTile(
      title: Text(form['student_name'] ?? ''),
      subtitle: const Text('Awaiting HOD Approval', style: TextStyle(color: Colors.orange, fontSize: 12)),
      trailing: const Icon(Icons.hourglass_bottom, color: Colors.orange),
      onTap: () => Navigator.pushNamed(context, '/ssmMentorReview', arguments: form['form_id']),
    ),
  );
}

class _ActivitiesTab extends StatefulWidget {
  final List<dynamic> activities;
  final Future<void> Function() onRefresh;
  const _ActivitiesTab({required this.activities, required this.onRefresh});
  @override
  State<_ActivitiesTab> createState() => _ActivitiesTabState();
}

class _ActivitiesTabState extends State<_ActivitiesTab> {
  String _filter = 'all';
  @override
  Widget build(BuildContext context) {
    final filtered = _filter == 'all' ? widget.activities : widget.activities.where((a) => (a['status'] ?? '').toLowerCase() == _filter).toList();
    return Column(children: [
      SingleChildScrollView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.all(8), child: Row(children: [
        _chip('all', 'All'), _chip('pending', 'Pending'), _chip('approved', 'Approved'), _chip('rejected', 'Rejected'),
      ])),
      Expanded(child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filtered.length,
        itemBuilder: (_, i) => Card(child: ListTile(
          title: Text(filtered[i]['activity_name'] ?? 'Activity'),
          subtitle: Text(filtered[i]['student_name'] ?? ''),
          trailing: Text(filtered[i]['status'] ?? ''),
          onTap: () => Navigator.pushNamed(context, '/ssmMentorActivityDetail', arguments: filtered[i]['activity_id']),
        )),
      )),
    ]);
  }
  Widget _chip(String id, String label) => Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(
    label: Text(label), selected: _filter == id, onSelected: (s) => setState(() => _filter = id),
  ));
}

// Re-using StarRating from HOD file or common
class StarRating extends StatelessWidget {
  final int stars;
  final double size;
  const StarRating({required this.stars, this.size = 16, super.key});
  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(5, (i) => Icon(
          i < stars ? Icons.star : Icons.star_border,
          color: Colors.amber, size: size,
        )),
      );
}

// ────────────────────────────────────────────────
// UI HELPERS
// ────────────────────────────────────────────────

class _SummaryStrip extends StatelessWidget {
  final int pending;
  final int students;
  final int activities;
  const _SummaryStrip(
      {required this.pending, required this.students, required this.activities});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: cs.onPrimary.withOpacity(0.12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StripStat(Icons.pending_actions_rounded, '$pending', 'Pending',
              Colors.amberAccent),
          Container(width: 1, height: 24, color: cs.onPrimary.withOpacity(0.2)),
          _StripStat(Icons.people_rounded, '$students', 'Students',
              const Color(0xFF69F0AE)),
          Container(width: 1, height: 24, color: cs.onPrimary.withOpacity(0.2)),
          _StripStat(Icons.list_alt_rounded, '$activities', 'Activities', cs.onPrimary),
        ],
      ),
    );
  }
}

class _StripStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _StripStat(this.icon, this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value,
                style: TextStyle(
                    color: cs.onPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900)),
            Text(label,
                style: TextStyle(
                    color: cs.onPrimary.withOpacity(0.85),
                    fontSize: 11,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }
}
