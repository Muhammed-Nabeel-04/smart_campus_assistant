// File: lib/models/ssm_models.dart
// ─────────────────────────────────────────────────────────
// SSM (Performance Module) — Dart model classes
// ─────────────────────────────────────────────────────────

class SSMSubmission {
  final int id;
  final int studentId;
  final double? gpa;
  final double? attendanceInput;
  final double totalScore;
  final int starRating;
  final String status;
  final Map<String, dynamic> scoreBreakdown;
  final String? submittedAt;
  final String? updatedAt;
  final List<SSMActivity> activities;
  final List<SSMReview> reviews;

  const SSMSubmission({
    required this.id,
    required this.studentId,
    this.gpa,
    this.attendanceInput,
    required this.totalScore,
    required this.starRating,
    required this.status,
    required this.scoreBreakdown,
    this.submittedAt,
    this.updatedAt,
    required this.activities,
    required this.reviews,
  });

  factory SSMSubmission.fromJson(Map<String, dynamic> json) {
    return SSMSubmission(
      id: json['id'],
      studentId: json['student_id'],
      gpa: (json['gpa'] as num?)?.toDouble(),
      attendanceInput: (json['attendance_input'] as num?)?.toDouble(),
      totalScore: (json['total_score'] as num?)?.toDouble() ?? 0.0,
      starRating: json['star_rating'] ?? 0,
      status: json['status'] ?? 'draft',
      scoreBreakdown: Map<String, dynamic>.from(json['score_breakdown'] ?? {}),
      submittedAt: json['submitted_at'],
      updatedAt: json['updated_at'],
      activities: (json['activities'] as List? ?? [])
          .map((e) => SSMActivity.fromJson(e))
          .toList(),
      reviews: (json['reviews'] as List? ?? [])
          .map((e) => SSMReview.fromJson(e))
          .toList(),
    );
  }

  String get statusLabel {
    switch (status) {
      case 'draft':             return 'Draft';
      case 'submitted':         return 'Pending Mentor Review';
      case 'mentor_approved':   return 'Mentor Approved';
      case 'mentor_rejected':   return 'Mentor Rejected';
      case 'hod_approved':      return 'Final Approved ✓';
      case 'hod_rejected':      return 'HOD Rejected';
      default:                  return status;
    }
  }

  String get categoryLabel {
    if (starRating >= 5) return 'Excellent';
    if (starRating >= 4) return 'Very Good';
    if (starRating >= 3) return 'Good';
    if (starRating >= 2) return 'Average';
    return 'Needs Improvement';
  }

  bool get canEdit =>
      status == 'draft' || status == 'mentor_rejected';

  bool get canSubmit =>
      status == 'draft' || status == 'mentor_rejected';

  bool get isFinal => status == 'hod_approved';
}


class SSMActivity {
  final int id;
  final int submissionId;
  final String type;
  final String title;
  final String? description;
  final String? duration;
  final String? organization;
  final double score;
  final String? proofFileName;
  final bool hasProof;

  const SSMActivity({
    required this.id,
    required this.submissionId,
    required this.type,
    required this.title,
    this.description,
    this.duration,
    this.organization,
    required this.score,
    this.proofFileName,
    required this.hasProof,
  });

  factory SSMActivity.fromJson(Map<String, dynamic> json) {
    return SSMActivity(
      id: json['id'],
      submissionId: json['submission_id'],
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      duration: json['duration'],
      organization: json['organization'],
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      proofFileName: json['proof_file_name'],
      hasProof: json['has_proof'] ?? false,
    );
  }

  String get typeLabel {
    switch (type) {
      case 'internship':    return 'Internship';
      case 'certificate':   return 'Certificate';
      case 'project':       return 'Project';
      case 'achievement':   return 'Achievement';
      default:              return type;
    }
  }
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

  factory SSMReview.fromJson(Map<String, dynamic> json) {
    return SSMReview(
      id: json['id'],
      reviewerRole: json['reviewer_role'] ?? '',
      reviewerName: json['reviewer_name'],
      status: json['status'] ?? '',
      remarks: json['remarks'],
      reviewedAt: json['reviewed_at'],
    );
  }
}
