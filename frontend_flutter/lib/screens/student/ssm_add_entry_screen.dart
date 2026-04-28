// File: lib/screens/student/ssm_add_entry_screen.dart
// ─────────────────────────────────────────────────────────────────────────────
// Student picks what they want to add → fills details → uploads proof
// This replaces the old 29-field form
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';
import '../../core/session.dart';
import 'ssm_upload_proof_screen.dart';

class SSMAddEntryScreen extends StatefulWidget {
  final int submissionId;
  final Map<String, dynamic>? existingEntry; // for editing

  const SSMAddEntryScreen({
    super.key,
    required this.submissionId,
    this.existingEntry,
  });

  @override
  State<SSMAddEntryScreen> createState() => _SSMAddEntryScreenState();
}

class _SSMAddEntryScreenState extends State<SSMAddEntryScreen> {
  int? _selectedCategory;
  String? _selectedType;
  bool _isSaving = false;
  int? _savedEntryId;
  Map<String, dynamic>? _savedEntry;

  // ── Category definitions ────────────────────────────────────────────────────
  static const _categories = [
    {
      'id': 1, 'label': 'Academic Performance',
      'icon': Icons.school_outlined, 'color': Color(0xFF1565C0),
      'desc': 'GPA, attendance, projects',
    },
    {
      'id': 2, 'label': 'Student Development',
      'icon': Icons.workspace_premium_outlined, 'color': Color(0xFF2E7D32),
      'desc': 'NPTEL, internship, certifications',
    },
    {
      'id': 3, 'label': 'Skill & Readiness',
      'icon': Icons.rocket_launch_outlined, 'color': Color(0xFF6A1B9A),
      'desc': 'Placement, research, industry',
    },
    {
      'id': 5, 'label': 'Leadership',
      'icon': Icons.groups_outlined, 'color': Color(0xFFC62828),
      'desc': 'Roles, events, community',
    },
  ];

  // ── Entry types per category ─────────────────────────────────────────────────
  static const _types = {
    1: [
      {'type': 'iat_gpa',          'label': 'Internal Assessment GPA',   'icon': Icons.grade_outlined,       'proof': false},
      {'type': 'university_gpa',   'label': 'University Exam GPA',        'icon': Icons.account_balance_outlined, 'proof': false},
      {'type': 'attendance',       'label': 'Attendance %',               'icon': Icons.how_to_reg_outlined,  'proof': false},
      {'type': 'project',          'label': 'Project (Beyond Curriculum)','icon': Icons.build_outlined,       'proof': true},
      {'type': 'consistency_index','label': 'Academic Consistency Index', 'icon': Icons.trending_up_outlined, 'proof': false},
    ],
    2: [
      {'type': 'nptel',            'label': 'NPTEL / SWAYAM Certificate', 'icon': Icons.verified_outlined,    'proof': true},
      {'type': 'online_cert',      'label': 'Online Certification',       'icon': Icons.laptop_outlined,      'proof': true},
      {'type': 'internship',       'label': 'Internship / In-plant',      'icon': Icons.work_outline,         'proof': true},
      {'type': 'competition',      'label': 'Competition / Hackathon',    'icon': Icons.emoji_events_outlined, 'proof': true},
      {'type': 'publication',      'label': 'Publication / Patent',       'icon': Icons.article_outlined,     'proof': true},
      {'type': 'skill_program',    'label': 'Skill Program / Workshop',   'icon': Icons.star_outline,         'proof': true},
    ],
    3: [
      {'type': 'placement_readiness', 'label': 'Placement Readiness %', 'icon': Icons.business_center_outlined, 'proof': false},
      {'type': 'industry_interaction','label': 'Industry Interaction',   'icon': Icons.factory_outlined,     'proof': false},
      {'type': 'research_paper',      'label': 'Research Paper Read',    'icon': Icons.menu_book_outlined,   'proof': false},
      {'type': 'innovation',          'label': 'Innovation / Idea',      'icon': Icons.lightbulb_outline,    'proof': false},
    ],
    5: [
      {'type': 'leadership_role',       'label': 'Formal Leadership Role',  'icon': Icons.manage_accounts_outlined, 'proof': false},
      {'type': 'event_leadership',      'label': 'Event Led / Coordinated', 'icon': Icons.flag_outlined,        'proof': false},
      {'type': 'team_management',       'label': 'Team Management',         'icon': Icons.people_outline,       'proof': false},
      {'type': 'innovation_initiative', 'label': 'Innovation Initiative',   'icon': Icons.rocket_launch_outlined,'proof': false},
      {'type': 'community_leadership',  'label': 'Community Leadership',    'icon': Icons.volunteer_activism_outlined, 'proof': false},
    ],
  };

