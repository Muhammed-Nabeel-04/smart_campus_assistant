// File: lib/screens/student/ssm_add_activity_screen.dart
// Ported from standalone SSM app — adapted for campus app (no go_router)

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/api_service.dart';

class SSMAddActivityScreen extends StatefulWidget {
  const SSMAddActivityScreen({super.key});

  @override
  State<SSMAddActivityScreen> createState() => _SSMAddActivityScreenState();
}

class _SSMAddActivityScreenState extends State<SSMAddActivityScreen> {
  int _step = 0;
  String? _category;
  String? _activityType;
  File? _pickedFile;
  bool _submitting = false;
  String? _resultMessage;
  bool _success = false;

  final _c = <String, TextEditingController>{};
  final Map<String, String?> _dropdowns = {};

  TextEditingController _ctrl(String key) =>
      _c.putIfAbsent(key, () => TextEditingController());

  @override
  void dispose() { for (final c in _c.values) c.dispose(); super.dispose(); }

  // ── Category colors ───────────────────────────────────────────────────────
  static const _catColors = {
    'academic':    Color(0xFF1565C0),
    'development': Color(0xFF2E7D32),
    'skill':       Color(0xFF6A1B9A),
    'leadership':  Color(0xFFC62828),
  };

  static const _categories = [
    {'id': 'academic',    'label': 'Academic',       'icon': Icons.school_rounded,          'subtitle': 'GPA, attendance, project'},
    {'id': 'development', 'label': 'Student Dev',    'icon': Icons.workspace_premium_rounded,'subtitle': 'NPTEL, internship, competitions'},
    {'id': 'skill',       'label': 'Skill & Career', 'icon': Icons.trending_up_rounded,     'subtitle': 'Placement, higher studies, research'},
    {'id': 'leadership',  'label': 'Leadership',     'icon': Icons.emoji_events_rounded,    'subtitle': 'Roles, events, community service'},
  ];

