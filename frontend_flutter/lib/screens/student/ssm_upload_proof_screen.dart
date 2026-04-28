// File: lib/screens/student/ssm_upload_proof_screen.dart
// ─────────────────────────────────────────────────────────────────────────────
// SSM Upload Proof Screen
// Student picks image/PDF → uploads → sees OCR verification result instantly
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/api_service.dart';

class SSMUploadProofScreen extends StatefulWidget {
  final int submissionId;
  final String criterionKey;   // e.g. "2_1_nptel"
  final String criterionLabel; // e.g. "NPTEL / SWAYAM Certificate"

  // Existing proof (for replace flow)
  final Map<String, dynamic>? existingProof;

  const SSMUploadProofScreen({
    super.key,
    required this.submissionId,
    required this.criterionKey,
    required this.criterionLabel,
    this.existingProof,
  });

  @override
  State<SSMUploadProofScreen> createState() => _SSMUploadProofScreenState();
}

class _SSMUploadProofScreenState extends State<SSMUploadProofScreen> {
  File? _selectedFile;
  String? _fileName;
  String? _fileType;   // "image" | "pdf"
  String? _base64Data;

  bool _isUploading = false;
  Map<String, dynamic>? _verificationResult;
  String? _error;

  final ImagePicker _imagePicker = ImagePicker();

  // ── Color helpers ──────────────────────────────────────────────────────────
  Color _statusColor(String? status, ColorScheme cs) {
    switch (status) {
      case 'valid':   return const Color(0xFF2E7D32);
      case 'review':  return const Color(0xFFFF9800);
      case 'invalid': return cs.error;
      default:        return cs.onBackground.withOpacity(0.4);
    }
  }

