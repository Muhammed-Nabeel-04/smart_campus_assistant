// lib/screens/admin/hod_subject_management_screen.dart
// HOD interface to manage departmental subjects and toggle active semesters

import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class HODSubjectManagementScreen extends StatefulWidget {
  const HODSubjectManagementScreen({super.key});

  @override
  State<HODSubjectManagementScreen> createState() =>
      _HODSubjectManagementScreenState();
}

class _HODSubjectManagementScreenState
    extends State<HODSubjectManagementScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _data = {};

  final List<String> _years = ['1st Year', '2nd Year', '3rd Year', '4th Year'];

  final Map<String, List<int>> _yearSemesters = {
    '1st Year': [1, 2],
    '2nd Year': [3, 4],
    '3rd Year': [5, 6],
    '4th Year': [7, 8],
  };

  List<String> _sections = [];
  bool _loadingSections = true;
  final _customSectionCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _loadSections();
  }

  Future<void> _loadSections() async {
    try {
      final sections = await ApiService.getHODSections();
      if (mounted)
        setState(() {
          _sections = sections;
          _loadingSections = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loadingSections = false);
    }
  }

  Future<void> _saveSections() async {
    final cs = Theme.of(context).colorScheme;
    try {
      await ApiService.updateHODSections(_sections);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sections saved successfully'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: cs.error),
        );
      }
    }
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getHODSubjects();
      if (mounted) {
        setState(() {
          _data = data;
          _isLoading = false;
        });
      }
    } catch (e) {
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
            content: Text('$year updated to Semester $semester'),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
        _load();
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: cs.error),
        );
      }
    }
  }

  Future<void> _deleteSubject(int subjectId, String name) async {
    final cs = Theme.of(context).colorScheme;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surface,
        title: const Text('Delete Subject'),
        content: Text('Are you sure you want to delete "$name"?'),
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message), backgroundColor: cs.error),
          );
        }
      }
    }
  }

  void _showAddSubjectDialog(String year) {
    final cs = Theme.of(context).colorScheme;
    final nameCtrl = TextEditingController();
    int selectedSemester = _getCurrentSemester(year);
    int selectedCredits = 3;
    String selectedType = 'Theory';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: cs.surface,
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
                  dropdownColor: cs.surface,
                  decoration: const InputDecoration(labelText: 'Semester'),
                  items: _yearSemesters[year]!
                      .map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text('Semester $s'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedSemester = v!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: selectedCredits,
                  dropdownColor: cs.surface,
                  decoration: const InputDecoration(labelText: 'Credits'),
                  items: [1, 2, 3, 4, 5, 6]
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text('$c Credits'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedCredits = v!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  dropdownColor: cs.surface,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: ['Theory', 'Lab', 'Project']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedType = v!),
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Subject added'),
                        backgroundColor: Color(0xFF4CAF50),
                      ),
                    );
                    _load();
                  }
                } on ApiException catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.message),
                        backgroundColor: cs.error,
                      ),
                    );
                  }
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
    final cs = Theme.of(context).colorScheme;
    final nameCtrl = TextEditingController(text: subject['name']);
    int selectedCredits = subject['credits'] ?? 3;
    String selectedType = subject['type'] ?? 'Theory';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: cs.surface,
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
                  dropdownColor: cs.surface,
                  decoration: const InputDecoration(labelText: 'Credits'),
                  items: [1, 2, 3, 4, 5, 6]
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text('$c Credits'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedCredits = v!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  dropdownColor: cs.surface,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: ['Theory', 'Lab', 'Project']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedType = v!),
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Subject updated'),
                        backgroundColor: Color(0xFF4CAF50),
                      ),
                    );
                    _load();
                  }
                } on ApiException catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.message),
                        backgroundColor: cs.error,
                      ),
                    );
                  }
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _customSectionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Subjects & Semesters')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: cs.primary))
          : RefreshIndicator(
              onRefresh: _load,
              color: cs.primary,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _years.length + 1, // +1 for sections card
                itemBuilder: (ctx, i) {
                  // First item — sections management card
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
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
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
                                icon: Icon(
                                  Icons.add_circle_outline,
                                  color: cs.primary,
                                ),
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
                              'No subjects added for this year',
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
            ),
    );
  }

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
                    'Sections',
                    style: TextStyle(
                      color: cs.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                TextButton(onPressed: _saveSections, child: const Text('Save')),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: _loadingSections
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select sections for your department:',
                        style: TextStyle(
                          color: cs.onSurface.withOpacity(0.6),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ...allSections.map((s) {
                            final isSelected = _sections.contains(s);
                            return GestureDetector(
                              onTap: () => setState(() {
                                isSelected
                                    ? _sections.remove(s)
                                    : _sections.add(s);
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
                          // Custom sections
                          ..._sections
                              .where((s) => !allSections.contains(s))
                              .map(
                                (s) => GestureDetector(
                                  onTap: () =>
                                      setState(() => _sections.remove(s)),
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
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _customSectionCtrl,
                              textCapitalization: TextCapitalization.characters,
                              decoration: const InputDecoration(
                                labelText: 'Add custom section',
                                hintText: 'e.g. Z',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () {
                              final s = _customSectionCtrl.text
                                  .trim()
                                  .toUpperCase();
                              if (s.isNotEmpty && !_sections.contains(s)) {
                                setState(() {
                                  _sections.add(s);
                                  _customSectionCtrl.clear();
                                });
                              }
                            },
                            icon: Icon(
                              Icons.add_circle_outline,
                              color: cs.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
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
