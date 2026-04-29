import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../services/api_service.dart';
import '../../core/session.dart';

// ════════════════════════════════════════════════════════════════
// HOD Dashboard Screen (Enhanced)
// ════════════════════════════════════════════════════════════════

class SSMHodDashboard extends StatefulWidget {
  const SSMHodDashboard({super.key});
  @override
  State<SSMHodDashboard> createState() => _SSMHodDashboardState();
}

class _SSMHodDashboardState extends State<SSMHodDashboard>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _data;
  List<dynamic>? _allStudents;
  List<dynamic>? _approved;
  bool _loading = true;
  late TabController _tab;

  // Students tab filters
  String _searchQuery = '';
  String _sortBy = 'name';
  String _filterStatus = 'all'; // all | submitted | not_submitted

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = (_data == null));
    try {
      final res = await Future.wait([
        ApiService.ssmGetHodDashboard(),
        ApiService.ssmGetHodAllStudents(),
      ]);
      setState(() {
        _data = res[0];
        final studentsData = res[1];
        _allStudents = (studentsData['items'] as List?) ?? [];
        _loading = false;
        debugPrint('HOD Dashboard Data: $_data');
        debugPrint('HOD All Students Count: ${_allStudents?.length}');
      });
    } catch (e) {
      debugPrint('HOD Load Error: $e');
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load: $e')),
        );
      }
    }

    // Load approved separately
    try {
      final approvedData = await ApiService.ssmGetHodApproved();
      setState(() {
        _approved = (approvedData['items'] as List?) ?? [];
      });
    } catch (_) {
      setState(() => _approved = []);
    }
  }

  List<dynamic> get _pending => (_data?['pending_approvals'] as List?) ?? [];

  List<dynamic> _filteredStudents() {
    var students = (_allStudents ?? []).where((s) {
      final name = (s['student_name'] ?? '').toString().toLowerCase();
      final reg = (s['register_number'] ?? '').toString().toLowerCase();
      final q = _searchQuery.toLowerCase();
      final matchesSearch = q.isEmpty || name.contains(q) || reg.contains(q);

      final status = (s['form_status'] ?? '').toString();
      final hasSubmitted = status == 'hod_review' ||
          status == 'approved' ||
          status == 'mentor_review' ||
          status == 'submitted' ||
          status == 'draft';
      final matchesFilter = _filterStatus == 'all' ||
          (_filterStatus == 'submitted' && hasSubmitted) ||
          (_filterStatus == 'not_submitted' && !hasSubmitted);

      return matchesSearch && matchesFilter;
    }).toList();

    students.sort((a, b) {
      switch (_sortBy) {
        case 'score':
          final sa = (a['grand_total'] as num?) ?? 0;
          final sb = (b['grand_total'] as num?) ?? 0;
          return sb.compareTo(sa);
        case 'status':
          return (a['form_status'] ?? '')
              .toString()
              .compareTo((b['form_status'] ?? '').toString());
        case 'reg':
          return (a['register_number'] ?? '')
              .toString()
              .compareTo((b['register_number'] ?? '').toString());
        default:
          return (a['student_name'] ?? '')
              .toString()
              .compareTo((b['student_name'] ?? '').toString());
      }
    });
    return students;
  }

  @override
  Widget build(BuildContext context) {
    final pending = _pending;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 0,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('HOD SSM Dashboard',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: cs.onPrimary)),
          if (_data?['hod'] != null)
            Text(_data!['hod'],
                style: TextStyle(
                    fontSize: 12, color: cs.onPrimary.withOpacity(0.8))),
        ]),
        actions: [
          IconButton(
              icon: Icon(Icons.bar_chart_rounded, color: cs.onPrimary),
              tooltip: 'Department Report',
              onPressed: () => Navigator.pushNamed(context, '/ssmHodReport')),
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
                approved: _data?['approved_count'] ?? 0,
                total: _data?['total_students'] ?? 0,
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
                tabs: [
                  Tab(text: 'Pending (${pending.length})'),
                  Tab(text: 'Approved (${_data?['approved_count'] ?? 0})'),
                  Tab(text: 'Students (${_allStudents?.length ?? 0})'),
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
                  _PendingTab(pending: pending),
                  _ApprovedTab(approved: _approved),
                  _StudentsTab(
                    students: _filteredStudents(),
                    totalCount: _allStudents?.length ?? 0,
                    searchQuery: _searchQuery,
                    sortBy: _sortBy,
                    filterStatus: _filterStatus,
                    onSearch: (v) =>
                        setState(() => _searchQuery = v.toLowerCase()),
                    onSort: (v) => setState(() => _sortBy = v),
                    onFilter: (v) => setState(() => _filterStatus = v),
                  ),
                ],
              ),
            ),
    );
  }
}

