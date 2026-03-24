// File: lib/screens/admin/admin_edit_faculty_screen.dart
import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class AdminEditFacultyScreen extends StatefulWidget {
  final Map<String, dynamic> faculty;

  const AdminEditFacultyScreen({super.key, required this.faculty});

  @override
  State<AdminEditFacultyScreen> createState() => _AdminEditFacultyScreenState();
}

class _AdminEditFacultyScreenState extends State<AdminEditFacultyScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _employeeIdController;
  late TextEditingController _phoneController;

  bool _isLoading = false;
  bool _loadingDepts = true;

  // HOD's own department (auto-loaded)
  String _hodDepartmentCode = '';
  String _hodDepartmentName = '';

  // All departments (for assignment picker)
  List<Map<String, dynamic>> _departments = [];

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
    _nameController = TextEditingController(text: widget.faculty['name']);
    _emailController = TextEditingController(text: widget.faculty['email']);
    _employeeIdController = TextEditingController(
      text: widget.faculty['employee_id'],
    );
    _phoneController = TextEditingController(
      text: widget.faculty['phone'] ?? '',
    );

    // Load existing assignments
    final existing = widget.faculty['teaching_assignments'];
    if (existing != null && existing is List) {
      for (final a in existing) {
        _assignments.add({
          'year': a['year']?.toString() ?? '',
          'department': a['department']?.toString() ?? '',
          'section': a['section']?.toString() ?? '',
        });
      }
    }

    _isCc = widget.faculty['is_cc'] == true;
    _ccClassId = widget.faculty['cc_class_id'];
    _ccYear = widget.faculty['cc_year'];
    _ccSection = widget.faculty['cc_section'];

    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    try {
      final hodDept = await ApiService.getHODDepartment();
      final deptCode = hodDept['department_code'] ?? hodDept['code'] ?? '';
      final deptName =
          hodDept['department_name'] ?? hodDept['department'] ?? '';

      final data = await ApiService.getDepartments();
      Map<String, List<String>> sectionsByYear = {};
      try {
        sectionsByYear = await ApiService.getHODSections();
      } catch (_) {}

      if (mounted) {
        setState(() {
          _sectionsByYear = sectionsByYear;
          _hodDepartmentCode = deptCode;
          _hodDepartmentName = deptName;
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
      _showSnack('Select year, department and section first', isWarning: true);
      return;
    }
    final dup = _assignments.any(
      (a) =>
          a['year'] == _pickerYear &&
          a['department'] == _pickerDept &&
          a['section'] == _pickerSection,
    );
    if (dup) {
      _showSnack('Assignment already added', isWarning: true);
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

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    // If CC is ON and section is selected but classId not resolved yet, resolve now
    if (_isCc && _ccYear != null && _ccSection != null && _ccClassId == null) {
      final classId = await _findClassId(_ccYear!, _ccSection!);
      if (classId == null) {
        _showSnack(
          'Class not found for $_ccYear - Sec $_ccSection. Cannot assign CC.',
          isError: true,
        );
        return;
      }
      setState(() => _ccClassId = classId);
    }

    setState(() => _isLoading = true);
    try {
      await ApiService.updateFaculty(widget.faculty['id'], {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'employee_id': _employeeIdController.text.trim(),
        'department': _hodDepartmentCode,
        'phone': _phoneController.text.trim(),
        'teaching_assignments': _assignments,
      });

      // Update CC status
      await ApiService.setCCFaculty(
        facultyId: widget.faculty['id'],
        isCc: _isCc,
        ccClassId: _isCc ? _ccClassId : null,
      );

      if (mounted) {
        _showSnack('Faculty updated successfully');
        Navigator.pop(context, true);
      }
    } on ApiException catch (e) {
      if (mounted) _showSnack(e.message, isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false, bool isWarning = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : isWarning
            ? const Color(0xFFFF9800)
            : const Color(0xFF4CAF50),
      ),
    );
  }

  // ── UI Helpers ─────────────────────────────────────────────
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
      appBar: AppBar(title: const Text('Edit Faculty')),
      body: _loadingDepts
          ? Center(child: CircularProgressIndicator(color: cs.primary))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Basic Information ────────────────────────
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
                        validator: (v) =>
                            v?.isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email Address',
                          prefixIcon: Icon(Icons.alternate_email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) =>
                            v?.isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _employeeIdController,
                        decoration: const InputDecoration(
                          labelText: 'Employee ID',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        validator: (v) =>
                            v?.isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),

                      // Home department — read only, auto from HOD
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: cs.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: cs.primary.withOpacity(0.2),
                          ),
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
                                    _hodDepartmentName.isNotEmpty
                                        ? _hodDepartmentName
                                        : _hodDepartmentCode,
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
                          labelText: 'Phone Number',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── Teaching Assignments ─────────────────────
                  _card(
                    title: 'Teaching Assignments',
                    icon: Icons.class_outlined,
                    cs: cs,
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _assignments.isEmpty
                            ? cs.onSurface.withOpacity(0.05)
                            : cs.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_assignments.length} assigned',
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
                                  setState(
                                    () => _pickerDept = d['code'] as String,
                                  );
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
                        _secLabel('CURRENT ASSIGNMENTS', cs),
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
                                  backgroundColor: cs.surfaceVariant
                                      .withOpacity(0.5),
                                  deleteIcon: const Icon(Icons.close, size: 14),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── Class Coordinator (CC) ───────────────────
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
                                  (s) => _selChip(
                                    'Sec $s',
                                    _ccSection == s,
                                    () async {
                                      setState(() => _ccSection = s);
                                      final classId = await _findClassId(
                                        _ccYear!,
                                        s,
                                      );
                                      if (mounted)
                                        setState(() => _ccClassId = classId);
                                    },
                                    cs,
                                  ),
                                )
                                .toList(),
                          ),
                          if (_ccClassId == null && _ccSection != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: cs.error.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: cs.error.withOpacity(0.4),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: cs.error,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'No class found for $_ccYear - Sec $_ccSection. Please create this class first before assigning a CC.',
                                        style: TextStyle(
                                          color: cs.error,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ],
                    ],
                  ),

                  const SizedBox(height: 32),

                  // ── Submit Button ────────────────────────────
                  SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed:
                          (_isLoading ||
                              (_isCc &&
                                  _ccSection != null &&
                                  _ccClassId == null))
                          ? null
                          : _handleUpdate,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(_isLoading ? 'Updating...' : 'Save Changes'),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}
