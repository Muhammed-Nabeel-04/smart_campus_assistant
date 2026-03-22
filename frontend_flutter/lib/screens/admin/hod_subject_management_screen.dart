// lib/screens/admin/hod_subject_management_screen.dart
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../core/session.dart';

class HODSubjectManagementScreen extends StatefulWidget {
  const HODSubjectManagementScreen({super.key});

  @override
  State<HODSubjectManagementScreen> createState() =>
      _HODSubjectManagementScreenState();
}

class _HODSubjectManagementScreenState extends State<HODSubjectManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ── Subjects state ────────────────────────────────────────
  bool _isLoading = true;
  Map<String, dynamic> _data = {};
  Map<String, List<String>> _sectionsByYear = {};
  bool _loadingSections = true;
  final _customSectionCtrl = TextEditingController();

  // ── Timetable state ───────────────────────────────────────
  List<Map<String, dynamic>> _classes = [];
  bool _loadingClasses = true;

  final List<String> _years = ['1st Year', '2nd Year', '3rd Year', '4th Year'];
  final List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];
  final Map<String, List<int>> _yearSemesters = {
    '1st Year': [1, 2],
    '2nd Year': [3, 4],
    '3rd Year': [5, 6],
    '4th Year': [7, 8],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
    _loadSections();
    _loadTimetableInit();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _customSectionCtrl.dispose();
    super.dispose();
  }

  // ── Subjects methods ──────────────────────────────────────

  Future<void> _loadSections() async {
    try {
      final sections = await ApiService.getHODSections();
      if (mounted)
        setState(() {
          _sectionsByYear = sections;
          _loadingSections = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loadingSections = false);
    }
  }

  Future<void> _saveSections() async {
    final cs = Theme.of(context).colorScheme;
    try {
      await ApiService.updateHODSections(_sectionsByYear);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sections saved'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
    } on ApiException catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
    }
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getHODSubjects();
      if (mounted)
        setState(() {
          _data = data;
          _isLoading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic> get _subjectsByYear =>
      (_data['subjects_by_year'] as Map<String, dynamic>?) ?? {};
  Map<String, dynamic> get _currentSemesters =>
      (_data['current_semesters'] as Map<String, dynamic>?) ?? {};

  int _getCurrentSemester(String year) {
    final sem = _currentSemesters[year];
    if (sem == null) return _yearSemesters[year]!.first;
    if (sem is int) return sem;
    final match = RegExp(r'\d+').firstMatch(sem.toString());
    return match != null
        ? int.parse(match.group(0)!)
        : _yearSemesters[year]!.first;
  }

  Future<void> _updateSemester(String year, int semester) async {
    final cs = Theme.of(context).colorScheme;
    try {
      await ApiService.updateClassSemester(year: year, semester: semester);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$year → Semester $semester'),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
        _load();
      }
    } on ApiException catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: cs.error),
        );
    }
  }

  Future<void> _deleteSubject(int subjectId, String name) async {
    final cs = Theme.of(context).colorScheme;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Subject'),
        content: Text('Delete "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: cs.error),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await ApiService.deleteHODSubject(subjectId);
        _load();
      } on ApiException catch (e) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message), backgroundColor: cs.error),
          );
      }
    }
  }

  void _showAddSubjectDialog(String year) {
    final nameCtrl = TextEditingController();
    int selectedSemester = _getCurrentSemester(year);
    int selectedCredits = 3;
    String selectedType = 'Theory';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text('Add Subject — $year'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Subject Name',
                    prefixIcon: Icon(Icons.book_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: selectedSemester,
                  decoration: const InputDecoration(labelText: 'Semester'),
                  items: _yearSemesters[year]!
                      .map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text('Semester $s'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setD(() => selectedSemester = v!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: selectedCredits,
                  decoration: const InputDecoration(labelText: 'Credits'),
                  items: [1, 2, 3, 4, 5, 6]
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text('$c Credits'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setD(() => selectedCredits = v!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: ['Theory', 'Lab', 'Project']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setD(() => selectedType = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                try {
                  await ApiService.addHODSubject(
                    name: nameCtrl.text.trim(),
                    year: year,
                    semester: selectedSemester,
                    credits: selectedCredits,
                    subjectType: selectedType,
                  );
                  if (mounted) {
                    _showSnack('Subject added');
                    _load();
                  }
                } on ApiException catch (e) {
                  if (mounted) _showSnack(e.message, isError: true);
                }
              },
              child: const Text('Add Subject'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditSubjectDialog(Map<String, dynamic> subject) {
    final nameCtrl = TextEditingController(text: subject['name']);
    int selectedCredits = subject['credits'] ?? 3;
    String selectedType = subject['type'] ?? 'Theory';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('Edit Subject'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Subject Name',
                    prefixIcon: Icon(Icons.book_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: selectedCredits,
                  decoration: const InputDecoration(labelText: 'Credits'),
                  items: [1, 2, 3, 4, 5, 6]
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text('$c Credits'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setD(() => selectedCredits = v!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: ['Theory', 'Lab', 'Project']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setD(() => selectedType = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                try {
                  await ApiService.updateHODSubject(
                    subjectId: subject['id'],
                    name: nameCtrl.text.trim(),
                    credits: selectedCredits,
                    subjectType: selectedType,
                  );
                  if (mounted) {
                    _showSnack('Subject updated');
                    _load();
                  }
                } on ApiException catch (e) {
                  if (mounted) _showSnack(e.message, isError: true);
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Timetable methods ─────────────────────────────────────

  Future<void> _loadTimetableInit() async {
    try {
      final hodDept = await ApiService.getHODDepartment();
      final deptId = hodDept['department_id'];
      if (deptId == null) {
        if (mounted) setState(() => _loadingClasses = false);
        return;
      }

      // Load sections per year configured by HOD
      final sectionsByYear = await ApiService.getHODSections();

      // Generate all possible classes = all years × their sections
      final List<Map<String, dynamic>> allClasses = [];
      for (final year in _years) {
        final yearSections = sectionsByYear[year] ?? ['A'];
        for (final section in yearSections) {
          // Try to find existing class in DB
          final existingClasses = await ApiService.getClassesByDepartment(
            deptId,
          );
          final existing = (existingClasses as List).firstWhere(
            (c) => c['year'] == year && c['section'] == section,
            orElse: () => {},
          );
          if (existing.isNotEmpty) {
            allClasses.add(Map<String, dynamic>.from(existing));
          } else {
            // Class doesn't exist yet — add as placeholder with no id
            allClasses.add({
              'id': null,
              'year': year,
              'section': section,
              'department_id': deptId,
            });
          }
        }
      }

      if (mounted)
        setState(() {
          _classes = allClasses;
          _loadingClasses = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loadingClasses = false);
    }
  }

  Future<void> _loadTimetableForClass(Map<String, dynamic> cls) async {
    if (cls['id'] == null) {
      _showSnack(
        'No students in this class yet. Add faculty with this class assignment first.',
        isError: true,
      );
      return;
    }
    // Push to grid editor
    Navigator.pushNamed(
      context,
      '/ccTimetableEditor',
      arguments: {'class_id': cls['id'], 'faculty_id': SessionManager.userId},
    );
  }

  // ── Snack helper ──────────────────────────────────────────

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : const Color(0xFF4CAF50),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subjects & Timetable'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.book_outlined), text: 'Subjects'),
            Tab(icon: Icon(Icons.calendar_today_outlined), text: 'Timetable'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildSubjectsTab(cs), _buildTimetableTab(cs)],
      ),
    );
  }

  // ============================================================
  // SUBJECTS TAB (unchanged logic)
  // ============================================================

  Widget _buildSubjectsTab(ColorScheme cs) {
    if (_isLoading)
      return Center(child: CircularProgressIndicator(color: cs.primary));
    return RefreshIndicator(
      onRefresh: _load,
      color: cs.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _years.length + 1,
        itemBuilder: (ctx, i) {
          if (i == 0) return _buildSectionsCard(cs);
          final year = _years[i - 1];
          final subjects = (_subjectsByYear[year] as List?) ?? [];
          final currentSem = _getCurrentSemester(year);

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.onSurface.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: cs.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          year,
                          style: TextStyle(
                            color: cs.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButton<int>(
                          value: currentSem,
                          isExpanded: true,
                          dropdownColor: cs.surface,
                          underline: const SizedBox(),
                          icon: Icon(
                            Icons.swap_vert,
                            color: cs.primary,
                            size: 20,
                          ),
                          items: _yearSemesters[year]!
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(
                                    'Active: Semester $s',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v != null && v != currentSem)
                              _updateSemester(year, v);
                          },
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.add_circle_outline, color: cs.primary),
                        onPressed: () => _showAddSubjectDialog(year),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                if (subjects.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'No subjects for this year',
                      style: TextStyle(
                        color: cs.onSurface.withOpacity(0.4),
                        fontSize: 13,
                      ),
                    ),
                  )
                else
                  ...subjects.map((sub) => _buildSubjectTile(sub, cs)),
              ],
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // TIMETABLE TAB
  // ============================================================

  Widget _buildTimetableTab(ColorScheme cs) {
    if (_loadingClasses) {
      return Center(child: CircularProgressIndicator(color: cs.primary));
    }

    if (_classes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.class_outlined,
              size: 60,
              color: cs.onSurface.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'No classes found',
              style: TextStyle(color: cs.onSurface.withOpacity(0.5)),
            ),
            const SizedBox(height: 8),
            Text(
              'Add faculty with teaching assignments first',
              style: TextStyle(
                color: cs.onSurface.withOpacity(0.3),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // ── Class selector ─────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          color: cs.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Class',
                style: TextStyle(
                  color: cs.onSurface.withOpacity(0.5),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              ..._years.map((year) {
                final yearClasses = _classes
                    .where((c) => c['year'] == year)
                    .toList();
                if (yearClasses.isEmpty) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: cs.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          year
                              .replaceAll('st Year', 'Y')
                              .replaceAll('nd Year', 'Y')
                              .replaceAll('rd Year', 'Y')
                              .replaceAll('th Year', 'Y'),
                          style: TextStyle(
                            color: cs.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: yearClasses.map((cls) {
                              return GestureDetector(
                                onTap: () => _loadTimetableForClass(cls),
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: cs.surfaceVariant.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: cs.onSurface.withOpacity(0.1),
                                    ),
                                  ),
                                  child: Text(
                                    'Sec ${cls['section']}',
                                    style: TextStyle(
                                      color: cs.onSurface,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),

        // ── Timetable content placeholder ──────────────────
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.edit_calendar,
                  size: 48,
                  color: cs.onSurface.withOpacity(0.2),
                ),
                const SizedBox(height: 16),
                Text(
                  'Select a class above to open the Timetable Editor',
                  style: TextStyle(color: cs.onSurface.withOpacity(0.4)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SHARED WIDGETS
  // ============================================================

  Widget _buildSectionsCard(ColorScheme cs) {
    final allSections = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.onSurface.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Sections per Year',
                    style: TextStyle(
                      color: cs.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _saveSections,
                  child: const Text('Save All'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (_loadingSections)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            ...(_years.map((year) {
              final yearSections = _sectionsByYear[year] ?? [];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: cs.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            year,
                            style: TextStyle(
                              color: cs.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...allSections.map((s) {
                          final isSelected = yearSections.contains(s);
                          return GestureDetector(
                            onTap: () => setState(() {
                              final list = List<String>.from(
                                _sectionsByYear[year] ?? [],
                              );
                              isSelected ? list.remove(s) : list.add(s);
                              _sectionsByYear[year] = list;
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? cs.primary.withOpacity(0.12)
                                    : cs.surfaceVariant.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? cs.primary
                                      : cs.onSurface.withOpacity(0.1),
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Text(
                                'Sec $s',
                                style: TextStyle(
                                  color: isSelected
                                      ? cs.primary
                                      : cs.onSurface.withOpacity(0.7),
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          );
                        }),
                        // Custom sections for this year
                        ...yearSections
                            .where((s) => !allSections.contains(s))
                            .map(
                              (s) => GestureDetector(
                                onTap: () => setState(() {
                                  final list = List<String>.from(
                                    _sectionsByYear[year] ?? [],
                                  );
                                  list.remove(s);
                                  _sectionsByYear[year] = list;
                                }),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: cs.primary.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: cs.primary),
                                  ),
                                  child: Text(
                                    'Sec $s',
                                    style: TextStyle(
                                      color: cs.primary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        // Add custom section for this year
                        GestureDetector(
                          onTap: () => _showAddCustomSection(year, cs),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: cs.onSurface.withOpacity(0.2),
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.add,
                                  size: 14,
                                  color: cs.onSurface.withOpacity(0.5),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Custom',
                                  style: TextStyle(
                                    color: cs.onSurface.withOpacity(0.5),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (year != _years.last)
                    Divider(height: 1, color: cs.onSurface.withOpacity(0.06)),
                ],
              );
            })).toList(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _showAddCustomSection(String year, ColorScheme cs) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add Section — $year'),
        content: TextField(
          controller: ctrl,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Section letter',
            hintText: 'e.g. G',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final s = ctrl.text.trim().toUpperCase();
              if (s.isNotEmpty) {
                final list = List<String>.from(_sectionsByYear[year] ?? []);
                if (!list.contains(s)) {
                  setState(() {
                    list.add(s);
                    _sectionsByYear[year] = list;
                  });
                }
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectTile(Map<String, dynamic> sub, ColorScheme cs) {
    final type = sub['type'] ?? 'Theory';
    final Color typeColor = type == 'Lab'
        ? const Color(0xFF00897B)
        : type == 'Project'
        ? const Color(0xFFE65100)
        : cs.primary;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: typeColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          type == 'Lab'
              ? Icons.science_outlined
              : type == 'Project'
              ? Icons.assignment_outlined
              : Icons.book_outlined,
          color: typeColor,
          size: 18,
        ),
      ),
      title: Text(
        sub['name'] ?? '',
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        'Sem ${sub['semester']} · ${sub['credits']} Credits · $type',
        style: TextStyle(color: cs.onSurface.withOpacity(0.5), fontSize: 12),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              Icons.edit_outlined,
              color: cs.primary.withOpacity(0.7),
              size: 20,
            ),
            onPressed: () => _showEditSubjectDialog(sub),
          ),
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              color: cs.error.withOpacity(0.6),
              size: 20,
            ),
            onPressed: () => _deleteSubject(sub['id'], sub['name']),
          ),
        ],
      ),
    );
  }
}
