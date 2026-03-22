// File: lib/screens/admin/admin_add_faculty_screen.dart

import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class AdminAddFacultyScreen extends StatefulWidget {
  const AdminAddFacultyScreen({super.key});

  @override
  State<AdminAddFacultyScreen> createState() => _AdminAddFacultyScreenState();
}

class _AdminAddFacultyScreenState extends State<AdminAddFacultyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _phoneController = TextEditingController();

  String _selectedDepartment = '';
  String _hodDepartmentName = '';
  bool _isLoading = false;
  List<Map<String, dynamic>> _departments = [];
  bool _loadingDepts = true;

  static const List<String> _years = [
    '1st Year',
    '2nd Year',
    '3rd Year',
    '4th Year',
  ];
  List<String> _sections = [];

  String? _pickerYear;
  String? _pickerDept;
  String? _pickerSection;
  final List<Map<String, String>> _assignments = [];

  // CC
  bool _isCc = false;
  String? _ccYear;
  String? _ccSection;
  int? _ccClassId;

  Map<String, List<String>> _sectionsByYear = {};

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    try {
      // Load HOD's own department first
      final hodDept = await ApiService.getHODDepartment();
      final deptCode = hodDept['department_code'] ?? hodDept['code'] ?? '';
      final deptName =
          hodDept['department_name'] ?? hodDept['department'] ?? '';

      // Load all departments for assignment picker
      final data = await ApiService.getDepartments();
      // Load sections for HOD's department
      Map<String, List<String>> sectionsByYear = {};
      try {
        sectionsByYear = await ApiService.getHODSections();
      } catch (_) {}

      if (mounted) {
        setState(() {
          _sectionsByYear = sectionsByYear;
          _selectedDepartment = deptCode;
          _hodDepartmentName = deptName;
          _pickerDept = deptCode;
          _departments = List<Map<String, dynamic>>.from(data);
          // Flatten all sections across all years for assignment picker
          final allSections = sectionsByYear.values
              .expand((s) => s)
              .toSet()
              .toList();
          _sections = allSections.isNotEmpty ? allSections : ['A', 'B', 'C'];
          _loadingDepts = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingDepts = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _employeeIdController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _addAssignment() {
    if (_pickerYear == null || _pickerDept == null || _pickerSection == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select year, department and section first'),
          backgroundColor: Color(0xFFFF9800), // Warning Orange
        ),
      );
      return;
    }
    final dup = _assignments.any(
      (a) =>
          a['year'] == _pickerYear &&
          a['department'] == _pickerDept &&
          a['section'] == _pickerSection,
    );
    if (dup) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Assignment already added'),
          backgroundColor: Color(0xFFFF9800),
        ),
      );
      return;
    }
    setState(() {
      _assignments.add({
        'year': _pickerYear!,
        'department': _pickerDept!,
        'section': _pickerSection!,
      });
      _pickerYear = _pickerDept = _pickerSection = null;
    });
  }

  Future<void> _loadSectionsForDept(String deptCode) async {
    try {
      // Load per-year sections from HOD
      final sectionsByYear = await ApiService.getHODSections();
      // Use sections for currently selected year, or flatten all
      final yearSections = _pickerYear != null
          ? (sectionsByYear[_pickerYear] ?? [])
          : sectionsByYear.values.expand((s) => s).toSet().toList();
      if (mounted && yearSections.isNotEmpty) {
        setState(() => _sections = yearSections);
      }
    } catch (_) {}
  }

  Future<int?> _findClassId(String year, String section) async {
    try {
      final hodDept = await ApiService.getHODDepartment();
      final deptId = hodDept['department_id'];
      if (deptId == null) return null;
      final classes = await ApiService.getClassesByDepartment(deptId);
      final cls = (classes as List).firstWhere(
        (c) => c['year'] == year && c['section'] == section,
        orElse: () => {},
      );
      return cls.isEmpty ? null : cls['id'];
    } catch (_) {
      return null;
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDepartment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a home department')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final result = await ApiService.createFaculty({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'employee_id': _employeeIdController.text.trim(),
        'department': _selectedDepartment,
        'phone': _phoneController.text.trim(),
        'teaching_assignments': _assignments,
      });
      // Set CC if enabled
      if (_isCc && _ccClassId != null) {
        final facultyId = result['id'] ?? result['faculty_id'];
        if (facultyId != null) {
          await ApiService.setCCFaculty(
            facultyId: facultyId,
            isCc: true,
            ccClassId: _ccClassId,
          );
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Faculty created! Now generate a QR to complete onboarding.',
            ),
            backgroundColor: Color(0xFF4CAF50), // Success Green
          ),
        );
        Navigator.pop(context, true);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── UI helpers ─────────────────────────────────────────────────────────────

  Widget _selChip(
    String label,
    bool selected,
    VoidCallback onTap,
    ColorScheme cs,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? cs.primary.withOpacity(0.12)
              : cs.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? cs.primary : cs.onSurface.withOpacity(0.1),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? cs.primary : cs.onSurface.withOpacity(0.7),
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _secLabel(String t, ColorScheme cs) => Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 8),
    child: Text(
      t,
      style: TextStyle(
        color: cs.onSurface.withOpacity(0.5),
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.8,
      ),
    ),
  );

  Widget _card({
    required String title,
    required IconData icon,
    required List<Widget> children,
    required ColorScheme cs,
    Widget? trailing,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.onSurface.withOpacity(0.1)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: cs.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: cs.onSurface.withOpacity(0.05), height: 1),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Add New Faculty')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _card(
              title: 'Basic Information',
              icon: Icons.person_outline,
              cs: cs,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.alternate_email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _employeeIdController,
                  decoration: const InputDecoration(
                    labelText: 'Employee ID',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                // Department auto-set from HOD's department
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: cs.primary.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.business_outlined,
                        color: cs.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Home Department',
                              style: TextStyle(
                                color: cs.onSurface.withOpacity(0.5),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _loadingDepts
                                  ? 'Loading...'
                                  : _hodDepartmentName.isNotEmpty
                                  ? _hodDepartmentName
                                  : _selectedDepartment,
                              style: TextStyle(
                                color: cs.onSurface,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.lock_outline,
                        color: cs.onSurface.withOpacity(0.3),
                        size: 16,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone (Optional)',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _card(
              title: 'Teaching Assignments',
              icon: Icons.class_outlined,
              cs: cs,
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _assignments.isEmpty
                      ? cs.onSurface.withOpacity(0.05)
                      : cs.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_assignments.length} added',
                  style: TextStyle(
                    color: _assignments.isEmpty
                        ? cs.onSurface.withOpacity(0.4)
                        : cs.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.1)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue, size: 14),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Assignments auto-setup department, class & subject relationships.',
                          style: TextStyle(color: Colors.blue, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                _secLabel('YEAR', cs),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _years
                      .map(
                        (y) => _selChip(
                          y,
                          _pickerYear == y,
                          () => setState(() => _pickerYear = y),
                          cs,
                        ),
                      )
                      .toList(),
                ),
                _secLabel('DEPARTMENT', cs),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _departments
                      .map(
                        (d) => _selChip(
                          '${d['name']}',
                          _pickerDept == d['code'],
                          () {
                            setState(() => _pickerDept = d['code'] as String);
                            _loadSectionsForDept(d['code'] as String);
                          },
                          cs,
                        ),
                      )
                      .toList(),
                ),
                _secLabel('SECTION', cs),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _sections
                      .map(
                        (s) => _selChip(
                          'Sec $s',
                          _pickerSection == s,
                          () => setState(() => _pickerSection = s),
                          cs,
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _addAssignment,
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: const Text('Add Assignment'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: cs.primary,
                      side: BorderSide(color: cs.primary),
                    ),
                  ),
                ),
                if (_assignments.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  _secLabel('CURRENT LIST', cs),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _assignments
                        .map(
                          (a) => Chip(
                            label: Text(
                              '${a['department']} · ${a['year']} · Sec ${a['section']}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            onDeleted: () =>
                                setState(() => _assignments.remove(a)),
                            backgroundColor: cs.surfaceVariant.withOpacity(0.5),
                            deleteIcon: const Icon(Icons.close, size: 14),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            _card(
              title: 'Class Coordinator (CC)',
              icon: Icons.stars_outlined,
              cs: cs,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Assign as Class Coordinator',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: cs.onSurface,
                            ),
                          ),
                          Text(
                            'CC can manage timetable for their class',
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isCc,
                      onChanged: (v) => setState(() {
                        _isCc = v;
                        if (!v) {
                          _ccYear = null;
                          _ccSection = null;
                          _ccClassId = null;
                        }
                      }),
                    ),
                  ],
                ),
                if (_isCc) ...[
                  const SizedBox(height: 16),
                  _secLabel('CC YEAR', cs),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _years
                        .map(
                          (y) => _selChip(
                            y,
                            _ccYear == y,
                            () => setState(() {
                              _ccYear = y;
                              _ccSection = null;
                              _ccClassId = null;
                            }),
                            cs,
                          ),
                        )
                        .toList(),
                  ),
                  if (_ccYear != null) ...[
                    _secLabel('CC SECTION', cs),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (_sectionsByYear[_ccYear] ?? [])
                          .map(
                            (
                              s,
                            ) => _selChip('Sec $s', _ccSection == s, () async {
                              setState(() => _ccSection = s);
                              final classId = await _findClassId(_ccYear!, s);
                              if (mounted) setState(() => _ccClassId = classId);
                            }, cs),
                          )
                          .toList(),
                    ),
                    if (_ccClassId == null && _ccSection != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '⚠ This class has no students yet. CC will be set after class is created.',
                          style: TextStyle(color: cs.error, fontSize: 12),
                        ),
                      ),
                  ],
                ],
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _handleSubmit,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(
                  _isLoading ? 'Creating...' : 'Create Faculty Account',
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