  Color get _catColor {
    final cat = _categories.firstWhere(
        (c) => c['id'] == _selectedCategory,
        orElse: () => _categories[0]);
    return cat['color'] as Color;
  }

  @override
  void initState() {
    super.initState();
    // If editing, prefill
    if (widget.existingEntry != null) {
      final e = widget.existingEntry!;
      _savedEntryId = e['id'] as int?;
      _savedEntry = e;
      final cfg = _types.entries
          .expand((cat) => (cat.value as List).map((t) => {...t as Map, 'catId': cat.key}))
          .firstWhere((t) => t['type'] == e['entry_type'], orElse: () => {});
      if (cfg.isNotEmpty) {
        _selectedCategory = cfg['catId'] as int?;
        _selectedType = e['entry_type'] as String?;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEditing = widget.existingEntry != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Entry' : 'Add Activity'),
        centerTitle: false,
      ),
      body: _selectedCategory == null
          ? _buildCategoryPicker(cs)
          : _selectedType == null
              ? _buildTypePicker(cs)
              : _buildDetailsForm(cs),
    );
  }

  // ── Step 1: Pick Category ──────────────────────────────────────────────────
  Widget _buildCategoryPicker(ColorScheme cs) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('What would you like to add?',
            style: TextStyle(color: cs.onBackground,
                fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text('Select a category',
            style: TextStyle(color: cs.onBackground.withOpacity(0.5))),
        const SizedBox(height: 24),

        ..._categories.map((cat) {
          final color = cat['color'] as Color;
          final icon = cat['icon'] as IconData;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat['id'] as int),
            child: Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: color.withOpacity(0.25)),
                boxShadow: [BoxShadow(
                    color: cs.shadow.withOpacity(0.05),
                    blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cat['label'] as String,
                        style: TextStyle(color: cs.onSurface,
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 3),
                    Text(cat['desc'] as String,
                        style: TextStyle(
                            color: cs.onSurface.withOpacity(0.5),
                            fontSize: 13)),
                  ],
                )),
                Icon(Icons.arrow_forward_ios,
                    color: color.withOpacity(0.5), size: 16),
              ]),
            ),
          );
        }),
      ],
    );
  }

  // ── Step 2: Pick Type ──────────────────────────────────────────────────────
  Widget _buildTypePicker(ColorScheme cs) {
    final types = _types[_selectedCategory] ?? [];
    final color = _catColor;

    return Column(
      children: [
        // Back header
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          color: color.withOpacity(0.07),
          child: Row(children: [
            GestureDetector(
              onTap: () => setState(() => _selectedCategory = null),
              child: Icon(Icons.arrow_back_ios, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Text(_categories.firstWhere(
                    (c) => c['id'] == _selectedCategory)['label'] as String,
                style: TextStyle(color: color,
                    fontWeight: FontWeight.bold, fontSize: 15)),
          ]),
        ),

        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('What do you have?',
                  style: TextStyle(color: cs.onBackground,
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Select the specific activity',
                  style: TextStyle(
                      color: cs.onBackground.withOpacity(0.5), fontSize: 13)),
              const SizedBox(height: 20),

              ...types.map((t) {
                final needsProof = t['proof'] as bool;
                return GestureDetector(
                  onTap: () => setState(() => _selectedType = t['type'] as String),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: color.withOpacity(0.18)),
                    ),
                    child: Row(children: [
                      Icon(t['icon'] as IconData, color: color, size: 22),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(t['label'] as String,
                            style: TextStyle(color: cs.onSurface,
                                fontWeight: FontWeight.w600, fontSize: 14)),
                      ),
                      if (needsProof)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF9800).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('Proof',
                              style: TextStyle(
                                  color: Color(0xFFFF9800),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ),
                      const SizedBox(width: 8),
                      Icon(Icons.chevron_right,
                          color: cs.onSurface.withOpacity(0.3)),
                    ]),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  // ── Step 3: Fill Details ───────────────────────────────────────────────────
  Widget _buildDetailsForm(ColorScheme cs) {
    final color = _catColor;

    return Column(
      children: [
        // Back header
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          color: color.withOpacity(0.07),
          child: Row(children: [
            GestureDetector(
              onTap: () => setState(() { _selectedType = null; _savedEntry = null; _savedEntryId = null; }),
              child: Icon(Icons.arrow_back_ios, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Text(_getTypeLabel(_selectedType!),
                style: TextStyle(color: color,
                    fontWeight: FontWeight.bold, fontSize: 15)),
          ]),
        ),

        Expanded(child: _EntryDetailForm(
          entryType: _selectedType!,
          submissionId: widget.submissionId,
          existingEntry: widget.existingEntry,
          color: color,
          onSaved: (entry, entryId) {
            setState(() {
              _savedEntry = entry;
              _savedEntryId = entryId;
            });
          },
          onDone: () => Navigator.pop(context, true),
        )),
      ],
    );
  }

  String _getTypeLabel(String type) {
    for (final cat in _types.values) {
      for (final t in cat) {
        if (t['type'] == type) return t['label'] as String;
      }
    }
    return type;
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Entry Detail Form — renders correct fields based on entry_type
// ─────────────────────────────────────────────────────────────────────────────

class _EntryDetailForm extends StatefulWidget {
  final String entryType;
  final int submissionId;
  final Map<String, dynamic>? existingEntry;
  final Color color;
  final Function(Map<String, dynamic>, int) onSaved;
  final VoidCallback onDone;

  const _EntryDetailForm({
    required this.entryType,
    required this.submissionId,
    this.existingEntry,
    required this.color,
    required this.onSaved,
    required this.onDone,
  });

  @override
  State<_EntryDetailForm> createState() => _EntryDetailFormState();
}

class _EntryDetailFormState extends State<_EntryDetailForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  bool _saved = false;
  int? _entryId;
  int? _actualSubmissionId;  // real submission ID from backend response
  Map<String, dynamic> _details = {};
  String? _proofStatus;

  // Generic controllers
  final _numCtrl   = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _orgCtrl   = TextEditingController();
  String? _ddVal1, _ddVal2;

  // Proof mapping
  static const _proofCriteria = {
    'nptel':          '2_1_nptel',
    'online_cert':    '2_2_online_cert',
    'internship':     '2_3_internship',
    'competition':    '2_4_competition',
    'publication':    '2_5_publication',
    'skill_program':  '2_6_skill_programs',
    'project':        '1_6_project',
  };

  static const _proofLabels = {
    'nptel':          'NPTEL / SWAYAM Certificate',
    'online_cert':    'Online Certification Certificate',
    'internship':     'Internship Certificate / Offer Letter',
    'competition':    'Competition Certificate / Event Proof',
    'publication':    'Publication / Patent Document',
    'skill_program':  'Skill Program Certificate',
    'project':        'Project Certificate / Report',
  };

  @override
  void initState() {
    super.initState();
    final e = widget.existingEntry;
    if (e != null) {
      _entryId = e['id'] as int?;
      _details = Map<String, dynamic>.from(e['details'] as Map? ?? {});
      _proofStatus = e['proof_status'] as String?;
      _prefillFromDetails();
    }
  }

  void _prefillFromDetails() {
    _numCtrl.text = (_details['gpa'] ?? _details['percentage'] ?? '').toString()
        .replaceAll('null', '');
    _titleCtrl.text = (_details['title'] ?? _details['course'] ??
        _details['event'] ?? _details['paper'] ?? '').toString();
    _orgCtrl.text = (_details['company'] ?? _details['platform'] ??
        _details['organization'] ?? '').toString();
    _ddVal1 = _details['level'] ?? _details['duration'] ??
        _details['result'] ?? _details['type'] ?? _details['status'];
  }

  @override
  void dispose() {
    _numCtrl.dispose();
    _titleCtrl.dispose();
    _orgCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic> get _builtDetails {
    final d = <String, dynamic>{};
    switch (widget.entryType) {
      case 'iat_gpa':
      case 'university_gpa':
        d['gpa'] = double.tryParse(_numCtrl.text) ?? 0;
        break;
      case 'attendance':
      case 'placement_readiness':
      case 'consistency_index':
        d['percentage'] = double.tryParse(_numCtrl.text) ?? 0;
        break;
      case 'project':
        d['status'] = _ddVal1;
        d['title'] = _titleCtrl.text;
        break;
      case 'nptel':
        d['level'] = _ddVal1;
        d['course'] = _titleCtrl.text;
        d['duration'] = _orgCtrl.text;
        break;
      case 'online_cert':
        d['title'] = _titleCtrl.text;
        d['platform'] = _orgCtrl.text;
        break;
      case 'internship':
        d['duration'] = _ddVal1;
        d['company'] = _orgCtrl.text;
        d['role'] = _titleCtrl.text;
        break;
      case 'competition':
        d['result'] = _ddVal1;
        d['event'] = _titleCtrl.text;
        d['organization'] = _orgCtrl.text;
        break;
      case 'publication':
        d['type'] = _ddVal1;
        d['title'] = _titleCtrl.text;
        break;
      case 'skill_program':
        d['title'] = _titleCtrl.text;
        d['organization'] = _orgCtrl.text;
        break;
      case 'innovation':
      case 'leadership_role':
      case 'team_management':
      case 'innovation_initiative':
      case 'community_leadership':
        d['level'] = _ddVal1;
        d['title'] = _titleCtrl.text;
        break;
      case 'event_leadership':
        d['title'] = _titleCtrl.text;
        d['organization'] = _orgCtrl.text;
        break;
      case 'industry_interaction':
        d['title'] = _titleCtrl.text;
        d['organization'] = _orgCtrl.text;
        break;
      case 'research_paper':
        d['paper'] = _titleCtrl.text;
        break;
    }
    return d;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      Map<String, dynamic> result;
      if (_entryId != null) {
        result = await ApiService.ssmUpdateEntry(
            entryId: _entryId!, details: _builtDetails);
      } else {
        result = await ApiService.ssmAddEntry(
          studentId: SessionManager.studentId!,
          entryType: widget.entryType,
          details: _builtDetails,
        );
        _entryId = result['entry']?['id'] as int?;
      }
      if (mounted) {
        // Get actual submission_id from response (important when first entry creates submission)
        final entryData = result['entry'] as Map<String, dynamic>? ?? {};
        _actualSubmissionId = entryData['submission_id'] as int? ?? widget.submissionId;
        setState(() { _saved = true; _isSaving = false; });
        widget.onSaved(entryData, _entryId ?? 0);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✓ Entry saved! Score: ${result['new_score']}/500'),
          backgroundColor: const Color(0xFF2E7D32),
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final needsProof = _proofCriteria.containsKey(widget.entryType);
    final proofLabel = _proofLabels[widget.entryType] ?? 'Certificate';

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Fields ───────────────────────────────────────
          ..._buildFields(cs),

          const SizedBox(height: 24),

          // ── Save button ───────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _isSaving
                  ? const SizedBox(height: 18, width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Save Entry',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),

          // ── Proof upload (after save) ─────────────────────
          if (_saved && needsProof && _entryId != null) ...[
            const SizedBox(height: 16),
            _buildProofRow(cs, proofLabel),
          ],

          // ── Done button ───────────────────────────────────
          if (_saved) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: widget.onDone,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Done — Go Back'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  List<Widget> _buildFields(ColorScheme cs) {
    switch (widget.entryType) {
      case 'iat_gpa':
        return [
          _numField('Internal Assessment GPA', 'Average of IAT I, II & Model Exam', '0–10'),
        ];
      case 'university_gpa':
        return [
          _numField('University Exam GPA', 'End semester GPA/CGPA', '0–10'),
        ];
      case 'attendance':
        return [
          _numField('Attendance %', '≥95%→15pts | ≥90%→10pts | ≥85%→5pts', '0–100'),
        ];
      case 'consistency_index':
        return [
          _numField('Consistency Index %', 'Internal vs University marks match', '0–100'),
        ];
      case 'placement_readiness':
        return [
          _numField('Placement Readiness %', 'Aptitude/coding/mock interview attendance', '0–100'),
        ];
      case 'project':
        return [
          _ddField('Project Status', ['Fully Completed', 'Partial', 'Concept'], (v) {
            setState(() => _ddVal1 = v);
          }),
          _textField('Project Title', 'e.g. Smart Campus Assistant', _titleCtrl, Icons.build_outlined),
        ];
      case 'nptel':
        return [
          _ddField('Certificate Level', ['Elite+Silver', 'Elite+Gold', 'Top5%', 'Elite', 'Completed', 'Participated'],
              (v) => setState(() => _ddVal1 = v),
              labels: {'Elite+Silver': 'Elite + Silver / Top 5%', 'Elite+Gold': 'Elite + Gold',
                       'Top5%': 'Top 5%', 'Elite': 'Elite Certificate',
                       'Completed': 'Successfully Completed', 'Participated': 'Participated (No Cert)'}),
          _textField('Course Name', 'e.g. Python for Data Science', _titleCtrl, Icons.menu_book_outlined),
          _textField('Duration', 'e.g. 8 weeks, Jan–Mar 2025', _orgCtrl, Icons.schedule_outlined, required: false),
        ];
      case 'online_cert':
        return [
          _textField('Certification Title', 'e.g. Machine Learning with Python', _titleCtrl, Icons.laptop_outlined),
          _textField('Platform', 'e.g. Coursera, Udemy, LinkedIn Learning', _orgCtrl, Icons.business_outlined),
        ];
      case 'internship':
        return [
          _ddField('Duration', ['4weeks+', '2-4weeks', '1-2weeks', 'Participation'],
              (v) => setState(() => _ddVal1 = v),
              labels: {'4weeks+': '≥4 weeks + project/report', '2-4weeks': '2–4 weeks', '1-2weeks': '1–2 weeks', 'Participation': 'Participation only'}),
          _textField('Company / Organization', 'e.g. TCS, Infosys, Startup', _orgCtrl, Icons.business_outlined),
          _textField('Role', 'e.g. Software Development Intern', _titleCtrl, Icons.person_outlined, required: false),
        ];
      case 'competition':
        return [
          _ddField('Result', ['Winner', 'Finalist', 'Participation'],
              (v) => setState(() => _ddVal1 = v),
              labels: {'Winner': 'Winner / Top 3', 'Finalist': 'Finalist / Shortlisted', 'Participation': 'Participation'}),
          _textField('Event Name', 'e.g. Smart India Hackathon 2025', _titleCtrl, Icons.emoji_events_outlined),
          _textField('Organized By', 'e.g. AICTE, IEEE, College', _orgCtrl, Icons.business_outlined, required: false),
        ];
      case 'publication':
        return [
          _ddField('Type', ['Patent', 'Conference', 'Prototype'],
              (v) => setState(() => _ddVal1 = v),
              labels: {'Patent': 'Patent Filed / Product Developed', 'Conference': 'Conference / Journal Paper', 'Prototype': 'Prototype / Idea Validated'}),
          _textField('Title', 'Paper/patent/product title', _titleCtrl, Icons.article_outlined),
        ];
      case 'skill_program':
        return [
          _textField('Program Name', 'e.g. AWS Cloud Practitioner Workshop', _titleCtrl, Icons.star_outline),
          _textField('Organized By', 'e.g. Department, ISTE, Industry', _orgCtrl, Icons.business_outlined, required: false),
        ];
      case 'industry_interaction':
        return [
          _textField('Event / Talk Title', 'e.g. AI in Industry — Guest Lecture', _titleCtrl, Icons.factory_outlined),
          _textField('Organization', 'e.g. Google, IITM, Alumni', _orgCtrl, Icons.business_outlined, required: false),
        ];
      case 'research_paper':
        return [
          _textField('Paper Title', 'Title of research paper you read', _titleCtrl, Icons.menu_book_outlined),
        ];
      case 'innovation':
        return [
          _ddField('Level', ['Implemented', 'Proposed'],
              (v) => setState(() => _ddVal1 = v),
              labels: {'Implemented': 'Implemented working solution', 'Proposed': 'Proposed an idea'}),
          _textField('Idea / Solution Title', 'Brief title of your idea', _titleCtrl, Icons.lightbulb_outline),
        ];
      case 'leadership_role':
        return [
          _ddField('Level', ['College', 'Department', 'Class'],
              (v) => setState(() => _ddVal1 = v),
              labels: {'College': 'College level (CR, Club President)', 'Department': 'Department level', 'Class': 'Class level'}),
          _textField('Role Title', 'e.g. Class Representative, Club Secretary', _titleCtrl, Icons.manage_accounts_outlined),
        ];
      case 'event_leadership':
        return [
          _textField('Event Name', 'e.g. Technical Symposium 2025', _titleCtrl, Icons.flag_outlined),
          _textField('Organized By / For', 'e.g. Department, IEEE, College', _orgCtrl, Icons.business_outlined, required: false),
        ];
      case 'team_management':
        return [
          _ddField('Level', ['Excellent', 'Good', 'Limited'],
              (v) => setState(() => _ddVal1 = v),
              labels: {'Excellent': 'Excellent team leader', 'Good': 'Good team player', 'Limited': 'Limited teamwork'}),
          _textField('Context', 'e.g. Project team, Event, Competition', _titleCtrl, Icons.people_outline, required: false),
        ];
      case 'innovation_initiative':
        return [
          _ddField('Level', ['Implemented', 'Proposed', 'Minor'],
              (v) => setState(() => _ddVal1 = v),
              labels: {'Implemented': 'Implemented impactful initiative', 'Proposed': 'Proposed useful idea', 'Minor': 'Minor idea'}),
          _textField('Initiative Title', 'Brief description of initiative', _titleCtrl, Icons.rocket_launch_outlined),
        ];
      case 'community_leadership':
        return [
          _ddField('Level', ['Led', 'Active', 'Minimal'],
              (v) => setState(() => _ddVal1 = v),
              labels: {'Led': 'Led community project', 'Active': 'Active participant', 'Minimal': 'Minimal involvement'}),
          _textField('Activity', 'e.g. NSS, Blood Donation Drive', _titleCtrl, Icons.volunteer_activism_outlined, required: false),
        ];
      default:
        return [
          _textField('Details', 'Enter details', _titleCtrl, Icons.info_outline),
        ];
    }
  }

  Widget _buildProofRow(ColorScheme cs, String proofLabel) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (_proofStatus) {
      case 'valid':
        statusColor = const Color(0xFF2E7D32);
        statusIcon = Icons.check_circle_outline;
        statusText = '✓ Certificate verified';
        break;
      case 'review':
        statusColor = const Color(0xFFFF9800);
        statusIcon = Icons.rate_review_outlined;
        statusText = '⚠ Certificate needs review';
        break;
      case 'invalid':
        statusColor = cs.error;
        statusIcon = Icons.cancel_outlined;
        statusText = '✗ Invalid — please re-upload';
        break;
      default:
        statusColor = cs.error;
        statusIcon = Icons.upload_file_outlined;
        statusText = 'Upload certificate (required)';
    }

    return GestureDetector(
      onTap: () async {
        final proofKey = _proofCriteria[widget.entryType]!;
        final realSubId = _actualSubmissionId ?? widget.submissionId;
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => SSMUploadProofScreen(
            submissionId: realSubId,
            criterionKey: proofKey,
            criterionLabel: proofLabel,
          )),
        );
        if (result == true) {
          // Refresh proof status
          try {
            final proofs = await ApiService.ssmGetProofs(realSubId);
            final proof = (proofs as List).firstWhere(
                (p) => p['criterion_key'] == proofKey,
                orElse: () => null);
            if (proof != null && _entryId != null) {
              await ApiService.ssmLinkProof(
                  entryId: _entryId!,
                  proofId: proof['id'] as int,
                  proofStatus: proof['verification_status'] as String);
              if (mounted) setState(() =>
                  _proofStatus = proof['verification_status'] as String?);
            }
          } catch (_) {}
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: statusColor.withOpacity(_proofStatus == null ? 0.7 : 0.3),
              width: _proofStatus == null ? 1.5 : 1),
        ),
        child: Row(children: [
          Icon(statusIcon, color: statusColor, size: 22),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(statusText, style: TextStyle(
                  color: statusColor, fontWeight: FontWeight.bold, fontSize: 13)),
              Text(proofLabel, style: TextStyle(
                  color: cs.onBackground.withOpacity(0.5), fontSize: 11)),
            ],
          )),
          Icon(Icons.arrow_forward_ios, color: statusColor, size: 14),
        ]),
      ),
    );
  }

  // ── Field builder helpers ──────────────────────────────────────────────────

  Widget _numField(String label, String helper, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: _numCtrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
        decoration: InputDecoration(
          labelText: label, helperText: helper,
          helperStyle: const TextStyle(fontSize: 11),
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
        ),
        validator: (v) {
          if (v == null || v.isEmpty) return 'Required';
          if (double.tryParse(v) == null) return 'Enter a valid number';
          return null;
        },
      ),
    );
  }

  Widget _textField(String label, String hint, TextEditingController ctrl,
      IconData icon, {bool required = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: ctrl,
        decoration: InputDecoration(
          labelText: label, hintText: hint,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
        ),
        validator: required
            ? (v) => (v == null || v.isEmpty) ? 'Required' : null
            : null,
      ),
    );
  }

  Widget _ddField(String label, List<String> opts, ValueChanged<String?> onChanged,
      {Map<String, String>? labels}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: _ddVal1,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
        ),
        items: opts.map((o) => DropdownMenuItem(
          value: o,
          child: Text(labels?[o] ?? o,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13)),
        )).toList(),
        onChanged: onChanged,
        validator: (v) => v == null ? 'Please select an option' : null,
      ),
    );
  }
}
