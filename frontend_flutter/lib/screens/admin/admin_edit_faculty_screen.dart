// File: lib/screens/admin/admin_edit_faculty_screen.dart
import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
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
  static const List<String> _depts = [
    'CSE',
    'AI',
    'BME',
    'ECE',
    'MECH',
    'CIVIL',
    'IT',
    'AIDS',
  ];
  static const List<String> _sections = ['A', 'B', 'C', 'D', 'E', 'F'];
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

    // Load existing teaching assignments
    print("DEBUG faculty data: ${widget.faculty}");
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select year, department and section first'),
          backgroundColor: AppColors.warning,
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
          backgroundColor: AppColors.warning,
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Faculty updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── UI helpers ─────────────────────────────────────────────────────────────

  Widget _selChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(0.18)
              : AppColors.bgInput,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.bgSeparator,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _secLabel(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      t,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    ),
  );

  Widget _card({
    required String title,
    required IconData icon,
    required List<Widget> children,
    Widget? trailing,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.bgSeparator),
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
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: AppColors.bgSeparator, height: 1),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(title: const Text('Edit Faculty')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Basic Info card ─────────────────────────────────
            _card(
              title: 'Basic Information',
              icon: Icons.person_outlined,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _employeeIdController,
                  decoration: const InputDecoration(
                    labelText: 'Employee ID',
                    prefixIcon: Icon(Icons.badge),
                  ),
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedDepartment,
                  decoration: const InputDecoration(
                    labelText: 'Home Department',
                    prefixIcon: Icon(Icons.business),
                  ),
                  items: _validDepts
                      .map(
                        (d) => DropdownMenuItem(
                          value: d,
                          child: Text('$d  ·  ${_deptLabels[d] ?? d}'),
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
                    labelText: 'Phone (Optional)',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Teaching Assignments card ────────────────────────
            _card(
              title: 'Teaching Assignments',
              icon: Icons.class_outlined,
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _assignments.isEmpty
                      ? AppColors.bgSeparator
                      : AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_assignments.length} added',
                  style: TextStyle(
                    color: _assignments.isEmpty
                        ? AppColors.textSecondary
                        : AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              children: [
                // Year chips
                _secLabel('YEAR'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _years
                      .map(
                        (y) => _selChip(
                          y,
                          _pickerYear == y,
                          () => setState(() => _pickerYear = y),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 14),

                // Department chips
                _secLabel('DEPARTMENT'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _depts
                      .map(
                        (d) => _selChip(
                          '$d  ·  ${_deptLabels[d] ?? d}',
                          _pickerDept == d,
                          () => setState(() => _pickerDept = d),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 14),

                // Section chips
                _secLabel('SECTION'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _sections
                      .map(
                        (s) => _selChip(
                          'Sec $s',
                          _pickerSection == s,
                          () => setState(() => _pickerSection = s),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),

                // Add button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _addAssignment,
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: AppColors.primary,
                    ),
                    label: const Text(
                      'Add Assignment',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),

                // Added chips list
                if (_assignments.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Divider(color: AppColors.bgSeparator),
                  const SizedBox(height: 10),
                  _secLabel('ADDED'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _assignments
                        .map(
                          (a) => Chip(
                            label: Text(
                              '${a['department']} · ${a['year']} · Sec ${a['section']}',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 12,
                              ),
                            ),
                            backgroundColor: AppColors.primary.withOpacity(
                              0.12,
                            ),
                            side: const BorderSide(color: AppColors.primary),
                            deleteIcon: const Icon(
                              Icons.close,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            onDeleted: () =>
                                setState(() => _assignments.remove(a)),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 28),

            // ── Update button ────────────────────────────────────
            SizedBox(
              height: 54,
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
                    : const Icon(Icons.save),
                label: Text(
                  _isLoading ? 'Updating...' : 'Update Faculty',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