// ────────────────────────────────────────────────
class _SummaryStrip extends StatelessWidget {
  final int pending;
  final dynamic approved;
  final dynamic total;
  const _SummaryStrip(
      {required this.pending, required this.approved, required this.total});

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
          _StripStat(Icons.hourglass_empty_rounded, '$pending', 'Pending',
              Colors.amberAccent),
          Container(width: 1, height: 24, color: cs.onPrimary.withOpacity(0.2)),
          _StripStat(Icons.check_circle_rounded, '$approved', 'Approved',
              const Color(0xFF69F0AE)), // brighter green
          Container(width: 1, height: 24, color: cs.onPrimary.withOpacity(0.2)),
          _StripStat(Icons.people_rounded, '$total', 'Total', cs.onPrimary),
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

// ────────────────────────────────────────────────
// PENDING TAB
// ────────────────────────────────────────────────
class _PendingTab extends StatelessWidget {
  final List<dynamic> pending;
  const _PendingTab({required this.pending});

  @override
  Widget build(BuildContext context) {
    if (pending.isEmpty) {
      return const SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: 300,
          child: Center(
            child: Text('No pending approvals 🎉',
                style: TextStyle(color: Colors.grey)),
          ),
        ),
      );
    }
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: pending.length,
      itemBuilder: (context, i) => _HodPendingCard(form: pending[i]),
    );
  }
}

// ────────────────────────────────────────────────
// APPROVED TAB
// ────────────────────────────────────────────────
class _ApprovedTab extends StatelessWidget {
  final List<dynamic>? approved;
  const _ApprovedTab({required this.approved});

  @override
  Widget build(BuildContext context) {
    if (approved == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (approved!.isEmpty) {
      return const SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: 300,
          child: Center(
            child: Text('No approved forms yet',
                style: TextStyle(color: Colors.grey)),
          ),
        ),
      );
    }
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: approved!.length,
      itemBuilder: (context, i) => _ApprovedCard(form: approved![i]),
    );
  }
}

class _ApprovedCard extends StatelessWidget {
  final Map<String, dynamic> form;
  const _ApprovedCard({required this.form});

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: form['form_id'] != null
              ? () => Navigator.pushNamed(context, '/ssmHodApproval', arguments: form['form_id'])
              : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              CircleAvatar(
                backgroundColor: Colors.green.withOpacity(0.15),
                child: const Icon(Icons.check_circle_rounded,
                    color: Colors.green),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(form['student_name'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text(form['register_number'] ?? '',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12)),
                      Text('AY ${form['academic_year'] ?? ''}',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 11)),
                    ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                if (form['final_score'] != null || form['grand_total'] != null)
                  Text(
                    '${((form['final_score'] ?? form['grand_total']) as num).toStringAsFixed(0)} pts',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.green,
                        fontSize: 14),
                  ),
                if (form['star_rating'] != null)
                  StarRating(stars: form['star_rating'] as int, size: 14),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Approved',
                      style: TextStyle(
                          color: Colors.green,
                          fontSize: 10,
                          fontWeight: FontWeight.w600)),
                ),
              ]),
            ]),
          ),
        ),
      );
}

// ────────────────────────────────────────────────
// STUDENTS TAB
// ────────────────────────────────────────────────
class _StudentsTab extends StatelessWidget {
  final List<dynamic> students;
  final int totalCount;
  final String searchQuery;
  final String sortBy;
  final String filterStatus;
  final ValueChanged<String> onSearch;
  final ValueChanged<String> onSort;
  final ValueChanged<String> onFilter;

