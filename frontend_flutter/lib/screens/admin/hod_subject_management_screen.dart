// lib/screens/admin/hod_subject_management_screen.dart
import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
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
    // Parse "Semester X"
    final match = RegExp(r'\d+').firstMatch(sem.toString());
    return match != null
        ? int.parse(match.group(0)!)
        : _yearSemesters[year]!.first;
  }

  Future<void> _updateSemester(String year, int semester) async {
    try {
      await ApiService.updateClassSemester(year: year, semester: semester);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$year updated to Semester $semester'),
            backgroundColor: AppColors.success,
          ),
        );
        _load();
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<void> _deleteSubject(int subjectId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: const Text(
          'Delete Subject',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Delete "$name"?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Delete'),
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
            SnackBar(
              content: Text(e.message),
              backgroundColor: AppColors.danger,
            ),
          );
        }
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
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.bgCard,
          title: Text(
            'Add Subject — $year',
            style: const TextStyle(color: AppColors.textPrimary),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Subject Name',
                    prefixIcon: Icon(Icons.book),
                  ),
                ),
                const SizedBox(height: 12),
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
                  onChanged: (v) => setDialogState(() => selectedSemester = v!),
                ),
                const SizedBox(height: 12),
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
                  onChanged: (v) => setDialogState(() => selectedCredits = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedType,
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
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
              ),
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
                        content: Text('Subject added successfully'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                    _load();
                  }
                } on ApiException catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.message),
                        backgroundColor: AppColors.danger,
                      ),
                    );
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(title: const Text('Subjects & Semesters')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _years.length,
                itemBuilder: (ctx, i) {
                  final year = _years[i];
                  final subjects = (_subjectsByYear[year] as List?) ?? [];
                  final currentSem = _getCurrentSemester(year);
                  final semesters = _yearSemesters[year]!;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.danger.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Year header
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.danger.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  year,
                                  style: const TextStyle(
                                    color: AppColors.danger,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Current semester selector
                              Expanded(
                                child: DropdownButton<int>(
                                  value: currentSem,
                                  isExpanded: true,
                                  dropdownColor: AppColors.bgCard,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                  ),
                                  underline: Container(
                                    height: 1,
                                    color: AppColors.bgSeparator,
                                  ),
                                  items: semesters
                                      .map(
                                        (s) => DropdownMenuItem(
                                          value: s,
                                          child: Text(
                                            'Current: Semester $s',
                                            style: const TextStyle(
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) {
                                    if (v != null && v != currentSem) {
                                      _updateSemester(year, v);
                                    }
                                  },
                                ),
                              ),
                              // Add subject button
                              IconButton(
                                icon: const Icon(
                                  Icons.add_circle,
                                  color: AppColors.success,
                                ),
                                onPressed: () => _showAddSubjectDialog(year),
                                tooltip: 'Add Subject',
                              ),
                            ],
                          ),
                        ),

                        const Divider(height: 1),

                        // Subjects list
                        if (subjects.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'No subjects added yet',
                              style: TextStyle(
                                color: AppColors.textSecondary.withOpacity(0.6),
                                fontSize: 13,
                              ),
                            ),
                          )
                        else
                          ...subjects.map((sub) {
                            final typeColor = sub['type'] == 'Lab'
                                ? AppColors.success
                                : sub['type'] == 'Project'
                                ? AppColors.warning
                                : AppColors.info;
                            return ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: typeColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  sub['type'] == 'Lab'
                                      ? Icons.science
                                      : sub['type'] == 'Project'
                                      ? Icons.assignment
                                      : Icons.book,
                                  color: typeColor,
                                  size: 18,
                                ),
                              ),
                              title: Text(
                                sub['name'] ?? '',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(
                                'Sem ${sub['semester']} · ${sub['credits']} Credits · ${sub['type']}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: AppColors.danger,
                                  size: 20,
                                ),
                                onPressed: () =>
                                    _deleteSubject(sub['id'], sub['name']),
                              ),
                            );
                          }),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}