  IconData _statusIcon(String? status) {
    switch (status) {
      case 'valid':   return Icons.check_circle_outline;
      case 'review':  return Icons.rate_review_outlined;
      case 'invalid': return Icons.cancel_outlined;
      default:        return Icons.upload_file_outlined;
    }
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'valid':   return '✓ Valid Certificate';
      case 'review':  return '⚠ Needs Manual Review';
      case 'invalid': return '✗ Invalid / Unclear';
      default:        return 'Not Verified';
    }
  }

  // ── Pick from Camera ───────────────────────────────────────────────────────
  Future<void> _pickFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (image == null) return;
      await _loadFile(File(image.path), image.name, "image");
    } catch (e) {
      _showError('Camera error: $e');
    }
  }

  // ── Pick from Gallery ──────────────────────────────────────────────────────
  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (image == null) return;
      await _loadFile(File(image.path), image.name, "image");
    } catch (e) {
      _showError('Gallery error: $e');
    }
  }

  // ── Pick PDF ───────────────────────────────────────────────────────────────
  Future<void> _pickPDF() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result == null || result.files.isEmpty) return;
      final file = File(result.files.single.path!);
      await _loadFile(file, result.files.single.name, "pdf");
    } catch (e) {
      _showError('File picker error: $e');
    }
  }

  Future<void> _loadFile(File file, String name, String type) async {
    final bytes = await file.readAsBytes();
    if (bytes.lengthInBytes > 5 * 1024 * 1024) {
      _showError('File too large. Max 5MB allowed.');
      return;
    }
    setState(() {
      _selectedFile = file;
      _fileName = name;
      _fileType = type;
      _base64Data = base64Encode(bytes);
      _verificationResult = null;
      _error = null;
    });
  }

  // ── Upload and Verify ──────────────────────────────────────────────────────
  Future<void> _uploadAndVerify() async {
    if (_base64Data == null || _fileName == null || _fileType == null) return;

    setState(() { _isUploading = true; _error = null; });

    try {
      final result = await ApiService.ssmUploadProof(
        submissionId: widget.submissionId,
        criterionKey: widget.criterionKey,
        fileName: _fileName!,
        fileType: _fileType!,
        fileData: _base64Data!,
      );

      setState(() {
        _verificationResult = result;
        _isUploading = false;
      });

    } catch (e) {
      setState(() {
        _error = e.toString();
        _isUploading = false;
      });
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  // ── UI ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasExisting = widget.existingProof != null;
    final existingStatus = widget.existingProof?['verification_status'] as String?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Proof'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Criterion label ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cs.primary.withOpacity(0.2)),
            ),
            child: Row(children: [
              Icon(Icons.upload_file_outlined, color: cs.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Proof for:', style: TextStyle(
                        color: cs.onBackground.withOpacity(0.5), fontSize: 12)),
                    Text(widget.criterionLabel,
                        style: TextStyle(color: cs.onBackground,
                            fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
              ),
            ]),
          ),

          const SizedBox(height: 20),

          // ── Existing proof status ─────────────────────────────────────────
          if (hasExisting && _verificationResult == null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _statusColor(existingStatus, cs).withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: _statusColor(existingStatus, cs).withOpacity(0.3)),
              ),
              child: Row(children: [
                Icon(_statusIcon(existingStatus),
                    color: _statusColor(existingStatus, cs), size: 22),
                const SizedBox(width: 10),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Current Proof: ${widget.existingProof!['file_name']}',
                        style: TextStyle(color: cs.onSurface,
                            fontWeight: FontWeight.w600, fontSize: 13)),
                    Text(_statusLabel(existingStatus),
                        style: TextStyle(
                            color: _statusColor(existingStatus, cs),
                            fontSize: 12)),
                  ],
                )),
              ]),
            ),
            const SizedBox(height: 8),
            Text('Upload a new file to replace the existing proof.',
                style: TextStyle(color: cs.onBackground.withOpacity(0.5),
                    fontSize: 12)),
            const SizedBox(height: 20),
          ],

          // ── File picker buttons ───────────────────────────────────────────
          Text('Select File', style: TextStyle(
              color: cs.onBackground,
              fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),

          Row(children: [
            Expanded(child: _pickButton(
              icon: Icons.camera_alt_outlined,
              label: 'Camera',
              color: const Color(0xFF1565C0),
              onTap: _pickFromCamera,
            )),
            const SizedBox(width: 10),
            Expanded(child: _pickButton(
              icon: Icons.photo_library_outlined,
              label: 'Gallery',
              color: const Color(0xFF2E7D32),
              onTap: _pickFromGallery,
            )),
            const SizedBox(width: 10),
            Expanded(child: _pickButton(
              icon: Icons.picture_as_pdf_outlined,
              label: 'PDF',
              color: const Color(0xFFC62828),
              onTap: _pickPDF,
            )),
          ]),

          const SizedBox(height: 20),

          // ── Selected file preview ─────────────────────────────────────────
          if (_selectedFile != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cs.onSurface.withOpacity(0.1)),
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (_fileType == 'pdf'
                        ? const Color(0xFFC62828)
                        : const Color(0xFF1565C0)).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _fileType == 'pdf'
                        ? Icons.picture_as_pdf_outlined
                        : Icons.image_outlined,
                    color: _fileType == 'pdf'
                        ? const Color(0xFFC62828)
                        : const Color(0xFF1565C0),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_fileName ?? '',
                          style: TextStyle(color: cs.onSurface,
                              fontWeight: FontWeight.w600, fontSize: 13),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      Text(
                        '${(_base64Data!.length * 3 / 4 / 1024).toStringAsFixed(1)} KB · ${_fileType?.toUpperCase()}',
                        style: TextStyle(
                            color: cs.onSurface.withOpacity(0.5), fontSize: 11)),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: cs.onSurface.withOpacity(0.4)),
                  onPressed: () => setState(() {
                    _selectedFile = null;
                    _fileName = null;
                    _fileType = null;
                    _base64Data = null;
                    _verificationResult = null;
                  }),
                ),
              ]),
            ),

            // Image preview (if image)
            if (_fileType == 'image') ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(
                  _selectedFile!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Upload button
            if (_verificationResult == null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isUploading ? null : _uploadAndVerify,
                  icon: _isUploading
                      ? const SizedBox(height: 18, width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.verified_outlined),
                  label: Text(_isUploading
                      ? 'Verifying certificate...'
                      : 'Upload & Verify'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
          ],

          // ── Error ─────────────────────────────────────────────────────────
          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.error.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.error.withOpacity(0.3)),
              ),
              child: Text(_error!,
                  style: TextStyle(color: cs.error, fontSize: 13)),
            ),
          ],

          // ── Verification Result ───────────────────────────────────────────
          if (_verificationResult != null) ...[
            const SizedBox(height: 20),
            _buildVerificationResult(cs),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.check),
                label: const Text('Done'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],

          // ── Tips ─────────────────────────────────────────────────────────
          const SizedBox(height: 24),
          _buildTips(cs),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _pickButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(
              color: color, fontWeight: FontWeight.w600, fontSize: 12)),
        ]),
      ),
    );
  }

  Widget _buildVerificationResult(ColorScheme cs) {
    final result = _verificationResult!;
    final status = result['verification_status'] as String? ?? 'review';
    final score = result['verification_score'] as int? ?? 0;
    final details = result['verification_details'] as String? ?? '';
    final checks = result['checks'] as Map<String, dynamic>? ?? {};
    final color = _statusColor(status, cs);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status header
          Row(children: [
            Icon(_statusIcon(status), color: color, size: 28),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Verification Result',
                    style: TextStyle(color: cs.onBackground.withOpacity(0.5),
                        fontSize: 11, fontWeight: FontWeight.bold,
                        letterSpacing: 0.8)),
                Text(_statusLabel(status),
                    style: TextStyle(color: color,
                        fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            )),
            // Score gauge
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Text('$score',
                  style: TextStyle(color: color,
                      fontWeight: FontWeight.bold, fontSize: 18)),
            ),
          ]),

          const SizedBox(height: 14),

          // Score bar
          LinearProgressIndicator(
            value: score / 100,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),

          const SizedBox(height: 14),

          // Checks
          _checkRow('Certificate keyword found', checks['has_cert_word'] == true, cs),
          _checkRow('Platform/Organization recognized', checks['has_platform'] == true, cs),
          _checkRow('Student name visible', checks['has_name'] == true, cs),
          _checkRow('Date present', checks['has_date'] == true, cs),
          _checkRow('Good text quality', checks['text_quality'] == 'good', cs),

          if (checks['found_platforms'] != null &&
              (checks['found_platforms'] as List).isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Recognized: ${(checks['found_platforms'] as List).join(', ')}',
                style: TextStyle(color: color.withOpacity(0.8),
                    fontSize: 12, fontStyle: FontStyle.italic)),
          ],

          const SizedBox(height: 12),

          // Summary
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(details.split(' | ').join('\n'),
                style: TextStyle(color: cs.onBackground.withOpacity(0.7),
                    fontSize: 12)),
          ),

          if (status == 'review') ...[
            const SizedBox(height: 10),
            Text(
              'ℹ This certificate will be manually reviewed by your mentor.',
              style: TextStyle(
                  color: const Color(0xFFFF9800).withOpacity(0.8), fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _checkRow(String label, bool passed, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Icon(
          passed ? Icons.check_circle_outline : Icons.radio_button_unchecked,
          size: 16,
          color: passed ? const Color(0xFF2E7D32) : cs.onBackground.withOpacity(0.3),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
              color: passed ? cs.onBackground : cs.onBackground.withOpacity(0.4),
              fontSize: 13,
            )),
      ]),
    );
  }

  Widget _buildTips(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.onSurface.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.tips_and_updates_outlined,
                color: const Color(0xFFFF9800), size: 18),
            const SizedBox(width: 8),
            Text('Tips for better verification',
                style: TextStyle(color: cs.onBackground,
                    fontWeight: FontWeight.bold, fontSize: 13)),
          ]),
          const SizedBox(height: 10),
          ...[
            'Upload the full certificate — not just a part of it',
            'Make sure your name is clearly visible',
            'Certificate should clearly show the platform/organization name',
            'For NPTEL: upload the e-certificate from the portal',
            'For internship: upload the completion certificate or offer letter',
            'Scan in good lighting — avoid glare and shadows',
            'PDF is preferred over photos for better OCR accuracy',
          ].map((tip) => Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyle(
                    color: cs.onBackground.withOpacity(0.5))),
                Expanded(child: Text(tip, style: TextStyle(
                    color: cs.onBackground.withOpacity(0.6), fontSize: 12))),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