  const _StudentsTab({
    required this.students,
    required this.totalCount,
    required this.searchQuery,
    required this.sortBy,
    required this.filterStatus,
    required this.onSearch,
    required this.onSort,
    required this.onFilter,
  });

  PopupMenuItem<String> _menuItem(
      String value, String label, bool selected, IconData icon, Color hodColor) {
    return PopupMenuItem(
      value: value,
      child: Row(children: [
        Icon(icon,
            size: 18,
            color: selected ? hodColor : Colors.grey),
        const SizedBox(width: 10),
        Text(label,
            style: TextStyle(
                fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                color: selected ? hodColor : null)),
        if (selected) ...[
          const Spacer(),
          Icon(Icons.check_rounded, size: 16, color: hodColor),
        ]
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hodColor = Theme.of(context).colorScheme.primary;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search name or reg no...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onChanged: onSearch,
                ),
              ),
              const SizedBox(width: 6),
              PopupMenuButton<String>(
                tooltip: 'Filter',
                icon: Badge(
                  isLabelVisible: filterStatus != 'all',
                  child: const Icon(Icons.filter_list_rounded),
                ),
                onSelected: onFilter,
                itemBuilder: (_) => [
                  _menuItem('all', 'All Students', filterStatus == 'all',
                      Icons.people_rounded, hodColor),
                  _menuItem('submitted', 'Submitted',
                      filterStatus == 'submitted', Icons.upload_file_rounded, hodColor),
                  _menuItem('not_submitted', 'Not Submitted',
                      filterStatus == 'not_submitted', Icons.pending_outlined, hodColor),
                ],
              ),
              PopupMenuButton<String>(
                tooltip: 'Sort',
                icon: const Icon(Icons.sort_rounded),
                onSelected: onSort,
                itemBuilder: (_) => [
                  _menuItem('name', 'Sort by Name', sortBy == 'name',
                      Icons.sort_by_alpha_rounded, hodColor),
                  _menuItem('reg', 'Sort by Reg No', sortBy == 'reg',
                      Icons.numbers_rounded, hodColor),
                  _menuItem('score', 'Sort by Score', sortBy == 'score',
                      Icons.star_rounded, hodColor),
                  _menuItem('status', 'Sort by Status', sortBy == 'status',
                      Icons.pending_actions_rounded, hodColor),
                ],
              ),
            ],
          ),
        ),

        // Active filter chips
        if (filterStatus != 'all' || searchQuery.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
            child: Row(children: [
              Expanded(
                child: Wrap(spacing: 6, children: [
                  if (filterStatus != 'all')
                    _FilterChip(
                      label: filterStatus == 'submitted'
                          ? 'Submitted'
                          : 'Not Submitted',
                      color: filterStatus == 'submitted'
                          ? Colors.green
                          : Colors.grey,
                      onRemove: () => onFilter('all'),
                    ),
                  if (searchQuery.isNotEmpty)
                    _FilterChip(
                      label: '"$searchQuery"',
                      color: hodColor,
                      onRemove: () => onSearch(''),
                    ),
                ]),
              ),
              Text('${students.length}/$totalCount',
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 12)),
            ]),
          ),

        Expanded(
          child: students.isEmpty
              ? const Center(
                  child: Text('No students found',
                      style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                  itemCount: students.length,
                  itemBuilder: (context, i) => _StudentCard(student: students[i]),
                ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onRemove;
  const _FilterChip(
      {required this.label, required this.color, required this.onRemove});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.only(left: 10, right: 4, top: 3, bottom: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(width: 2),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(20),
            child: Icon(Icons.close_rounded, size: 14, color: color),
          ),
        ]),
      );
}

// ────────────────────────────────────────────────
// STUDENT CARD
// ────────────────────────────────────────────────
class _StudentCard extends StatelessWidget {
  final Map<String, dynamic> student;
  const _StudentCard({required this.student});

