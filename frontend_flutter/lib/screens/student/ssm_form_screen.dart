// File: lib/screens/student/ssm_form_screen.dart  (REPLACE old version)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/session.dart';
import '../../services/api_service.dart';

class SSMFormScreen extends StatefulWidget {
  final Map<String, dynamic>? existingFormData;
  const SSMFormScreen({super.key, this.existingFormData});

  @override
  State<SSMFormScreen> createState() => _SSMFormScreenState();
}

class _SSMFormScreenState extends State<SSMFormScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  bool _isSaving = false;

  // Numeric fields
  final _iatCtrl = TextEditingController();
  final _uniCtrl = TextEditingController();
  final _attCtrl = TextEditingController();
  final _ciCtrl = TextEditingController();
  final _ocCtrl = TextEditingController();
  final _spCtrl = TextEditingController();
  final _prCtrl = TextEditingController();
  final _iiCtrl = TextEditingController();
  final _rpCtrl = TextEditingController();

  // Dropdown states
  String? _mentorFb,
      _hodFb,
      _projStat,
      _nptel,
      _interDur,
      _compRes,
      _pubType,
      _techSkill,
      _softSkill,
      _placOut,
      _innovLvl,
      _discCon,
      _punctLvl,
      _dressCd,
      _deptEvt,
      _socialMd,
      _leadRole,
      _evtLead,
      _teamMgmt,
      _innvInit,
      _commLead;

  int _previewTotal = 0;
  int _previewStars = 0;

  static const _catColors = [
    Color(0xFF1565C0),
    Color(0xFF2E7D32),
    Color(0xFF6A1B9A),
    Color(0xFFE65100),
    Color(0xFFC62828),
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 5, vsync: this);
    _tab.addListener(() {
      if (!_tab.indexIsChanging) setState(() {});
    });

    final d = widget.existingFormData ?? {};
    _iatCtrl.text = (d['iat_gpa'] ?? '').toString().replaceAll('null', '');
    _uniCtrl.text =
        (d['university_gpa'] ?? '').toString().replaceAll('null', '');
    _attCtrl.text =
        (d['attendance_pct'] ?? '').toString().replaceAll('null', '');
    _ciCtrl.text =
        (d['consistency_index'] ?? '').toString().replaceAll('null', '');
    _ocCtrl.text =
        (d['online_cert_count'] ?? '').toString().replaceAll('null', '');
    _spCtrl.text =
        (d['skill_programs'] ?? '').toString().replaceAll('null', '');
    _prCtrl.text =
        (d['placement_readiness'] ?? '').toString().replaceAll('null', '');
    _iiCtrl.text =
        (d['industry_interactions'] ?? '').toString().replaceAll('null', '');
    _rpCtrl.text =
        (d['research_papers'] ?? '').toString().replaceAll('null', '');

    _mentorFb = d['mentor_feedback'];
    _hodFb = d['hod_feedback'];
    _projStat = d['project_status'];
    _nptel = d['nptel_level'];
    _interDur = d['internship_duration'];
    _compRes = d['competition_result'];
    _pubType = d['publication_type'];
    _techSkill = d['tech_skill_level'];
    _softSkill = d['soft_skill_level'];
    _placOut = d['placement_outcome'];
    _innovLvl = d['innovation_level'];
    _discCon = d['discipline_conduct'];
    _punctLvl = d['punctuality_level'];
    _dressCd = d['dress_code'];
    _deptEvt = d['dept_event_contribution'];
    _socialMd = d['social_media_level'];
    _leadRole = d['leadership_role'];
    _evtLead = d['event_leadership'];
    _teamMgmt = d['team_management'];
    _innvInit = d['innovation_initiative'];
    _commLead = d['community_leadership'];

    for (final c in [
      _iatCtrl,
      _uniCtrl,
      _attCtrl,
      _ciCtrl,
      _ocCtrl,
      _spCtrl,
      _prCtrl,
      _iiCtrl,
      _rpCtrl
    ]) {
      c.addListener(_calcPreview);
    }
    _calcPreview();
  }

  void _calcPreview() {
    int total = 0;
    double iat = double.tryParse(_iatCtrl.text) ?? 0;
    double uni = double.tryParse(_uniCtrl.text) ?? 0;
    double att = double.tryParse(_attCtrl.text) ?? 0;
    double ci = double.tryParse(_ciCtrl.text) ?? 0;
    int oc = int.tryParse(_ocCtrl.text) ?? 0;
    int sp = int.tryParse(_spCtrl.text) ?? 0;
    double pr = double.tryParse(_prCtrl.text) ?? 0;
    int ii = int.tryParse(_iiCtrl.text) ?? 0;
    int rp = int.tryParse(_rpCtrl.text) ?? 0;

    // Cat 1
    int c1 = 0;
    c1 += iat >= 9
        ? 15
        : iat >= 8
            ? 10
            : iat >= 7
                ? 5
                : 0;
    c1 += uni >= 9
        ? 15
        : uni >= 8
            ? 10
            : uni >= 7
                ? 5
                : 0;
    c1 += att >= 95
        ? 15
        : att >= 90
            ? 10
            : att >= 85
                ? 5
                : 0;
    c1 += _mentorFb == 'Excellent'
        ? 15
        : _mentorFb == 'Good'
            ? 10
            : _mentorFb == 'Average'
                ? 5
                : 0;
    c1 += _hodFb == 'Excellent'
        ? 15
        : _hodFb == 'Good'
            ? 10
            : _hodFb == 'Average'
                ? 5
                : 0;
    c1 += _projStat == 'Fully Completed'
        ? 15
        : _projStat == 'Partial'
            ? 10
            : _projStat == 'Concept'
                ? 5
                : 0;
    c1 += ci >= 95
        ? 15
        : ci >= 90
            ? 10
            : ci >= 85
                ? 5
                : 0;
    total += c1.clamp(0, 100);

    // Cat 2
    int c2 = 0;
    c2 += (_nptel == 'Elite+Silver' ||
            _nptel == 'Elite+Gold' ||
            _nptel == 'Top5%')
        ? 20
        : _nptel == 'Elite'
            ? 15
            : _nptel == 'Completed'
                ? 10
                : _nptel == 'Participated'
                    ? 5
                    : 0;
    c2 += oc >= 3
        ? 15
        : oc == 2
            ? 10
            : oc >= 1
                ? 5
                : 0;
    c2 += _interDur == '4weeks+'
        ? 20
        : _interDur == '2-4weeks'
            ? 15
            : _interDur == '1-2weeks'
                ? 10
                : _interDur == 'Participation'
                    ? 5
                    : 0;
    c2 += _compRes == 'Winner'
        ? 20
        : _compRes == 'Finalist'
            ? 10
            : _compRes == 'Participation'
                ? 5
                : 0;
    c2 += _pubType == 'Patent'
        ? 15
        : _pubType == 'Conference'
            ? 10
            : _pubType == 'Prototype'
                ? 5
                : 0;
    c2 += sp >= 3
        ? 15
        : sp == 2
            ? 10
            : sp >= 1
                ? 5
                : 0;
    total += c2.clamp(0, 100);

    // Cat 3
    int c3 = 0;
    c3 += _techSkill == 'Excellent'
        ? 20
        : _techSkill == 'Good'
            ? 10
            : _techSkill == 'Basic'
                ? 5
                : 0;
    c3 += _softSkill == 'Excellent'
        ? 20
        : _softSkill == 'Good'
            ? 10
            : _softSkill == 'Average'
                ? 5
                : 0;
    c3 += pr >= 95
        ? 20
        : pr >= 80
            ? 10
            : pr >= 75
                ? 5
                : 0;
    c3 += _placOut == '15+LPA'
        ? 20
        : _placOut == '10-14LPA'
            ? 15
            : _placOut == '7.5-9.9LPA'
                ? 10
                : _placOut == '<7.5LPA'
                    ? 5
                    : 0;
    c3 += ii >= 3
        ? 20
        : ii == 2
            ? 10
            : ii >= 1
                ? 5
                : 0;
    c3 += rp >= 3
        ? 10
        : rp >= 1
            ? 5
            : 0;
    c3 += _innovLvl == 'Implemented'
        ? 10
        : _innovLvl == 'Proposed'
            ? 5
            : 0;
    total += c3.clamp(0, 100);

    // Cat 4
    int c4 = 0;
    c4 += _discCon == 'Exemplary'
        ? 20
        : _discCon == 'Minor Issues'
            ? 10
            : 0;
    c4 += _punctLvl == 'ge95NoLate'
        ? 15
        : _punctLvl == '90-94'
            ? 10
            : _punctLvl == '85-89'
                ? 5
                : 0;
    c4 += _dressCd == '100% Adherence'
        ? 15
        : _dressCd == 'Highly Regular'
            ? 10
            : _dressCd == 'General'
                ? 5
                : 0;
    c4 += _deptEvt == 'Impactful'
        ? 25
        : _deptEvt == 'Useful'
            ? 15
            : _deptEvt == 'Minor'
                ? 5
                : 0;
    c4 += _socialMd == 'ActiveCreator'
        ? 25
        : _socialMd == 'Regular'
            ? 20
            : _socialMd == 'Shares'
                ? 15
                : _socialMd == 'Occasional'
                    ? 10
                    : _socialMd == 'Minimal'
                        ? 5
                        : 0;
    total += c4.clamp(0, 100);

    // Cat 5
    int c5 = 0;
    c5 += _leadRole == 'College'
        ? 15
        : _leadRole == 'Department'
            ? 10
            : _leadRole == 'Class'
                ? 5
                : 0;
    c5 += _evtLead == 'Led2+'
        ? 15
        : _evtLead == 'Led1'
            ? 10
            : _evtLead == 'Assisted'
                ? 5
                : 0;
    c5 += _teamMgmt == 'Excellent'
        ? 15
        : _teamMgmt == 'Good'
            ? 10
            : _teamMgmt == 'Limited'
                ? 5
                : 0;
    c5 += _innvInit == 'Implemented'
        ? 25
        : _innvInit == 'Proposed'
            ? 15
            : _innvInit == 'Minor'
                ? 5
                : 0;
    c5 += _commLead == 'Led'
        ? 25
        : _commLead == 'Active'
            ? 15
            : _commLead == 'Minimal'
                ? 5
                : 0;
    total += c5.clamp(0, 100);

    setState(() {
      _previewTotal = total;
      _previewStars = total >= 450
          ? 5
          : total >= 400
              ? 4
              : total >= 350
                  ? 3
                  : total >= 300
                      ? 2
                      : total >= 250
                          ? 1
                          : 0;
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    for (final c in [
      _iatCtrl,
      _uniCtrl,
      _attCtrl,
      _ciCtrl,
      _ocCtrl,
      _spCtrl,
      _prCtrl,
      _iiCtrl,
      _rpCtrl
    ]) c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final body = <String, dynamic>{'student_id': SessionManager.studentId!};
      void n(String k, TextEditingController c) {
        final v = double.tryParse(c.text);
        if (v != null) body[k] = v;
      }

      void ni(String k, TextEditingController c) {
        final v = int.tryParse(c.text);
        if (v != null) body[k] = v;
      }

      void s(String k, String? v) {
        if (v != null && v.isNotEmpty) body[k] = v;
      }

      n('iat_gpa', _iatCtrl);
      n('university_gpa', _uniCtrl);
      n('attendance_pct', _attCtrl);
      n('consistency_index', _ciCtrl);
      ni('online_cert_count', _ocCtrl);
      ni('skill_programs', _spCtrl);
      n('placement_readiness', _prCtrl);
      ni('industry_interactions', _iiCtrl);
      ni('research_papers', _rpCtrl);
      s('mentor_feedback', _mentorFb);
      s('hod_feedback', _hodFb);
      s('project_status', _projStat);
      s('nptel_level', _nptel);
      s('internship_duration', _interDur);
      s('competition_result', _compRes);
      s('publication_type', _pubType);
      s('tech_skill_level', _techSkill);
      s('soft_skill_level', _softSkill);
      s('placement_outcome', _placOut);
      s('innovation_level', _innovLvl);
      s('discipline_conduct', _discCon);
      s('punctuality_level', _punctLvl);
      s('dress_code', _dressCd);
      s('dept_event_contribution', _deptEvt);
      s('social_media_level', _socialMd);
      s('leadership_role', _leadRole);
      s('event_leadership', _evtLead);
      s('team_management', _teamMgmt);
      s('innovation_initiative', _innvInit);
      s('community_leadership', _commLead);

      await ApiService.ssmSaveForm(
          studentId: SessionManager.studentId!, formData: body);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('✓ SSM Form saved!'),
            backgroundColor: Color(0xFF4CAF50)));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final catNames = [
      'Academic',
      'Development',
      'Skills',
      'Discipline',
      'Leadership'
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('SSM Form'),
        actions: [
          if (_previewTotal > 0)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('$_previewTotal/500',
                      style: TextStyle(
                          color: cs.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                  const SizedBox(width: 4),
                  ...List.generate(
                      5,
                      (i) => Icon(
                          i < _previewStars ? Icons.star : Icons.star_border,
                          color: const Color(0xFFFFB300),
                          size: 11)),
                ]),
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: List.generate(
              5,
              (i) => Tab(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: _tab.index == i
                            ? _catColors[i]
                            : _catColors[i].withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('${i + 1}. ${catNames[i]}',
                          style: TextStyle(
                              color: _tab.index == i
                                  ? Colors.white
                                  : _catColors[i],
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                    ),
                  )),
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [_cat1(), _cat2(), _cat3(), _cat4(), _cat5()],
      ),
      bottomNavigationBar: _bottomBar(cs),
    );
  }

  Widget _bottomBar(ColorScheme cs) {
    final idx = _tab.index;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          if (idx > 0) ...[
            Expanded(
                child: OutlinedButton(
              onPressed: () => _tab.animateTo(idx - 1),
              style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              child: const Text('← Back'),
            )),
            const SizedBox(width: 10),
          ],
          if (idx < 4)
            Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () => _tab.animateTo(idx + 1),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _catColors[idx + 1],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: const Text('Next →',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ))
          else
            Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: _isSaving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Save Form ✓',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                )),
        ]),
      ),
    );
  }

  // ── Category builders ──────────────────────────────────────────────────────

  Widget _cat1() => _catList(
          _catColors[0], 'Category 1: Academic Performance', 'Max 100 pts', [
        _num(
            '1.1  Internal Assessment GPA',
            'Average of IAT I, II & Model Exam (0–10)',
            _iatCtrl,
            Icons.school_outlined),
        _num('1.2  University Examination GPA', 'End semester results (0–10)',
            _uniCtrl, Icons.account_balance_outlined),
        _num('1.3  Attendance %', '≥95%→15pts | ≥90%→10pts | ≥85%→5pts',
            _attCtrl, Icons.how_to_reg_outlined),
        _dd('1.4  Mentor Feedback', ['Excellent', 'Good', 'Average'], _mentorFb,
            Icons.person_outlined, (v) {
          setState(() {
            _mentorFb = v;
            _calcPreview();
          });
        }),
        _dd('1.5  HoD Feedback', ['Excellent', 'Good', 'Average'], _hodFb,
            Icons.supervisor_account_outlined, (v) {
          setState(() {
            _hodFb = v;
            _calcPreview();
          });
        }),
        _dd(
            '1.6  Project (Beyond Curriculum)',
            ['Fully Completed', 'Partial', 'Concept'],
            _projStat,
            Icons.build_outlined, (v) {
          setState(() {
            _projStat = v;
            _calcPreview();
          });
        }),
        _num(
            '1.7  Academic Consistency Index %',
            'Internal vs University marks consistency',
            _ciCtrl,
            Icons.trending_up_outlined),
      ]);

  Widget _cat2() => _catList(_catColors[1],
          'Category 2: Student Development Activities', 'Max 100 pts', [
        _dd(
            '2.1  NPTEL / SWAYAM Level',
            [
              'Elite+Silver',
              'Elite+Gold',
              'Top5%',
              'Elite',
              'Completed',
              'Participated'
            ],
            _nptel,
            Icons.verified_outlined, (v) {
          setState(() {
            _nptel = v;
            _calcPreview();
          });
        }, labels: {
          'Elite+Silver': 'Elite + Silver / Top 5%',
          'Elite+Gold': 'Elite + Gold',
          'Top5%': 'Top 5%',
          'Elite': 'Elite Certificate',
          'Completed': 'Successfully Completed',
          'Participated': 'Participated (No Cert)'
        }),
        _int(
            '2.2  Industry Online Certifications',
            'Coursera / Udemy ≥20 hrs each (count)',
            _ocCtrl,
            Icons.laptop_outlined),
        _dd(
            '2.3  Internship / In-plant Training',
            ['4weeks+', '2-4weeks', '1-2weeks', 'Participation'],
            _interDur,
            Icons.work_outline, (v) {
          setState(() {
            _interDur = v;
            _calcPreview();
          });
        }, labels: {
          '4weeks+': '≥4 weeks + project/report',
          '2-4weeks': '2–4 weeks + project',
          '1-2weeks': '1–2 weeks (≥7 days)',
          'Participation': 'Participation only'
        }),
        _dd(
            '2.4  Technical Competition / Hackathon',
            ['Winner', 'Finalist', 'Participation'],
            _compRes,
            Icons.emoji_events_outlined, (v) {
          setState(() {
            _compRes = v;
            _calcPreview();
          });
        }, labels: {
          'Winner': 'Winner / Top 3',
          'Finalist': 'Finalist / Shortlisted',
          'Participation': 'Participation'
        }),
        _dd(
            '2.5  Publications / Patents / Product Dev.',
            ['Patent', 'Conference', 'Prototype'],
            _pubType,
            Icons.article_outlined, (v) {
          setState(() {
            _pubType = v;
            _calcPreview();
          });
        }, labels: {
          'Patent': 'Patent Filed / Product Developed',
          'Conference': 'Conference / Journal Paper',
          'Prototype': 'Prototype / Idea Validated'
        }),
        _int(
            '2.6  Professional Skill Programs',
            'Workshops / Value-added / Add-on courses (count)',
            _spCtrl,
            Icons.star_outline),
      ]);

  Widget _cat3() => _catList(_catColors[2],
          'Category 3: Skill, Prof. Readiness & Research', 'Max 100 pts', [
        _dd('3.1  Technical Skill Competency', ['Excellent', 'Good', 'Basic'],
            _techSkill, Icons.code_outlined, (v) {
          setState(() {
            _techSkill = v;
            _calcPreview();
          });
        }, labels: {
          'Excellent': 'Excellent (Independent problem solving)',
          'Good': 'Good (Can apply with guidance)',
          'Basic': 'Basic (Limited application)'
        }),
        _dd(
            '3.2  Soft Skills & Communication',
            ['Excellent', 'Good', 'Average'],
            _softSkill,
            Icons.record_voice_over_outlined, (v) {
          setState(() {
            _softSkill = v;
            _calcPreview();
          });
        }),
        _num(
            '3.3  Placement Readiness %',
            'Aptitude / Coding practice / Mock interviews attendance',
            _prCtrl,
            Icons.business_center_outlined),
        _dd(
            '3.4  Placement Outcome / Career',
            ['15+LPA', '10-14LPA', '7.5-9.9LPA', '<7.5LPA'],
            _placOut,
            Icons.currency_rupee_outlined, (v) {
          setState(() {
            _placOut = v;
            _calcPreview();
          });
        }, labels: {
          '15+LPA': '≥15 LPA (or GATE / Top University)',
          '10-14LPA': '10–14.9 LPA',
          '7.5-9.9LPA': '7.5–9.9 LPA',
          '<7.5LPA': '<7.5 LPA / Internship offer'
        }),
        _int(
            '3.5  Industry Interactions',
            'Guest lectures / industrial visits / workshops (count)',
            _iiCtrl,
            Icons.factory_outlined),
        _int(
            '3.6  Research Papers Read',
            'Papers reviewed with presentation (count)',
            _rpCtrl,
            Icons.menu_book_outlined),
        _dd('3.7  Innovation / Idea Contribution', ['Implemented', 'Proposed'],
            _innovLvl, Icons.lightbulb_outline, (v) {
          setState(() {
            _innovLvl = v;
            _calcPreview();
          });
        }, labels: {
          'Implemented': 'Innovative idea implemented',
          'Proposed': 'Idea proposed'
        }),
      ]);

  Widget _cat4() => _catList(
          _catColors[3],
          'Category 4: Discipline & Contribution to Institution',
          'Max 100 pts', [
        _dd(
            '4.1  Discipline & Code of Conduct',
            ['Exemplary', 'Minor Issues', 'Issues'],
            _discCon,
            Icons.verified_user_outlined, (v) {
          setState(() {
            _discCon = v;
            _calcPreview();
          });
        }, labels: {
          'Exemplary': 'No violations, exemplary conduct',
          'Minor Issues': 'Minor issues',
          'Issues': 'Disciplinary issues'
        }),
        _dd(
            '4.2  Attendance & Punctuality Discipline',
            ['ge95NoLate', '90-94', '85-89'],
            _punctLvl,
            Icons.access_time_outlined, (v) {
          setState(() {
            _punctLvl = v;
            _calcPreview();
          });
        }, labels: {
          'ge95NoLate': '≥95% + No late entries',
          '90-94': '90–94% + Minimal late',
          '85-89': '85–89%'
        }),
        _dd(
            '4.3  Dress Code & Professional Appearance',
            ['100% Adherence', 'Highly Regular', 'General'],
            _dressCd,
            Icons.checkroom_outlined, (v) {
          setState(() {
            _dressCd = v;
            _calcPreview();
          });
        }, labels: {
          '100% Adherence': '100% Consistent (full marks)',
          'Highly Regular': 'Highly regular with minor deviations',
          'General': 'Generally follows dress code'
        }),
        _dd(
            '4.4  Contribution to Department Events',
            ['Impactful', 'Useful', 'Minor'],
            _deptEvt,
            Icons.event_outlined, (v) {
          setState(() {
            _deptEvt = v;
            _calcPreview();
          });
        }, labels: {
          'Impactful': 'Implemented impactful initiative',
          'Useful': 'Proposed useful idea',
          'Minor': 'Minor idea'
        }),
        _dd(
            '4.5  Social Media & Promotional Activities',
            ['ActiveCreator', 'Regular', 'Shares', 'Occasional', 'Minimal'],
            _socialMd,
            Icons.share_outlined, (v) {
          setState(() {
            _socialMd = v;
            _calcPreview();
          });
        }, labels: {
          'ActiveCreator': 'Actively creates & manages quality content',
          'Regular': 'Regularly contributes',
          'Shares': 'Participates and shares content',
          'Occasional': 'Occasional contribution',
          'Minimal': 'Minimal / Class group only'
        }),
      ]);

  Widget _cat5() => _catList(_catColors[4],
          'Category 5: Leadership Roles & Initiatives', 'Max 100 pts', [
        _dd('5.1  Formal Leadership Roles', ['College', 'Department', 'Class'],
            _leadRole, Icons.groups_outlined, (v) {
          setState(() {
            _leadRole = v;
            _calcPreview();
          });
        }, labels: {
          'College': 'Major – College level (CR, Club Secretary/President)',
          'Department': 'Department level leadership',
          'Class': 'Class level leadership'
        }),
        _dd('5.2  Event Leadership & Coordination',
            ['Led2+', 'Led1', 'Assisted'], _evtLead, Icons.flag_outlined, (v) {
          setState(() {
            _evtLead = v;
            _calcPreview();
          });
        }, labels: {
          'Led2+': 'Led ≥2 events successfully',
          'Led1': 'Led 1 event',
          'Assisted': 'Assisted leadership'
        }),
        _dd(
            '5.3  Team Management & Collaboration',
            ['Excellent', 'Good', 'Limited'],
            _teamMgmt,
            Icons.people_outline, (v) {
          setState(() {
            _teamMgmt = v;
            _calcPreview();
          });
        }, labels: {
          'Excellent': 'Excellent team leader',
          'Good': 'Good team player',
          'Limited': 'Limited teamwork'
        }),
        _dd(
            '5.4  Innovation & Initiative',
            ['Implemented', 'Proposed', 'Minor'],
            _innvInit,
            Icons.rocket_launch_outlined, (v) {
          setState(() {
            _innvInit = v;
            _calcPreview();
          });
        }, labels: {
          'Implemented': 'Implemented impactful initiative',
          'Proposed': 'Proposed useful idea',
          'Minor': 'Minor idea'
        }),
        _dd('5.5  Social / Community Leadership', ['Led', 'Active', 'Minimal'],
            _commLead, Icons.volunteer_activism_outlined, (v) {
          setState(() {
            _commLead = v;
            _calcPreview();
          });
        }, labels: {
          'Led': 'Led community project',
          'Active': 'Active participant',
          'Minimal': 'Minimal involvement'
        }),
      ]);

  // ── Shared widgets ─────────────────────────────────────────────────────────

  Widget _catList(
      Color color, String title, String subtitle, List<Widget> children) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(children: [
            Icon(Icons.info_outline, color: color, size: 18),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.bold, fontSize: 13)),
              Text(subtitle,
                  style:
                      TextStyle(color: color.withOpacity(0.7), fontSize: 11)),
            ]),
          ]),
        ),
        ...children,
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _num(String label, String helper, TextEditingController ctrl,
          IconData icon) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: TextFormField(
            controller: ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
            ],
            decoration: InputDecoration(
              labelText: label,
              helperText: helper,
              helperStyle: const TextStyle(fontSize: 11),
              prefixIcon: Icon(icon),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
            ),
          ));

  Widget _int(String label, String helper, TextEditingController ctrl,
          IconData icon) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: TextFormField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: label,
              helperText: helper,
              helperStyle: const TextStyle(fontSize: 11),
              hintText: 'Enter number',
              prefixIcon: Icon(icon),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
            ),
          ));

  Widget _dd(String label, List<String> opts, String? val, IconData icon,
          ValueChanged<String?> onChanged,
          {Map<String, String>? labels}) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: DropdownButtonFormField<String>(
            value: val,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: label,
              prefixIcon: Icon(icon),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
            ),
            items: opts
                .map((o) => DropdownMenuItem(
                      value: o,
                      child: Text(labels?[o] ?? o,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13)),
                    ))
                .toList(),
            onChanged: onChanged,
          ));
}
