// File: lib/models/ssm_models.dart

class SSMSubmission {
  final int id;
  final int studentId;
  final double totalScore;
  final int starRating;
  final String status;
  final Map<String, dynamic> scoreBreakdown;
  final List<SSMEntry> entries;
  final Map<String, dynamic>? mentorInput;
  final List<SSMReview> reviews;
  final String? submittedAt;
  final String? updatedAt;

  const SSMSubmission({
    required this.id,
    required this.studentId,
    required this.totalScore,
    required this.starRating,
    required this.status,
    required this.scoreBreakdown,
    required this.entries,
    this.mentorInput,
    required this.reviews,
    this.submittedAt,
    this.updatedAt,
  });

  factory SSMSubmission.fromJson(Map<String, dynamic> json) => SSMSubmission(
        id: json['id'],
        studentId: json['student_id'],
        totalScore: (json['total_score'] as num?)?.toDouble() ?? 0.0,
        starRating: json['star_rating'] ?? 0,
        status: json['status'] ?? 'active',
        scoreBreakdown:
            Map<String, dynamic>.from(json['score_breakdown'] ?? {}),
        entries: (json['entries'] as List? ?? [])
            .map((e) => SSMEntry.fromJson(e))
            .toList(),
        mentorInput: json['mentor_input'] as Map<String, dynamic>?,
        reviews: (json['reviews'] as List? ?? [])
            .map((r) => SSMReview.fromJson(r))
            .toList(),
        submittedAt: json['submitted_at'],
        updatedAt: json['updated_at'],
      );

  String get statusLabel {
    switch (status) {
      case 'active':
        return 'Active — Add activities anytime';
      case 'submitted':
        return 'Submitted — Pending Mentor Review';
      case 'mentor_approved':
        return 'Mentor Approved — Pending HOD';
      case 'hod_approved':
        return '✓ Final Score Locked';
      default:
        return status;
    }
  }

  String get categoryLabel {
    if (starRating >= 5) return 'Excellent';
    if (starRating >= 4) return 'Very Good';
    if (starRating >= 3) return 'Good';
    if (starRating >= 2) return 'Average';
    if (starRating >= 1) return 'Below Average';
    return 'Not Rated Yet';
  }

  int get cat1 => (scoreBreakdown['cat1'] as num?)?.toInt() ?? 0;
  int get cat2 => (scoreBreakdown['cat2'] as num?)?.toInt() ?? 0;
  int get cat3 => (scoreBreakdown['cat3'] as num?)?.toInt() ?? 0;
  int get cat4 => (scoreBreakdown['cat4'] as num?)?.toInt() ?? 0;
  int get cat5 => (scoreBreakdown['cat5'] as num?)?.toInt() ?? 0;

  bool get canEdit => status != 'hod_approved';
  bool get isFinal => status == 'hod_approved';
  bool get canSubmit => status == 'active' && entries.isNotEmpty;
}

class SSMEntry {
  final int id;
  final int submissionId;
  final int category;
  final String entryType;
  final String entryLabel;
  final Map<String, dynamic> details;
  final double score;
  final int? proofId;
  final bool proofRequired;
  final String proofStatus;
  final String entryStatus;
  final String? addedAt;

  const SSMEntry({
    required this.id,
    required this.submissionId,
    required this.category,
    required this.entryType,
    required this.entryLabel,
    required this.details,
    required this.score,
    this.proofId,
    required this.proofRequired,
    required this.proofStatus,
    required this.entryStatus,
    this.addedAt,
  });

  factory SSMEntry.fromJson(Map<String, dynamic> json) => SSMEntry(
        id: json['id'],
        submissionId: json['submission_id'],
        category: json['category'] ?? 1,
        entryType: json['entry_type'] ?? '',
        entryLabel: json['entry_label'] ?? json['entry_type'] ?? '',
        details: Map<String, dynamic>.from(json['details'] ?? {}),
        score: (json['score'] as num?)?.toDouble() ?? 0.0,
        proofId: json['proof_id'] as int?,
        proofRequired:
            json['proof_required'] == true || json['proof_required'] == 1,
        proofStatus: json['proof_status'] ?? 'pending',
        entryStatus: json['entry_status'] ?? 'pending_proof',
        addedAt: json['added_at'],
      );
}

class SSMReview {
  final int id;
  final String reviewerRole;
  final String? reviewerName;
  final String status;
  final String? remarks;
  final String? reviewedAt;

  const SSMReview({
    required this.id,
    required this.reviewerRole,
    this.reviewerName,
    required this.status,
    this.remarks,
    this.reviewedAt,
  });

  factory SSMReview.fromJson(Map<String, dynamic> json) => SSMReview(
        id: json['id'],
        reviewerRole: json['reviewer_role'] ?? '',
        reviewerName: json['reviewer_name'],
        status: json['status'] ?? '',
        remarks: json['remarks'],
        reviewedAt: json['reviewed_at'],
      );
}