  Color _statusColor(BuildContext context) {
    switch (student['form_status'] ?? '') {
      case 'approved':
        return Colors.green;
      case 'hod_review':
        return Theme.of(context).colorScheme.primary;
      case 'mentor_review':
      case 'submitted':
        return Colors.blue; 
      case 'rejected':
        return Colors.red;
      case 'draft':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String get _statusLabel {
    switch (student['form_status'] ?? '') {
      case 'approved':
        return 'Approved';
      case 'hod_review':
        return 'Pending HOD ⏳';
      case 'mentor_review':
        return 'With Mentor';
      case 'submitted':
        return 'With Mentor';
      case 'rejected':
        return 'Rejected';
      case 'draft':
        return 'Draft';
      default:
        return 'Not Submitted';
    }
  }

  bool get _hasSubmitted {
    final status = (student['form_status'] ?? '').toString();
    return status.isNotEmpty && status != 'not_submitted';
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(context);
    final hodColor = Theme.of(context).colorScheme.primary;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: student['form_id'] != null
            ? () => Navigator.pushNamed(context, '/ssmHodApproval', arguments: student['form_id'])
            : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            CircleAvatar(
              backgroundColor: _hasSubmitted
                  ? hodColor.withOpacity(0.12)
                  : Colors.grey.withOpacity(0.15),
              radius: 22,
              child: Text(
                (student['student_name'] ?? 'S')
                    .toString()
                    .substring(0, 1)
                    .toUpperCase(),
                style: TextStyle(
                    color: _hasSubmitted
                        ? hodColor
                        : Colors.grey,
                    fontWeight: FontWeight.w700,
                    fontSize: 16),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(student['student_name'] ?? '',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(student['register_number'] ?? '',
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 12)),
                  ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              if (student['grand_total'] != null)
                Text(
                  '${(student['grand_total'] as num).toStringAsFixed(0)} pts',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _hasSubmitted
                          ? hodColor
                          : Colors.grey,
                      fontSize: 14),
                ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: color.withOpacity(0.3)),
                ),
                child: Text(
                  _statusLabel,
                  style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w600),
                ),
              ),
              if (student['star_rating'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: StarRating(
                      stars: student['star_rating'] as int, size: 12),
                ),
            ]),
          ]),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────
// PENDING CARD
// ────────────────────────────────────────────────
class _HodPendingCard extends StatelessWidget {
  final Map<String, dynamic> form;
  const _HodPendingCard({required this.form});

