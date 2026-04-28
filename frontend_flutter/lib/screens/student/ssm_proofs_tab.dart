// File: lib/screens/student/ssm_proofs_tab.dart
// ─────────────────────────────────────────────────────────────────────────────
// SSM Proofs Tab — shown inside SSM form / result screen
// Lists all proofs, upload status, and lets student add/replace proofs
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'ssm_upload_proof_screen.dart';

class SSMProofsTab extends StatefulWidget {
  final int submissionId;
  final bool canEdit; // false if submitted/approved

  const SSMProofsTab({
    super.key,
    required this.submissionId,
    required this.canEdit,
  });

  @override
  State<SSMProofsTab> createState() => _SSMProofsTabState();
}

class _SSMProofsTabState extends State<SSMProofsTab> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _proofs = [];
  String? _error;

  // Criteria that require proof uploads — key → label
  static const Map<String, String> _proofCriteria = {
    '2_1_nptel':          'NPTEL / SWAYAM Certificate',
    '2_2_online_cert':    'Industry Online Certification',
    '2_3_internship':     'Internship / In-plant Certificate',
    '2_4_competition':    'Competition / Hackathon Certificate',
    '2_5_publication':    'Publication / Patent Document',
    '1_6_project':        'Project Completion Certificate',
    '2_6_skill_programs': 'Skill Program Certificate',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await ApiService.ssmGetProofs(widget.submissionId);
      if (mounted) setState(() {
        _proofs = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Build a map of existing proofs by criterion key
    final proofMap = <String, Map<String, dynamic>>{};
    for (final p in _proofs) {
      proofMap[p['criterion_key'] as String] = p;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Proof Documents'),
        centerTitle: false,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: cs.primary))
          : _error != null
              ? _buildError(cs)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.primary.withOpacity(0.2)),
            ),
            child: Row(children: [
              Icon(Icons.folder_open_outlined, color: cs.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(
                'Upload proof certificates for each activity. '
                'System will auto-verify using OCR.',
                style: TextStyle(
                    color: cs.onBackground.withOpacity(0.65), fontSize: 12),
              )),
            ]),
          ),

          // ── Summary stats ─────────────────────────────────────────────────
          if (_proofs.isNotEmpty) ...[
            _buildSummaryRow(cs),
            const SizedBox(height: 16),
          ],

          // ── Criteria list ─────────────────────────────────────────────────
          ..._proofCriteria.entries.map((entry) {
            final key = entry.key;
            final label = entry.value;
            final existing = proofMap[key];
            return _buildCriterionCard(key, label, existing, cs);
          }),

          const SizedBox(height: 40),
        ],
      ),
    ),
    );
  }

  Widget _buildSummaryRow(ColorScheme cs) {
    final total = _proofCriteria.length;
    final uploaded = _proofs.length;
    final valid   = _proofs.where((p) => p['verification_status'] == 'valid').length;
    final review  = _proofs.where((p) => p['verification_status'] == 'review').length;
    final invalid = _proofs.where((p) => p['verification_status'] == 'invalid').length;

    return Row(children: [
      _summaryChip('$uploaded/$total', 'Uploaded', cs.primary, cs),
      const SizedBox(width: 8),
      _summaryChip('$valid', 'Valid', const Color(0xFF2E7D32), cs),
      const SizedBox(width: 8),
      _summaryChip('$review', 'Review', const Color(0xFFFF9800), cs),
      const SizedBox(width: 8),
      _summaryChip('$invalid', 'Invalid', cs.error, cs),
    ]);
  }

  Widget _summaryChip(String value, String label, Color color, ColorScheme cs) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(children: [
          Text(value, style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 16)),
          Text(label, style: TextStyle(
              color: cs.onBackground.withOpacity(0.5), fontSize: 10)),
        ]),
      ),
    );
  }

  Widget _buildCriterionCard(
    String key,
    String label,
    Map<String, dynamic>? existing,
    ColorScheme cs,
  ) {
    final hasProof = existing != null;
    final status = existing?['verification_status'] as String?;

    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (!hasProof) {
      statusColor = cs.onBackground.withOpacity(0.3);
      statusIcon = Icons.upload_outlined;
      statusText = 'Not uploaded';
    } else {
      switch (status) {
        case 'valid':
          statusColor = const Color(0xFF2E7D32);
          statusIcon = Icons.check_circle_outline;
          statusText = '✓ Valid';
          break;
        case 'review':
          statusColor = const Color(0xFFFF9800);
          statusIcon = Icons.rate_review_outlined;
          statusText = '⚠ Needs Review';
          break;
        case 'invalid':
          statusColor = cs.error;
          statusIcon = Icons.cancel_outlined;
          statusText = '✗ Invalid';
          break;
        default:
          statusColor = cs.onBackground.withOpacity(0.4);
          statusIcon = Icons.hourglass_empty;
          statusText = 'Pending';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasProof
              ? statusColor.withOpacity(0.3)
              : cs.onSurface.withOpacity(0.08),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              // Status icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(statusIcon, color: statusColor, size: 20),
              ),
              const SizedBox(width: 12),
              // Label + status
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(
                      color: cs.onSurface, fontWeight: FontWeight.w600,
                      fontSize: 13)),
                  const SizedBox(height: 2),
                  Row(children: [
                    Text(statusText, style: TextStyle(
                        color: statusColor, fontSize: 12)),
                    if (hasProof) ...[
                      Text(' · ', style: TextStyle(
                          color: cs.onSurface.withOpacity(0.3))),
                      Text(
                        existing!['file_name'] as String? ?? '',
                        style: TextStyle(
                            color: cs.onSurface.withOpacity(0.4),
                            fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ]),
                ],
              )),
              // Score badge (if verified)
              if (hasProof && existing!['verification_score'] != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${existing['verification_score']}',
                    style: TextStyle(
                        color: statusColor, fontWeight: FontWeight.bold,
                        fontSize: 13)),
                ),
                const SizedBox(width: 8),
              ],
              // Upload / Replace button
              if (widget.canEdit)
                GestureDetector(
                  onTap: () => _openUpload(key, label, existing),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: cs.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      hasProof ? 'Replace' : 'Upload',
                      style: TextStyle(
                          color: cs.primary, fontWeight: FontWeight.bold,
                          fontSize: 12),
                    ),
                  ),
                ),
            ]),
          ),

          // Verification details (expandable)
          if (hasProof && existing!['verification_details'] != null &&
              (existing['verification_details'] as String).isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  existing['verification_details'] as String,
                  style: TextStyle(
                      color: cs.onBackground.withOpacity(0.55), fontSize: 11),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _openUpload(String key, String label,
      Map<String, dynamic>? existing) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => SSMUploadProofScreen(
          submissionId: widget.submissionId,
          criterionKey: key,
          criterionLabel: label,
          existingProof: existing,
        ),
      ),
    );
    if (result == true) _load(); // reload proofs
  }

  Widget _buildError(ColorScheme cs) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.cloud_off, size: 50, color: cs.error.withOpacity(0.4)),
        const SizedBox(height: 16),
        Text(_error!, style: TextStyle(color: cs.onBackground.withOpacity(0.6))),
        const SizedBox(height: 20),
        ElevatedButton(onPressed: _load, child: const Text('Retry')),
      ]),
    );
  }
}
