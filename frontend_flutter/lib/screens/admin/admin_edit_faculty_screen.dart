// File: lib/screens/admin/admin_edit_faculty_screen.dart
// Admin interface to edit existing faculty details and manage teaching assignments

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
  late String _selectedDepartment;
  bool _isLoading = false;

  static const List<String> _years = [
    '1st Year',
    '2nd Year',
    '3rd Year',
    '4th Year',
  ];
  static const List<String> _sections = ['A', 'B', 'C', 'D', 'E', 'F'];
  static const List<String> _validDepts = [
    'AIDS',
    'AI',
    'CSE',
    'ECE',
    'MECH',
    'CIVIL',
    'IT',
    'BME',
  ];

  static const Map<String, String> _deptLabels = {
    'CSE': 'Computer Science',
    'AI': 'Artificial Intelligence',
    'BME': 'Biomedical Engg',
    'ECE': 'Electronics',
    'MECH': 'Mechanical',
    'CIVIL': 'Civil',
    'IT': 'Information Technology',
    'AIDS': 'AI & Data Science',
  };

  String? _pickerYear;
  String? _pickerDept;
  String? _pickerSection;
  final List<Map<String, String>> _assignments = [];

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

    final dept = widget.faculty['department'] ?? 'CSE';
    _selectedDepartment = _validDepts.contains(dept) ? dept : 'CSE';

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

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await ApiService.updateFaculty(widget.faculty['id'], {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'employee_id': _employeeIdController.text.trim(),
        'department': _selectedDepartment,
        'phone': _phoneController.text.trim(),
        'teaching_assignments': _assignments,
      });
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
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError
            ? cs.error
            : (isWarning ? Colors.orange : Colors.green),
      ),
    );
  }

  // ── UI Helpers ─────────────────────────────────────────────────────────────

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
      appBar: AppBar(title: const Text('Edit Faculty Profile')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Basic Information
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
                    labelText: 'Email Address',
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
                DropdownButtonFormField<String>(
                  value: _selectedDepartment,
                  decoration: const InputDecoration(
                    labelText: 'Home Department',
                    prefixIcon: Icon(Icons.business_outlined),
                  ),
                  dropdownColor: cs.surface,
                  items: _validDepts
                      .map(
                        (d) => DropdownMenuItem(
                          value: d,
                          child: Text('$d · ${_deptLabels[d] ?? d}'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _selectedDepartment = v ?? 'CSE'),
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

            // Teaching Assignments
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
                  children: _validDepts
                      .map(
                        (d) => _selChip(
                          d,
                          _pickerDept == d,
                          () => setState(() => _pickerDept = d),
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
                            backgroundColor: cs.surfaceVariant.withOpacity(0.5),
                            deleteIcon: const Icon(Icons.close, size: 14),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _handleUpdate,
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
