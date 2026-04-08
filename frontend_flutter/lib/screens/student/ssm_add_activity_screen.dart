// File: lib/screens/student/ssm_add_activity_screen.dart
// ─────────────────────────────────────────────────────────
// Add Activity Screen — student adds internship / cert / project / achievement
// ─────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class SSMAddActivityScreen extends StatefulWidget {
  final int submissionId;

  const SSMAddActivityScreen({super.key, required this.submissionId});

  @override
  State<SSMAddActivityScreen> createState() => _SSMAddActivityScreenState();
}

class _SSMAddActivityScreenState extends State<SSMAddActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _durationController = TextEditingController();
  final _orgController = TextEditingController();

  String _selectedType = 'internship';
  bool _isSaving = false;

  static const _types = [
    {'value': 'internship',  'label': 'Internship',   'icon': Icons.work_outline,           'color': Color(0xFF9C27B0), 'pts': '+20 pts'},
    {'value': 'certificate', 'label': 'Certificate',  'icon': Icons.card_membership_outlined,'color': Color(0xFF2196F3), 'pts': '+5–15 pts'},
    {'value': 'project',     'label': 'Project',      'icon': Icons.code_outlined,           'color': Color(0xFF4CAF50), 'pts': '+15 pts'},
    {'value': 'achievement', 'label': 'Achievement',  'icon': Icons.emoji_events_outlined,   'color': Color(0xFFFF9800), 'pts': '+3 pts'},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _durationController.dispose();
    _orgController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await ApiService.ssmAddActivity(
        submissionId: widget.submissionId,
        type: _selectedType,
        title: _titleController.text.trim(),
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        duration: _durationController.text.trim().isEmpty
            ? null
            : _durationController.text.trim(),
        organization: _orgController.text.trim().isEmpty
            ? null
            : _orgController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Activity added!'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
        Navigator.pop(context);
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
        title: const Text('Add Activity'),
        centerTitle: false,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Type Selector ──────────────────────────────
            Text(
              'Activity Type',
              style: TextStyle(
                color: cs.onBackground,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.8,
              children: _types.map((t) {
                final val = t['value'] as String;
                final isSelected = _selectedType == val;
                final color = t['color'] as Color;
                final icon = t['icon'] as IconData;

                return GestureDetector(
                  onTap: () => setState(() => _selectedType = val),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? color : cs.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? color : cs.onSurface.withOpacity(0.12),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(icon, size: 18,
                            color: isSelected ? Colors.white : color),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                t['label'] as String,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : cs.onSurface,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                t['pts'] as String,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white.withOpacity(0.8)
                                      : color,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // ── Title ──────────────────────────────────────
            _buildField(
              cs,
              controller: _titleController,
              label: 'Title *',
              hint: _hintForType(),
              icon: Icons.title_outlined,
              required: true,
            ),

            const SizedBox(height: 16),

            // ── Organization ───────────────────────────────
            _buildField(
              cs,
              controller: _orgController,
              label: _orgLabelForType(),
              hint: _orgHintForType(),
              icon: Icons.business_outlined,
            ),

            const SizedBox(height: 16),

            // ── Duration ───────────────────────────────────
            _buildField(
              cs,
              controller: _durationController,
              label: 'Duration',
              hint: 'e.g. 3 months, Jan 2025 – Mar 2025',
              icon: Icons.schedule_outlined,
            ),

            const SizedBox(height: 16),

            // ── Description ────────────────────────────────
            TextFormField(
              controller: _descController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'Brief description of what you did...',
                prefixIcon: const Icon(Icons.notes_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                filled: true,
                fillColor: cs.surface,
              ),
            ),

            const SizedBox(height: 32),

            // ── Save Button ────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        height: 18, width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.add_circle_outline),
                label: Text(_isSaving ? 'Adding...' : 'Add Activity'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    ColorScheme cs, {
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool required = false,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        filled: true,
        fillColor: cs.surface,
      ),
      validator: required
          ? (v) {
              if (v == null || v.trim().isEmpty) return '$label is required';
              return null;
            }
          : null,
    );
  }

  String _hintForType() {
    switch (_selectedType) {
      case 'internship':   return 'e.g. Software Intern at TCS';
      case 'certificate':  return 'e.g. Python for Data Science — Coursera';
      case 'project':      return 'e.g. Smart Campus Assistant App';
      case 'achievement':  return 'e.g. 1st Place — National Hackathon';
      default:             return 'Enter title';
    }
  }

  String _orgLabelForType() {
    switch (_selectedType) {
      case 'internship':   return 'Company / Organization';
      case 'certificate':  return 'Platform / Institution';
      case 'project':      return 'Team / Organization (optional)';
      case 'achievement':  return 'Event / Organization';
      default:             return 'Organization';
    }
  }

  String _orgHintForType() {
    switch (_selectedType) {
      case 'internship':   return 'e.g. TCS, Infosys, Startup...';
      case 'certificate':  return 'e.g. Coursera, NPTEL, Google...';
      case 'project':      return 'e.g. Personal, College, Client...';
      case 'achievement':  return 'e.g. ISTE, IEEE, College...';
      default:             return '';
    }
  }
}
