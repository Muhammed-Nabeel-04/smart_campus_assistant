import 'package:flutter/material.dart';

class AttendanceSession {
  final int? id;
  final int classId;
  final int subjectId;
  final int facultyId;
  final String semester;
  final DateTime startTime;
  final DateTime endTime;
  final String status; // 'active', 'completed', 'cancelled'
  final int? totalPresent;
  final int? totalAbsent;

  AttendanceSession({
    this.id,
    required this.classId,
    required this.subjectId,
    required this.facultyId,
    required this.semester,
    required this.startTime,
    required this.endTime,
    this.status = 'active',
    this.totalPresent,
    this.totalAbsent,
  });

  factory AttendanceSession.fromJson(Map<String, dynamic> json) {
    return AttendanceSession(
      id: json['id'],
      classId: json['class_id'],
      subjectId: json['subject_id'],
      facultyId: json['faculty_id'],
      semester: json['semester'] ?? '',
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      status: json['status'] ?? 'active',
      totalPresent: json['total_present'],
      totalAbsent: json['total_absent'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'class_id': classId,
    'subject_id': subjectId,
    'faculty_id': facultyId,
    'semester': semester,
    'start_time': startTime.toIso8601String(),
    'end_time': endTime.toIso8601String(),
    'status': status,
    'total_present': totalPresent,
    'total_absent': totalAbsent,
  };
}

class AttendanceRecord {
  final int? id;
  final int sessionId;
  final int studentId;
  final String status; // 'present', 'absent', 'late'
  final DateTime timestamp;
  final String? remarks;

  AttendanceRecord({
    this.id,
    required this.sessionId,
    required this.studentId,
    required this.status,
    required this.timestamp,
    this.remarks,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'],
      sessionId: json['session_id'],
      studentId: json['student_id'],
      status: json['status'] ?? 'absent',
      timestamp: DateTime.parse(json['timestamp']),
      remarks: json['remarks'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'session_id': sessionId,
    'student_id': studentId,
    'status': status,
    'timestamp': timestamp.toIso8601String(),
    'remarks': remarks,
  };
}

// ============================================================================
// ACADEMIC STRUCTURE (With Semester Support)
// ============================================================================

class Department {
  final int? id;
  final String name;
  final String code;
  final String? hodName;
  final int totalYears;

  Department({
    this.id,
    required this.name,
    required this.code,
    this.hodName,
    this.totalYears = 4,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id'],
      name: json['name'],
      code: json['code'],
      hodName: json['hod_name'],
      totalYears: json['total_years'] ?? 4,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'code': code,
    'hod_name': hodName,
    'total_years': totalYears,
  };
}

class ClassModel {
  final int? id;
  final int departmentId;
  final String year; // "1st Year", "2nd Year", etc.
  final String section; // "A", "B", "C"
  final String currentSemester; // "Semester 1", "Semester 2", etc.
  final int? totalStudents;

  ClassModel({
    this.id,
    required this.departmentId,
    required this.year,
    required this.section,
    required this.currentSemester,
    this.totalStudents,
  });

  String get displayName => '$year - Section $section';
  String get fullName => '$year - Section $section ($currentSemester)';

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      id: json['id'],
      departmentId: json['department_id'],
      year: json['year'],
      section: json['section'],
      currentSemester: json['current_semester'],
      totalStudents: json['total_students'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'department_id': departmentId,
    'year': year,
    'section': section,
    'current_semester': currentSemester,
    'total_students': totalStudents,
  };
}

class Subject {
  final int? id;
  final String name;
  final String code;
  final int departmentId;
  final String year;
  final String semester; // Which semester this subject belongs to
  final int credits;
  final String type; // 'Theory', 'Lab', 'Project'

  Subject({
    this.id,
    required this.name,
    required this.code,
    required this.departmentId,
    required this.year,
    required this.semester,
    this.credits = 3,
    this.type = 'Theory',
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'],
      name: json['name'],
      code: json['code'],
      departmentId: json['department_id'],
      year: json['year'],
      semester: json['semester'],
      credits: json['credits'] ?? 3,
      type: json['type'] ?? 'Theory',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'code': code,
    'department_id': departmentId,
    'year': year,
    'semester': semester,
    'credits': credits,
    'type': type,
  };
}

class ClassSubject {
  final int? id;
  final int classId;
  final int subjectId;
  final String semester;
  final bool isActive;

  ClassSubject({
    this.id,
    required this.classId,
    required this.subjectId,
    required this.semester,
    this.isActive = true,
  });

  factory ClassSubject.fromJson(Map<String, dynamic> json) {
    return ClassSubject(
      id: json['id'],
      classId: json['class_id'],
      subjectId: json['subject_id'],
      semester: json['semester'],
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'class_id': classId,
    'subject_id': subjectId,
    'semester': semester,
    'is_active': isActive,
  };
}

class ClassSubjectFaculty {
  final int? id;
  final int classSubjectId;
  final int facultyId;
  final String assignedDate;
  final bool isActive;

  ClassSubjectFaculty({
    this.id,
    required this.classSubjectId,
    required this.facultyId,
    required this.assignedDate,
    this.isActive = true,
  });

  factory ClassSubjectFaculty.fromJson(Map<String, dynamic> json) {
    return ClassSubjectFaculty(
      id: json['id'],
      classSubjectId: json['class_subject_id'],
      facultyId: json['faculty_id'],
      assignedDate: json['assigned_date'],
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'class_subject_id': classSubjectId,
    'faculty_id': facultyId,
    'assigned_date': assignedDate,
    'is_active': isActive,
  };
}

// ============================================================================
// ONBOARDING TOKENS (With Expiry & Usage Tracking)
// ============================================================================

class OnboardingToken {
  final int? id;
  final String token;
  final String role; // 'student', 'faculty', 'admin'
  final int? targetId; // For student-specific QR, store student_id
  final DateTime expiryTime;
  final bool used;
  final DateTime? usedAt;
  final int? usedBy;
  final DateTime createdAt;

  OnboardingToken({
    this.id,
    required this.token,
    required this.role,
    this.targetId,
    required this.expiryTime,
    this.used = false,
    this.usedAt,
    this.usedBy,
    required this.createdAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiryTime);
  bool get isValid => !used && !isExpired;

  factory OnboardingToken.fromJson(Map<String, dynamic> json) {
    return OnboardingToken(
      id: json['id'],
      token: json['token'],
      role: json['role'],
      targetId: json['target_id'],
      expiryTime: DateTime.parse(json['expiry_time']),
      used: json['used'] ?? false,
      usedAt: json['used_at'] != null ? DateTime.parse(json['used_at']) : null,
      usedBy: json['used_by'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'token': token,
    'role': role,
    'target_id': targetId,
    'expiry_time': expiryTime.toIso8601String(),
    'used': used,
    'used_at': usedAt?.toIso8601String(),
    'used_by': usedBy,
    'created_at': createdAt.toIso8601String(),
  };
}

// ============================================================================
// COMPLAINT SYSTEM (With Status Tracking)
// ============================================================================

class Complaint {
  final int? id;
  final int studentId;
  final String category; // 'Academic', 'Infrastructure', 'Hostel', 'Other'
  final String priority; // 'Low', 'Medium', 'High', 'Critical'
  final String title;
  final String description;
  final String status; // 'pending', 'in_progress', 'resolved', 'rejected'
  final String? adminResponse;
  final int? handledBy; // Admin ID who handled it
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;

  Complaint({
    this.id,
    required this.studentId,
    required this.category,
    required this.priority,
    required this.title,
    required this.description,
    this.status = 'pending',
    this.adminResponse,
    this.handledBy,
    required this.createdAt,
    this.updatedAt,
    this.resolvedAt,
  });

  String get statusDisplay {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'in_progress':
        return 'In Progress';
      case 'resolved':
        return 'Resolved';
      case 'rejected':
        return 'Rejected';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'pending':
        return const Color(0xFFFFA726);
      case 'in_progress':
        return const Color(0xFF42A5F5);
      case 'resolved':
        return const Color(0xFF66BB6A);
      case 'rejected':
        return const Color(0xFFEF5350);
      default:
        return Colors.grey;
    }
  }

  factory Complaint.fromJson(Map<String, dynamic> json) {
    return Complaint(
      id: json['id'],
      studentId: json['student_id'],
      category: json['category'],
      priority: json['priority'],
      title: json['title'],
      description: json['description'],
      status: json['status'] ?? 'pending',
      adminResponse: json['admin_response'],
      handledBy: json['handled_by'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'student_id': studentId,
    'category': category,
    'priority': priority,
    'title': title,
    'description': description,
    'status': status,
    'admin_response': adminResponse,
    'handled_by': handledBy,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
    'resolved_at': resolvedAt?.toIso8601String(),
  };
}

// ============================================================================
// NOTIFICATION SYSTEM (With Targeting)
// ============================================================================

class CampusNotification {
  final int? id;
  final String title;
  final String message;
  final String targetRole;
  final int? targetClassId;
  final int? targetDepartmentId;
  final String type;
  final int sentBy;
  final DateTime createdAt;
  final DateTime? expiresAt;

  CampusNotification({
    // ✅ fixed
    this.id,
    required this.title,
    required this.message,
    this.targetRole = 'all',
    this.targetClassId,
    this.targetDepartmentId,
    this.type = 'info',
    required this.sentBy,
    required this.createdAt,
    this.expiresAt,
  });

  factory CampusNotification.fromJson(Map<String, dynamic> json) {
    // ✅ fixed
    return CampusNotification(
      // ✅ fixed
      id: json['id'],
      title: json['title'],
      message: json['message'],
      targetRole: json['target_role'] ?? 'all',
      targetClassId: json['target_class_id'],
      targetDepartmentId: json['target_department_id'],
      type: json['type'] ?? 'info',
      sentBy: json['sent_by'],
      createdAt: DateTime.parse(json['created_at']),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'message': message,
    'target_role': targetRole,
    'target_class_id': targetClassId,
    'target_department_id': targetDepartmentId,
    'type': type,
    'sent_by': sentBy,
    'created_at': createdAt.toIso8601String(),
    'expires_at': expiresAt?.toIso8601String(),
  };
}