  @override
  Widget build(BuildContext context) {
    final hodColor = Theme.of(context).colorScheme.primary;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.pushNamed(context, '/ssmHodApproval', arguments: form['form_id']),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            CircleAvatar(
                backgroundColor: hodColor,
                child: const Icon(Icons.person_rounded, color: Colors.white)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(form['student_name'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(form['register_number'] ?? '',
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 12)),
                    Text('AY ${form['academic_year']}',
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 11)),
                  ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              if (form['preview_score'] != null)
                Text(
                  '${(form['preview_score'] as num).toStringAsFixed(0)} pts',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: hodColor,
                      fontSize: 14),
                ),
              if (form['star_rating'] != null)
                StarRating(stars: form['star_rating'] as int, size: 14),
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: hodColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('Review',
                    style: TextStyle(
                        color: hodColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600)),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// HOD Approval Screen
// ════════════════════════════════════════════════════════════════

class SSMHodApprovalScreen extends StatefulWidget {
  final int formId;
  const SSMHodApprovalScreen({required this.formId, super.key});

  @override
  State<SSMHodApprovalScreen> createState() => _SSMHodApprovalScreenState();
}

class _SSMHodApprovalScreenState extends State<SSMHodApprovalScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  bool _submitting = false;
  String _hodFeedback = 'good';
  final _remarksCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final d = await ApiService.ssmGetHodFormDetails(widget.formId);
      if (mounted) setState(() { _data = d; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _decide(bool approve) async {
    setState(() => _submitting = true);
    try {
      final res = await ApiService.ssmHodApproveForm(widget.formId, {
        'hod_feedback': _hodFeedback,
        'remarks': _remarksCtrl.text.trim(),
        'approve': approve,
      });
      if (mounted) {
        final msg = approve
            ? '✓ Approved! Final score: ${res['final_score']?['grand_total']?.toStringAsFixed(0)} pts'
            : '✗ Rejected — student will be notified';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor: approve ? Colors.green : Colors.red,
        ));
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _submitting = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final cs = Theme.of(context).colorScheme;
    final student = _data?['student_name'] ?? '';
    final scores  = _data?['live_score'];
    final mentorRemarks = _data?['mentor_remarks'];

    return Scaffold(
      appBar: AppBar(title: Text('Approve: $student')),
      body: Stack(children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            // Score card
            if (scores != null) _buildScoreCard(cs, scores),
            const SizedBox(height: 16),

            // Category bars
            if (scores != null) ...[
              ..._buildCategoryBars(cs, scores),
              const SizedBox(height: 16),
            ],

            // Mentor remarks
            if (mentorRemarks != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.2)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Mentor Remarks',
                      style: TextStyle(fontWeight: FontWeight.w700,
                          color: Colors.blue, fontSize: 13)),
                  const SizedBox(height: 6),
                  Text(mentorRemarks, style: TextStyle(
                      color: cs.onSurface, fontSize: 13)),
                ]),
              ),
            const SizedBox(height: 16),

            // HOD feedback card
            Card(child: Padding(padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: const Color(0xFF6A1B9A).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.rate_review_rounded,
                        color: Color(0xFF6A1B9A), size: 18)),
                  const SizedBox(width: 10),
                  const Text('HOD Feedback', style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14)),
                ]),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _hodFeedback,
                  decoration: InputDecoration(
                    labelText: 'HOD Academic Feedback (1.5)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'average',   child: Text('Average (5 pts)')),
                    DropdownMenuItem(value: 'good',      child: Text('Good (10 pts)')),
                    DropdownMenuItem(value: 'excellent', child: Text('Excellent (15 pts)')),
                  ],
                  onChanged: (v) => setState(() => _hodFeedback = v!),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _remarksCtrl, maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'HOD remarks (visible to student and mentor)...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                  ),
                ),
              ]),
            )),
            const SizedBox(height: 24),

            Row(children: [
              Expanded(child: OutlinedButton.icon(
                onPressed: () => _decide(false),
                icon: const Icon(Icons.close_rounded, color: Colors.red),
                label: const Text('Reject', style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14)),
              )),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: ElevatedButton.icon(
                onPressed: () => _decide(true),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                icon: const Icon(Icons.lock_rounded, size: 18),
                label: const Text('Approve & Lock Score'),
              )),
            ]),
            const SizedBox(height: 32),
          ]),
        ),
        if (_submitting)
          Container(color: Colors.black26,
              child: const Center(child: CircularProgressIndicator())),
      ]),
    );
  }

  Widget _buildScoreCard(ColorScheme cs, Map scores) {
    final total = (scores['grand_total'] ?? 0) as num;
    final stars = (scores['star_rating'] ?? 0) as int;
    Color c;
    if (total >= 450) c = const Color(0xFF1B5E20);
    else if (total >= 400) c = const Color(0xFF2E7D32);
    else if (total >= 350) c = const Color(0xFF1565C0);
    else c = const Color(0xFFFF9800);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [c, c.withOpacity(0.75)],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: c.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Student Score', style: TextStyle(color: Colors.white70, fontSize: 12)),
          Text('${total.toStringAsFixed(0)} / 500',
              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800)),
        ]),
        Row(children: List.generate(5, (i) => Icon(
            i < stars ? Icons.star : Icons.star_border,
            color: Colors.white, size: 28))),
      ]),
    );
  }

  List<Widget> _buildCategoryBars(ColorScheme cs, Map scores) {
    final cats = [
      ('Academic',    scores['academic']    ?? 0, const Color(0xFF1565C0), Icons.school_rounded),
      ('Development', scores['development'] ?? 0, const Color(0xFF2E7D32), Icons.workspace_premium_rounded),
      ('Skill',       scores['skill']       ?? 0, const Color(0xFF6A1B9A), Icons.trending_up_rounded),
      ('Discipline',  scores['discipline']  ?? 0, const Color(0xFFE65100), Icons.verified_rounded),
      ('Leadership',  scores['leadership']  ?? 0, const Color(0xFFC62828), Icons.emoji_events_rounded),
    ];
    return cats.map((cat) {
      final pts = (cat.$2 as num).toDouble();
      final color = cat.$3;
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surface, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              Icon(cat.$4, color: color, size: 16),
              const SizedBox(width: 8),
              Text(cat.$1, style: TextStyle(
                  color: cs.onSurface, fontWeight: FontWeight.w600, fontSize: 13)),
            ]),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: Text('${pts.toInt()} / 100', style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ]),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: pts / 100,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 5, borderRadius: BorderRadius.circular(3),
          ),
        ]),
      );
    }).toList();
  }
}

