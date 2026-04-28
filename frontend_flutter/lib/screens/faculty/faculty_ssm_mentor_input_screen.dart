// File: lib/screens/faculty/faculty_ssm_mentor_input_screen.dart
import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class FacultySSMMentorInputScreen extends StatefulWidget {
  final int studentId;
  final String studentName;
  final String registerNumber;
  final Map<String, dynamic>? existingInput;

  const FacultySSMMentorInputScreen({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.registerNumber,
    this.existingInput,
  });

  @override
  State<FacultySSMMentorInputScreen> createState() =>
      _FacultySSMMentorInputScreenState();
}

class _FacultySSMMentorInputScreenState
    extends State<FacultySSMMentorInputScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  bool _isSaving = false;

  String? _mentorFeedback;
  String? _hodFeedback;
  String? _techSkillLevel;
  String? _softSkillLevel;
  String? _placementOutcome;
  String? _disciplineConduct;
  String? _punctualityLevel;
  String? _dressCode;
  String? _deptEventContribution;
  String? _socialMediaLevel;
  int _mentorScore = 0;

  static const _cat1Color = Color(0xFF1565C0);
  static const _cat3Color = Color(0xFF6A1B9A);
  static const _cat4Color = Color(0xFFE65100);

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _tab.addListener(() {
      if (!_tab.indexIsChanging) setState(() {});
    });
    final e = widget.existingInput ?? {};
    _mentorFeedback        = e['mentor_feedback'];
    _hodFeedback           = e['hod_feedback'];
    _techSkillLevel        = e['tech_skill_level'];
    _softSkillLevel        = e['soft_skill_level'];
    _placementOutcome      = e['placement_outcome'];
    _disciplineConduct     = e['discipline_conduct'];
    _punctualityLevel      = e['punctuality_level'];
    _dressCode             = e['dress_code'];
    _deptEventContribution = e['dept_event_contribution'];
    _socialMediaLevel      = e['social_media_level'];
    _calcScore();
  }

  void _calcScore() {
    int s = 0;
    s += _mentorFeedback == 'Excellent' ? 15
       : _mentorFeedback == 'Good'      ? 10
       : _mentorFeedback == 'Average'   ?  5 : 0;
    s += _hodFeedback == 'Excellent' ? 15
       : _hodFeedback == 'Good'      ? 10
       : _hodFeedback == 'Average'   ?  5 : 0;
    s += _techSkillLevel == 'Excellent' ? 20
       : _techSkillLevel == 'Good'      ? 10
       : _techSkillLevel == 'Basic'     ?  5 : 0;
    s += _softSkillLevel == 'Excellent' ? 20
       : _softSkillLevel == 'Good'      ? 10
       : _softSkillLevel == 'Average'   ?  5 : 0;
    s += _placementOutcome == '15+LPA'     ? 20
       : _placementOutcome == '10-14LPA'   ? 15
       : _placementOutcome == '7.5-9.9LPA' ? 10
       : _placementOutcome == '<7.5LPA'    ?  5 : 0;
    s += _disciplineConduct == 'Exemplary'    ? 20
       : _disciplineConduct == 'Minor Issues' ? 10 : 0;
    s += _punctualityLevel == 'ge95NoLate' ? 15
       : _punctualityLevel == '90-94'      ? 10
       : _punctualityLevel == '85-89'      ?  5 : 0;
    s += _dressCode == '100% Adherence' ? 15
       : _dressCode == 'Highly Regular'  ? 10
       : _dressCode == 'General'         ?  5 : 0;
    s += _deptEventContribution == 'Impactful' ? 25
       : _deptEventContribution == 'Useful'    ? 15
       : _deptEventContribution == 'Minor'     ?  5 : 0;
    s += _socialMediaLevel == 'ActiveCreator' ? 25
       : _socialMediaLevel == 'Regular'       ? 20
       : _socialMediaLevel == 'Shares'        ? 15
       : _socialMediaLevel == 'Occasional'    ? 10
       : _socialMediaLevel == 'Minimal'       ?  5 : 0;
    setState(() => _mentorScore = s);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await ApiService.ssmSaveMentorInput(
        studentId:             widget.studentId,
        mentorFeedback:        _mentorFeedback,
        hodFeedback:           _hodFeedback,
        techSkillLevel:        _techSkillLevel,
        softSkillLevel:        _softSkillLevel,
        placementOutcome:      _placementOutcome,
        disciplineConduct:     _disciplineConduct,
        punctualityLevel:      _punctualityLevel,
        dressCode:             _dressCode,
        deptEventContribution: _deptEventContribution,
        socialMediaLevel:      _socialMediaLevel,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✓ Mentor evaluation saved!'),
          backgroundColor: Color(0xFF2E7D32),
        ));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Mentor Evaluation', style: TextStyle(fontSize: 16)),
          Text(
            '${widget.studentName} · ${widget.registerNumber}',
            style: TextStyle(fontSize: 11, color: cs.onSurface.withOpacity(0.6)),
          ),
        ]),
        actions: [
          if (_mentorScore > 0)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text('+$_mentorScore pts',
                      style: TextStyle(color: cs.primary,
                          fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tab,
          tabs: [
            _mkTab('1. Academic', _cat1Color),
            _mkTab('3. Skills', _cat3Color),
            _mkTab('4. Discipline', _cat4Color),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [_buildCat1(cs), _buildCat3(cs), _buildCat4(cs)],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _isSaving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Save Evaluation',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ),
      ),
    );
  }

  Tab _mkTab(String label, Color color) => Tab(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 11)),
    ),
  );

  // ── Category 1 ─────────────────────────────────────────────
  Widget _buildCat1(ColorScheme cs) {
    return _scroll([
      _info(cs, 'Evaluate academic consistency, participation, responsiveness to guidance, and improvement efforts.'),
      _dd(cs, '1.4  Mentor Feedback (your evaluation)', _mentorFeedback,
          ['Excellent', 'Good', 'Average'], {
            'Excellent': 'Excellent — Outstanding academic behaviour',
            'Good':      'Good — Consistent participation',
            'Average':   'Average — Needs improvement',
          }, (v) { setState(() { _mentorFeedback = v; _calcScore(); }); }),
      _dd(cs, '1.5  HoD Feedback', _hodFeedback,
          ['Excellent', 'Good', 'Average'], {
            'Excellent': 'Excellent — Top academic standing',
            'Good':      'Good — Meeting expectations',
            'Average':   'Average — Requires attention',
          }, (v) { setState(() { _hodFeedback = v; _calcScore(); }); }),
    ]);
  }

  // ── Category 3 ─────────────────────────────────────────────
  Widget _buildCat3(ColorScheme cs) {
    return _scroll([
      _info(cs, 'Evaluate based on lab performance, coding ability, communication skills, and placement outcome.'),
      _dd(cs, '3.1  Technical Skill Competency', _techSkillLevel,
          ['Excellent', 'Good', 'Basic'], {
            'Excellent': 'Excellent — Independent problem solving, strong skills',
            'Good':      'Good — Can apply concepts with guidance',
            'Basic':     'Basic — Limited application ability',
          }, (v) { setState(() { _techSkillLevel = v; _calcScore(); }); }),
      _dd(cs, '3.2  Soft Skills & Communication', _softSkillLevel,
          ['Excellent', 'Good', 'Average'], {
            'Excellent': 'Excellent — Strong presentation & communication',
            'Good':      'Good — Communicates effectively',
            'Average':   'Average — Needs improvement',
          }, (v) { setState(() { _softSkillLevel = v; _calcScore(); }); }),
      _dd(cs, '3.4  Placement Outcome / Career', _placementOutcome,
          ['15+LPA', '10-14LPA', '7.5-9.9LPA', '<7.5LPA'], {
            '15+LPA':      '≥15 LPA (or GATE / Top University)',
            '10-14LPA':    '10–14.9 LPA',
            '7.5-9.9LPA':  '7.5–9.9 LPA',
            '<7.5LPA':     '<7.5 LPA / Internship offer',
          }, (v) { setState(() { _placementOutcome = v; _calcScore(); }); }),
    ]);
  }

  // ── Category 4 ─────────────────────────────────────────────
  Widget _buildCat4(ColorScheme cs) {
    return _scroll([
      _info(cs, 'Evaluate using ERP records, discipline committee records, and direct observation.'),
      _dd(cs, '4.1  Discipline & Code of Conduct', _disciplineConduct,
          ['Exemplary', 'Minor Issues', 'Issues'], {
            'Exemplary':    'No violations — exemplary conduct throughout',
            'Minor Issues': 'Minor issues only',
            'Issues':       'Disciplinary action taken',
          }, (v) { setState(() { _disciplineConduct = v; _calcScore(); }); }),
      _dd(cs, '4.2  Attendance & Punctuality', _punctualityLevel,
          ['ge95NoLate', '90-94', '85-89'], {
            'ge95NoLate': '≥95% + No late entries',
            '90-94':      '90–94% + Minimal late',
            '85-89':      '85–89%',
          }, (v) { setState(() { _punctualityLevel = v; _calcScore(); }); }),
      _dd(cs, '4.3  Dress Code & Professional Appearance', _dressCode,
          ['100% Adherence', 'Highly Regular', 'General'], {
            '100% Adherence': '100% Consistent throughout semester',
            'Highly Regular': 'Highly regular with minor deviations',
            'General':        'Generally follows dress code',
          }, (v) { setState(() { _dressCode = v; _calcScore(); }); }),
      _dd(cs, '4.4  Contribution to Department Events', _deptEventContribution,
          ['Impactful', 'Useful', 'Minor', 'None'], {
            'Impactful': 'Implemented impactful initiative (25 pts)',
            'Useful':    'Proposed useful idea (15 pts)',
            'Minor':     'Minor idea only (5 pts)',
            'None':      'No contribution (0 pts)',
          }, (v) {
            setState(() {
              _deptEventContribution = (v == 'None') ? null : v;
              _calcScore();
            });
          }),
      _dd(cs, '4.5  Social Media & Promotional Activities', _socialMediaLevel,
          ['ActiveCreator', 'Regular', 'Shares', 'Occasional', 'Minimal', 'None'], {
            'ActiveCreator': 'Actively creates quality content (25 pts)',
            'Regular':       'Regularly contributes (20 pts)',
            'Shares':        'Participates and shares (15 pts)',
            'Occasional':    'Occasional contribution (10 pts)',
            'Minimal':       'Minimal / Class group only (5 pts)',
            'None':          'No activity (0 pts)',
          }, (v) {
            setState(() {
              _socialMediaLevel = (v == 'None') ? null : v;
              _calcScore();
            });
          }),
    ]);
  }

  // ── Shared widgets ──────────────────────────────────────────

  Widget _scroll(List<Widget> children) => ListView(
    padding: const EdgeInsets.all(16),
    children: [...children, const SizedBox(height: 20)],
  );

  Widget _info(ColorScheme cs, String text) => Container(
    padding: const EdgeInsets.all(12),
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: cs.primary.withOpacity(0.06),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: cs.primary.withOpacity(0.15)),
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(Icons.info_outline, color: cs.primary, size: 16),
      const SizedBox(width: 8),
      Expanded(
        child: Text(text, style: TextStyle(
            color: cs.onBackground.withOpacity(0.65), fontSize: 12)),
      ),
    ]),
  );

  Widget _dd(
    ColorScheme cs,
    String label,
    String? value,
    List<String> opts,
    Map<String, String> labels,
    ValueChanged<String?> onChanged,
  ) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
        ),
        items: opts.map((o) => DropdownMenuItem(
          value: o,
          child: Text(labels[o] ?? o,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13)),
        )).toList(),
        onChanged: onChanged,
      ),
    );
}
