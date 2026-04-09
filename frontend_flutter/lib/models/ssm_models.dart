// File: lib/models/ssm_models.dart
// SSM — Student Success Matrix (500 pts total)

class SSMSubmission {
  final int id;
  final int studentId;
  final double totalScore; // 0–500
  final int starRating; // 0–5
  final String status;
  final Map<String, dynamic> scoreBreakdown;
  final Map<String, dynamic> formData;
  final String? submittedAt;
  final List<SSMReview> reviews;

  const SSMSubmission({
    required this.id,
    required this.studentId,
    required this.totalScore,
    required this.starRating,
    required this.status,
    required this.scoreBreakdown,
    required this.formData,
    this.submittedAt,
    required this.reviews,
  });

  factory SSMSubmission.fromJson(Map<String, dynamic> json) => SSMSubmission(
        id: json['id'],
        studentId: json['student_id'],
        totalScore: (json['total_score'] as num?)?.toDouble() ?? 0.0,
        starRating: json['star_rating'] ?? 0,
        status: json['status'] ?? 'draft',
        scoreBreakdown:
            Map<String, dynamic>.from(json['score_breakdown'] ?? {}),
        formData: Map<String, dynamic>.from(json['form_data'] ?? {}),
        submittedAt: json['submitted_at'],
        reviews: (json['reviews'] as List? ?? [])
            .map((e) => SSMReview.fromJson(e))
            .toList(),
      );

  String get statusLabel {
    switch (status) {
      case 'draft':
        return 'Draft';
      case 'submitted':
        return 'Pending Mentor Review';
      case 'mentor_approved':
        return 'Mentor Approved — Pending HOD';
      case 'mentor_rejected':
        return 'Mentor Rejected';
      case 'hod_approved':
        return '✓ Final Score Locked';
      case 'hod_rejected':
        return 'HOD Rejected';
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

  // Category subtotals from breakdown
  int get cat1 => (scoreBreakdown['_summary']?['cat1'] as num?)?.toInt() ?? 0;
  int get cat2 => (scoreBreakdown['_summary']?['cat2'] as num?)?.toInt() ?? 0;
  int get cat3 => (scoreBreakdown['_summary']?['cat3'] as num?)?.toInt() ?? 0;
  int get cat4 => (scoreBreakdown['_summary']?['cat4'] as num?)?.toInt() ?? 0;
  int get cat5 => (scoreBreakdown['_summary']?['cat5'] as num?)?.toInt() ?? 0;

  bool get canEdit => status == 'draft' || status == 'mentor_rejected';
  bool get isFinal => status == 'hod_approved';
}

class SSMReview {
  final int id;
  final String reviewerRole;
  final String? reviewerName;
  final String status;
  final String? remarks;
  final String? reviewedAt;

  const SSMReview(
      {required this.id,
      required this.reviewerRole,
      this.reviewerName,
      required this.status,
      this.remarks,
      this.reviewedAt});

  factory SSMReview.fromJson(Map<String, dynamic> json) => SSMReview(
        id: json['id'],
        reviewerRole: json['reviewer_role'] ?? '',
        reviewerName: json['reviewer_name'],
        status: json['status'] ?? '',
        remarks: json['remarks'],
        reviewedAt: json['reviewed_at'],
      );
}
