// File: lib/screens/student/ssm_form_screen.dart
// ─────────────────────────────────────────────────────────
// SSM Form Screen — student enters GPA + Attendance
// Creates a draft submission if none exists
// ─────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/session.dart';
import '../../models/ssm_models.dart';
import '../../services/api_service.dart';

class SSMFormScreen extends StatefulWidget {
  final SSMSubmission? submission; // null = create new

  const SSMFormScreen({super.key, this.submission});

  @override
  State<SSMFormScreen> createState() => _SSMFormScreenState();
}

class _SSMFormScreenState extends State<SSMFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _gpaController = TextEditingController();
  final _attendanceController = TextEditingController();

  bool _isSaving = false;
  double? _previewScore;
  int? _previewStars;

  @override
  void initState() {
    super.initState();
    // Pre-fill if editing
    if (widget.submission != null) {
      final sub = widget.submission!;
      if (sub.gpa != null) _gpaController.text = sub.gpa!.toString();
      if (sub.attendanceInput != null) {
        _attendanceController.text = sub.attendanceInput!.toString();
      }
    }

    // Listen for live preview
    _gpaController.addListener(_updatePreview);
    _attendanceController.addListener(_updatePreview);
  }

  void _updatePreview() {
    final gpa = double.tryParse(_gpaController.text);
    final att = double.tryParse(_attendanceController.text);
    if (gpa == null && att == null) {
      setState(() { _previewScore = null; _previewStars = null; });
      return;
    }

    double score = 0;
    // GPA points
    final g = gpa ?? 0;
    if (g >= 9.0) score += 15;
    else if (g >= 8.0) score += 10;
    else if (g >= 7.0) score += 5;

    // Attendance points
    final a = att ?? 0;
    if (a >= 90) score += 15;
    else if (a >= 75) score += 10;
    else if (a >= 60) score += 5;

    // Add existing activities score
    if (widget.submission != null) {
      for (final activity in widget.submission!.activities) {
        score += activity.score;
      }
    }

    score = score.clamp(0, 100);

    int stars;
    if (score >= 85) stars = 5;
    else if (score >= 70) stars = 4;
    else if (score >= 55) stars = 3;
    else if (score >= 40) stars = 2;
    else stars = 1;

    setState(() {
      _previewScore = score;
      _previewStars = stars;
    });
  }

  @override
  void dispose() {
    _gpaController.dispose();
    _attendanceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await ApiService.ssmSaveForm(
        studentId: SessionManager.studentId!,
        gpa: double.tryParse(_gpaController.text),
        attendanceInput: double.tryParse(_attendanceController.text),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Form saved successfully!'),
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
    final isEditing = widget.submission != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit SSM Form' : 'SSM Form'),
        centerTitle: false,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Intro card ──────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(0.07),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.primary.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: cs.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Enter your current academic data. '
                      'The system will calculate your score automatically.',
                      style: TextStyle(
                        color: cs.onBackground.withOpacity(0.7),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── GPA Field ────────────────────────────────────
            Text(
              'Academic GPA',
              style: TextStyle(
                color: cs.onBackground,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _gpaController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              decoration: InputDecoration(
                hintText: 'e.g. 8.5',
                prefixIcon: const Icon(Icons.school_outlined),
                helperText: '0.0 – 10.0  •  GPA ≥ 9 → 15 pts  |  ≥ 8 → 10 pts  |  ≥ 7 → 5 pts',
                helperStyle: TextStyle(fontSize: 11, color: cs.onBackground.withOpacity(0.5)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                filled: true,
                fillColor: cs.surface,
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'GPA is required';
                final val = double.tryParse(v);
                if (val == null) return 'Enter a valid number';
                if (val < 0 || val > 10) return 'GPA must be between 0 and 10';
                return null;
              },
            ),

            const SizedBox(height: 24),

            // ── Attendance Field ──────────────────────────────
            Text(
              'Attendance Percentage',
              style: TextStyle(
                color: cs.onBackground,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _attendanceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              decoration: InputDecoration(
                hintText: 'e.g. 85.5',
                prefixIcon: const Icon(Icons.how_to_reg_outlined),
                suffixText: '%',
                helperText: '0–100  •  ≥ 90% → 15 pts  |  ≥ 75% → 10 pts  |  ≥ 60% → 5 pts',
                helperStyle: TextStyle(fontSize: 11, color: cs.onBackground.withOpacity(0.5)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                filled: true,
                fillColor: cs.surface,
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return null; // attendance optional
                final val = double.tryParse(v);
                if (val == null) return 'Enter a valid number';
                if (val < 0 || val > 100) return 'Attendance must be 0–100';
                return null;
              },
            ),

            const SizedBox(height: 28),

            // ── Live Score Preview ────────────────────────────
            if (_previewScore != null) ...[
              _buildScorePreview(cs),
              const SizedBox(height: 28),
            ],

            // ── Scoring Guide ─────────────────────────────────
            _buildScoringGuide(cs),

            const SizedBox(height: 32),

            // ── Save Button ───────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Save & Continue',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildScorePreview(ColorScheme cs) {
    Color color;
    if (_previewScore! >= 85) color = const Color(0xFF4CAF50);
    else if (_previewScore! >= 70) color = const Color(0xFF2196F3);
    else if (_previewScore! >= 55) color = const Color(0xFFFF9800);
    else color = cs.error;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text('Live Score Preview',
              style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(
            '${_previewScore!.toStringAsFixed(1)} / 100',
            style: TextStyle(
              color: color,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) => Icon(
              i < (_previewStars ?? 0) ? Icons.star : Icons.star_border,
              color: color,
              size: 22,
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildScoringGuide(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.onSurface.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Scoring Guide',
            style: TextStyle(
              color: cs.onBackground,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          _guideRow(cs, 'GPA ≥ 9.0', '15 pts', const Color(0xFF4CAF50)),
          _guideRow(cs, 'GPA ≥ 8.0', '10 pts', const Color(0xFF4CAF50)),
          _guideRow(cs, 'GPA ≥ 7.0', '5 pts', const Color(0xFF4CAF50)),
          const Divider(height: 16),
          _guideRow(cs, 'Attendance ≥ 90%', '15 pts', const Color(0xFF2196F3)),
          _guideRow(cs, 'Attendance ≥ 75%', '10 pts', const Color(0xFF2196F3)),
          _guideRow(cs, 'Attendance ≥ 60%', '5 pts', const Color(0xFF2196F3)),
          const Divider(height: 16),
          _guideRow(cs, 'Internship (max 1)', '20 pts', const Color(0xFF9C27B0)),
          _guideRow(cs, 'Project (max 2)', '15 pts each', const Color(0xFF4CAF50)),
          _guideRow(cs, 'Certificates (≥3)', '15 pts bonus', const Color(0xFFFF9800)),
          _guideRow(cs, 'Certificates (1–2)', '5 pts each', const Color(0xFFFF9800)),
          _guideRow(cs, 'Achievement (max 5)', '3 pts each', const Color(0xFFFF5722)),
        ],
      ),
    );
  }

  Widget _guideRow(ColorScheme cs, String label, String pts, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: cs.onBackground.withOpacity(0.7), fontSize: 13)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(pts,
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