  static const _typesByCategory = <String, List<Map<String, dynamic>>>{
    'academic': [
      {'id': 'gpa_update', 'label': 'Update GPA / Attendance',    'icon': Icons.assessment_rounded,        'requiresDoc': false, 'desc': 'Update your internal GPA, university GPA, attendance %'},
      {'id': 'project',    'label': 'Project / Beyond Curriculum', 'icon': Icons.code_rounded,              'requiresDoc': true,  'desc': 'Submit your project completion proof'},
    ],
    'development': [
      {'id': 'nptel',        'label': 'NPTEL / SWAYAM Cert',       'icon': Icons.workspace_premium_rounded, 'requiresDoc': true,  'desc': 'Upload your NPTEL or SWAYAM completion certificate'},
      {'id': 'online_cert',  'label': 'Online Course Certificate', 'icon': Icons.laptop_rounded,            'requiresDoc': true,  'desc': 'Coursera, Udemy, LinkedIn Learning etc.'},
      {'id': 'internship',   'label': 'Internship / In-plant',     'icon': Icons.work_outline_rounded,      'requiresDoc': true,  'desc': 'Internship offer / completion letter'},
      {'id': 'competition',  'label': 'Competition / Hackathon',   'icon': Icons.emoji_events_rounded,      'requiresDoc': true,  'desc': 'Certificate or proof of participation / winning'},
      {'id': 'publication',  'label': 'Publication / Patent',      'icon': Icons.article_rounded,           'requiresDoc': true,  'desc': 'Journal paper, conference paper, patent'},
      {'id': 'prof_program', 'label': 'Workshop / VAP / Add-on',   'icon': Icons.event_rounded,             'requiresDoc': true,  'desc': 'Professional skill program certificate'},
    ],
    'skill': [
      {'id': 'placement',    'label': 'Placement Offer',            'icon': Icons.business_center_rounded,  'requiresDoc': true,  'desc': 'Upload your placement offer letter'},
      {'id': 'higher_study', 'label': 'Higher Studies (GATE/GRE)', 'icon': Icons.import_contacts_rounded,  'requiresDoc': true,  'desc': 'Score card or admission letter'},
      {'id': 'industry_int', 'label': 'Industry Interaction',      'icon': Icons.factory_rounded,           'requiresDoc': false, 'desc': 'Guest lecture, industry visit, workshop'},
      {'id': 'research',     'label': 'Research Paper',             'icon': Icons.biotech_rounded,           'requiresDoc': true,  'desc': 'Reviewed / published research paper'},
    ],
    'leadership': [
      {'id': 'formal_role', 'label': 'Formal Leadership Role',    'icon': Icons.star_rounded,              'requiresDoc': true,  'desc': 'CR, club president, dept coordinator etc.'},
      {'id': 'event_org',   'label': 'Event Organization',        'icon': Icons.celebration_rounded,       'requiresDoc': true,  'desc': 'Organized / led a college or external event'},
      {'id': 'community',   'label': 'Community / Social Service','icon': Icons.group_rounded,             'requiresDoc': true,  'desc': 'NSS, NCC, social service with proof'},
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_stepTitle(), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _step == 0 ? () => Navigator.pop(context) : _goBack,
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _step == 0 ? _buildCategoryStep()
             : _step == 1 ? _buildTypeStep()
             : _buildDetailsStep(),
      ),
    );
  }

  String _stepTitle() => switch (_step) {
    0 => 'What did you do?',
    1 => _catLabel(_category!),
    _ => _typeInfo(_activityType!)['label'] as String,
  };

  void _goBack() => setState(() {
    if (_step == 2) { _step = 1; _resultMessage = null; _success = false; }
    else if (_step == 1) { _step = 0; _activityType = null; }
  });

  // ── Step 0: Category ───────────────────────────────────────────────────────
  Widget _buildCategoryStep() {
    return GridView.count(
      key: const ValueKey('cat'),
      crossAxisCount: 2,
      padding: const EdgeInsets.all(16),
      mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.15,
      children: _categories.map((cat) {
        final color = _catColors[cat['id']]!;
        return GestureDetector(
          onTap: () => setState(() { _category = cat['id'] as String; _step = 1; }),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.2)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(cat['icon'] as IconData, color: color, size: 24),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(cat['label'] as String,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 2),
                Text(cat['subtitle'] as String,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
              ]),
            ]),
          ),
        );
      }).toList(),
    );
  }

  // ── Step 1: Type ───────────────────────────────────────────────────────────
  Widget _buildTypeStep() {
    final color = _catColors[_category!]!;
    final types = _typesByCategory[_category!] ?? [];
    return ListView(
      key: const ValueKey('type'),
      padding: const EdgeInsets.all(16),
      children: types.map((t) {
        final needsDoc = t['requiresDoc'] as bool;
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: color.withOpacity(0.15)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(t['icon'] as IconData, color: color, size: 22),
            ),
            title: Text(t['label'] as String,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(t['desc'] as String,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              if (needsDoc)
                Padding(padding: const EdgeInsets.only(right: 6),
                  child: Icon(Icons.attach_file_rounded, size: 14, color: Colors.grey.shade500)),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
            ]),
            onTap: () => setState(() {
              _activityType = t['id'] as String;
              _dropdowns.clear(); _step = 2;
            }),
          ),
        );
      }).toList(),
    );
  }

  // ── Step 2: Details ────────────────────────────────────────────────────────
  Widget _buildDetailsStep() {
    final tInfo = _typeInfo(_activityType!);
    final needsDoc = tInfo['requiresDoc'] as bool;
    final color = _catColors[_category!]!;

    return SingleChildScrollView(
      key: const ValueKey('details'),
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            Icon(tInfo['icon'] as IconData, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(tInfo['desc'] as String,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700))),
          ]),
        ),
        const SizedBox(height: 20),

        ..._buildFields(_activityType!),

        if (needsDoc) ...[
          const SizedBox(height: 16),
          const Text('Supporting Document',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickFile,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _pickedFile != null ? Colors.green : Colors.grey.shade300,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
                color: _pickedFile != null ? Colors.green.withOpacity(0.05) : null,
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(
                  _pickedFile != null ? Icons.check_circle_rounded : Icons.upload_file_rounded,
                  color: _pickedFile != null ? Colors.green : Colors.grey,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(
                  _pickedFile != null ? _pickedFile!.path.split('/').last
                      : 'Tap to pick PDF, JPG or PNG',
                  style: TextStyle(
                      color: _pickedFile != null ? Colors.green : Colors.grey,
                      fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                )),
              ]),
            ),
          ),
          const SizedBox(height: 4),
          const Text('PDF, JPG or PNG • Max 5 MB',
              style: TextStyle(color: Colors.grey, fontSize: 11)),
        ],

        const SizedBox(height: 24),

        if (_resultMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (_success ? Colors.green : Colors.red).withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: (_success ? Colors.green : Colors.red).withOpacity(0.3)),
            ),
            child: Row(children: [
              Icon(_success ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                  color: _success ? Colors.green : Colors.red, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(_resultMessage!,
                  style: TextStyle(color: _success ? Colors.green : Colors.red,
                      fontSize: 13))),
            ]),
          ),
          const SizedBox(height: 16),
        ],

        if (!_success)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _submitting
                  ? const SizedBox(height: 18, width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Submit Activity',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),

        if (_success) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.check_circle_outline, color: Colors.green),
              label: const Text('Done — Back to Dashboard'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
        const SizedBox(height: 40),
      ]),
    );
  }

  // ── Field builders ─────────────────────────────────────────────────────────
  List<Widget> _buildFields(String type) => switch (type) {
    'gpa_update' => [
      _num('internal_gpa',   'Internal GPA (0–10)', '/10'),
      _num('university_gpa', 'University GPA (0–10)', '/10'),
      _num('attendance_pct', 'Attendance %', '%'),
      _bool('has_arrear',    'I have an active arrear'),
    ],
    'project' => [_dd('project_status', 'Project Status', [('concept','Concept / Idea (5 pts)'),('partial','Partially Completed (10 pts)'),('fully_completed','Fully Completed (15 pts)')])],
    'nptel' => [_dd('nptel_tier', 'Achievement Level', [('participated','Participated'),('completed','Completed'),('elite','Elite'),('elite_plus','Elite + Gold/Silver/Top 5%')])],
    'online_cert' => [_text('platform_name','Platform (e.g. Coursera, Udemy)'), _text('course_name','Course Name')],
    'internship' => [_text('internship_company','Company / Organisation Name'), _dd('internship_duration','Duration',[('participation','Participation only'),('1to2weeks','1–2 Weeks + Report (10 pts)'),('2to4weeks','2–4 Weeks + Report (15 pts)'),('4weeks_plus','≥ 4 Weeks + Project (20 pts)')])],
    'competition' => [_text('competition_name','Event / Competition Name'), _dd('competition_result','Your Result',[('participated','Participated (5 pts)'),('finalist','Finalist (10 pts)'),('winner','Winner / Top 3 (20 pts)')])],
    'publication' => [_text('publication_title','Title of Paper / Patent'), _dd('publication_type','Type',[('prototype','Prototype / Idea (5 pts)'),('conference','Conference / Journal Paper (10 pts)'),('patent','Patent Filed (15 pts)')])],
    'prof_program' => [_text('program_name','Program Name (Workshop / VAP / Add-on)')],
    'placement' => [_text('placement_company','Company Name'), _num('placement_lpa','Package (LPA)','LPA')],
    'higher_study' => [_text('higher_study_exam','Exam (GATE, GRE, CAT…)'), _text('higher_study_score','Score / Rank')],
    'industry_int' => [_text('industry_org','Organisation / Company Name')],
    'research' => [_text('research_title','Paper Title'), _text('research_journal','Journal / Conference Name')],
    'formal_role' => [_text('role_name','Role Title (e.g. Class Representative)'), _dd('role_level','Level',[('class_level','Class Level (5 pts)'),('dept_level','Department Level (10 pts)'),('college_level','College Level (15 pts)')])],
    'event_org' => [_text('event_name','Event Name'), _dd('event_level','Scope',[('dept','Department Event'),('college','College Event'),('inter_college','Inter-College Event'),('national','National / External Event')])],
    'community' => [_text('community_org','Organisation (NSS, NCC, NGO…)'), _dd('community_level','Level',[('local','Local (5 pts)'),('district','District Level'),('state','State Level (15 pts)'),('national','National (25 pts)')])],
    _ => [],
  };

  Widget _text(String key, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(controller: _ctrl(key),
        decoration: InputDecoration(labelText: label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true)),
  );

  Widget _num(String key, String label, String suffix) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(controller: _ctrl(key),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label, suffixText: suffix,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true)),
  );

  Widget _dd(String key, String label, List<(String, String)> opts) {
    _dropdowns.putIfAbsent(key, () => null);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        value: _dropdowns[key],
        isExpanded: true,
        decoration: InputDecoration(labelText: label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true),
        items: opts.map((o) => DropdownMenuItem(value: o.$1, child: Text(o.$2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13)))).toList(),
        onChanged: (v) => setState(() => _dropdowns[key] = v),
      ),
    );
  }

  Widget _bool(String key, String label) {
    _dropdowns.putIfAbsent(key, () => 'false');
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(children: [
        Checkbox(
          value: _dropdowns[key] == 'true',
          onChanged: (v) => setState(() => _dropdowns[key] = (v ?? false).toString()),
        ),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
      ]),
    );
  }

  Map<String, dynamic> _typeInfo(String id) {
    for (final types in _typesByCategory.values) {
      for (final t in types) {
        if (t['id'] == id) return t;
      }
    }
    return {'label': id, 'icon': Icons.task_rounded, 'requiresDoc': false, 'desc': ''};
  }

  String _catLabel(String id) =>
      (_categories.firstWhere((c) => c['id'] == id, orElse: () => {'label': id})['label'] as String);

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom, allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png']);
    if (result?.files.single.path != null) {
      setState(() => _pickedFile = File(result!.files.single.path!));
    }
  }

  Future<void> _submit() async {
    final tInfo = _typeInfo(_activityType!);
    final needsDoc = tInfo['requiresDoc'] as bool;

    if (needsDoc && _pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please upload a supporting document')));
      return;
    }

    setState(() { _submitting = true; _resultMessage = null; });

    try {
      final fields = <String, String>{
        'category': _category!, 'activity_type': _activityType!,
      };
      for (final e in _c.entries) {
        if (e.value.text.trim().isNotEmpty) fields[e.key] = e.value.text.trim();
      }
      for (final e in _dropdowns.entries) {
        if (e.value != null) fields[e.key] = e.value!;
      }

      final res = await ApiService.ssmSubmitActivity(fields: fields, file: _pickedFile);
      final ocrStatus = res['ocr_status'] as String? ?? '';

      setState(() {
        _submitting = false;
        _success = ocrStatus != 'failed';
        _resultMessage = res['message'] as String? ?? 'Submitted';
        if (_success) _pickedFile = null;
      });
    } catch (e) {
      setState(() {
        _submitting = false;
        _success = false;
        _resultMessage = e.toString();
      });
    }
  }
}