// ════════════════════════════════════════════════════════════════
// HOD Report Screen
// ════════════════════════════════════════════════════════════════

class SSMHodReportScreen extends StatefulWidget {
  const SSMHodReportScreen({super.key});

  @override
  State<SSMHodReportScreen> createState() => _SSMHodReportScreenState();
}

class _SSMHodReportScreenState extends State<SSMHodReportScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      // Academic year hardcoded or from session if available
      final d = await ApiService.ssmGetDeptReport("2025-26");
      setState(() {
        _data = d;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  // ── CSV EXPORT ────────────────────────────────────────────────────────────
  Future<void> _exportCsv() async {
    final students = (_data?['students'] as List?) ?? [];
    if (students.isEmpty) return;

    setState(() => _exporting = true);
    try {
      final sb = StringBuffer();
      // Header
      sb.writeln(
          'Rank,Name,Register Number,Grand Total,Star Rating,Status,Academic Year');
      for (int i = 0; i < students.length; i++) {
        final s = students[i];
        sb.writeln([
          i + 1,
          '"${s['student_name'] ?? ''}"',
          s['register_number'] ?? '',
          s['grand_total']?.toStringAsFixed(2) ?? '0',
          s['star_rating'] ?? '0',
          s['status'] ?? '',
          s['academic_year'] ?? "2025-26",
        ].join(','));
      }

      final dir = await getTemporaryDirectory();
      final file =
          File('${dir.path}/dept_report_2025-26.csv');
      await file.writeAsString(sb.toString());

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Department SSM Report 2025-26',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.red));
    } finally {
      setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final students = (_data?['students'] as List?) ?? [];
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Department Report',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        actions: [
          if (!_loading && students.isNotEmpty)
            IconButton(
              icon: _exporting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.download_rounded),
              tooltip: 'Export CSV',
              onPressed: _exporting ? null : _exportCsv,
            ),
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                // ── Summary row ───────────────────────────────────────────
                Row(children: [
                  Expanded(
                      child: _StatCard(
                          'Total',
                          _data?['total_forms']?.toString() ?? '0',
                          cs.primary)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _StatCard(
                          'Approved',
                          _data?['approved']?.toString() ?? '0',
                          Colors.green)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _StatCard(
                          '⭐×5',
                          _data?['five_star']?.toString() ?? '0',
                          Colors.amber)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _StatCard(
                          'Avg',
                          (_data?['average_score'] ?? 0).toStringAsFixed(1),
                          Colors.blue)),
                ]),
                const SizedBox(height: 20),

                // ── Student list ──────────────────────────────────────────
                if (students.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: Text('No approved forms yet.',
                        style: TextStyle(color: Colors.grey)),
                  )
                else
                  ...students.asMap().entries.map((entry) {
                    final i = entry.key;
                    final s = entry.value;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              _rankColor(i + 1).withOpacity(0.15),
                          child: Text('${i + 1}',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: _rankColor(i + 1))),
                        ),
                        title: Text(s['student_name'] ?? '',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: Text(s['register_number'] ?? '',
                            style: const TextStyle(fontSize: 12)),
                        trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                (s['grand_total'] ?? 0).toStringAsFixed(0),
                                style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                    color: cs.primary),
                              ),
                              StarRating(
                                  stars: s['star_rating'] ?? 0, size: 13),
                            ]),
                      ),
                    );
                  }),
              ]),
            ),
    );
  }

  Color _rankColor(int rank) => switch (rank) {
        1 => const Color(0xFFFFD700),
        2 => const Color(0xFFC0C0C0),
        3 => const Color(0xFFCD7F32),
        _ => Colors.blue,
      };
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatCard(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(children: [
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 18, color: color)),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: Colors.grey)),
        ]),
      );
}


// Shared widgets (StarRating) from main/other files
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
