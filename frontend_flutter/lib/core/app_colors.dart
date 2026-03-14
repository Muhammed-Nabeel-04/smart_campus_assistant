// lib/core/app_colors.dart
// ════════════════════════════════════════════════════════════════
//  SINGLE SOURCE OF TRUTH FOR ALL COLORS IN SMART CAMPUS APP
//  Import this wherever you need a color instead of hardcoding hex
// ════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

class AppColors {
  AppColors._(); // Prevent instantiation

  // ── Backgrounds ──────────────────────────────────────────────
  static const Color bgDark = Color(0xFF0F1419); // Main scaffold bg
  static const Color bgCard = Color(0xFF1A2332); // Cards, appbar, bottom nav
  static const Color bgElevated = Color(0xFF243044); // Slightly lighter card
  static const Color bgInput = Color(0xFF1A2332); // Text field fill
  static const Color bgSeparator = Color(
    0xFF2A3A4A,
  ); // Dividers / progress track

  // ── Brand Accent (Cyan) ───────────────────────────────────────
  static const Color primary = Color(0xFF00D9FF); // Main cyan accent
  static const Color primaryDark = Color(
    0xFF0099CC,
  ); // Darker cyan (gradient end)
  static const Color primaryFg = Color(0xFF0F1419); // Text ON primary buttons

  // ── Semantic Status ───────────────────────────────────────────
  static const Color success = Color(0xFF4CAF50);
  static const Color successDark = Color(0xFF66BB6A);
  static const Color warning = Color(0xFFFF9800);
  static const Color warningMid = Color(0xFFFFC107);
  static const Color danger = Color(0xFFFF6B6B);
  static const Color dangerDark = Color(0xFFEE5A6F);
  static const Color info = Color(0xFF2196F3);
  static const Color urgent = Color(0xFFFF5722);
  static const Color amber = Color(0xFFFFC107);

  // ── Text ─────────────────────────────────────────────────────
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF90A4AE); // ~60 % white
  static const Color textHint = Color(0xFF546E7A); // ~40 % white
  static const Color textAccent = Color(0xFF00D9FF); // Cyan label / link

  // ── Complaint Status ─────────────────────────────────────────
  static const Color statusPending = Color(0xFFFFA726);
  static const Color statusInProgress = Color(0xFF42A5F5);
  static const Color statusResolved = Color(0xFF66BB6A);
  static const Color statusRejected = Color(0xFFEF5350);

  // ── Priority ─────────────────────────────────────────────────
  static const Color priorityCritical = Color(0xFFFF5722);
  static const Color priorityHigh = Color(0xFFFF9800);
  static const Color priorityMedium = Color(0xFFFFC107);
  static const Color priorityLow = Color(0xFF4CAF50);

  // ── Gradients ────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient dangerGradient = LinearGradient(
    colors: [danger, dangerDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Deep navy card gradient (used in QR overlays)
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF16213E), Color(0xFF0F3460)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Helper Methods ────────────────────────────────────────────

  /// Cyan if attendance ≥ 75 %, red otherwise
  static Color attendanceColor(double pct) => pct >= 75 ? primary : danger;

  /// Color for a notification type string
  static Color notificationColor(String type) {
    switch (type) {
      case 'info':
        return info;
      case 'warning':
        return warning;
      case 'urgent':
        return urgent;
      case 'announcement':
        return primary;
      default:
        return textSecondary;
    }
  }

  /// Color for a priority string
  static Color priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'critical':
        return priorityCritical;
      case 'high':
        return priorityHigh;
      case 'medium':
        return priorityMedium;
      case 'low':
        return priorityLow;
      default:
        return textSecondary;
    }
  }

  /// Color for a complaint status string
  static Color complaintStatusColor(String status) {
    switch (status) {
      case 'pending':
        return statusPending;
      case 'in_progress':
        return statusInProgress;
      case 'resolved':
        return statusResolved;
      case 'rejected':
        return statusRejected;
      default:
        return textSecondary;
    }
  }
}
