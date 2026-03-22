// lib/core/app_theme.dart
// ════════════════════════════════════════════════════════════════
//  ALL COLORS + LIGHT/DARK THEMES IN ONE PLACE
//  To change theme: only edit THIS file
// ════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // ════════════════════════════════════════════════════════════════
  // COLORS — LIGHT MODE
  // ════════════════════════════════════════════════════════════════

  static const Color lightPrimary = Color(0xFF1976D2);
  static const Color lightSecondary = Color(0xFF00897B);
  static const Color lightTertiary = Color(0xFFFB8C00); // CTA buttons
  static const Color lightError = Color(0xFFD32F2F);
  static const Color lightBackground = Color(0xFFFAFAFA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightOnPrimary = Colors.white;
  static const Color lightOnSecondary = Colors.white;
  static const Color lightOnTertiary = Colors.white;
  static const Color lightOnSurface = Color(0xFF212121);
  static const Color lightOnBg = Color(0xFF212121);
  static const Color lightOnError = Colors.white;

  // Input / card backgrounds
  static const Color lightInputFill = Color(0xFFF5F5F5);
  static const Color lightDivider = Color(0xFFE0E0E0);
  static const Color lightCardBg = Color(0xFFFFFFFF);
  static const Color lightTextSub = Color(0xFF757575);
  static const Color lightTextHint = Color(0xFFBDBDBD);

  // ════════════════════════════════════════════════════════════════
  // COLORS — DARK MODE
  // ════════════════════════════════════════════════════════════════

  static const Color darkPrimary = Color(0xFF64B5F6);
  static const Color darkSecondary = Color(0xFF4DB6AC);
  static const Color darkTertiary = Color(0xFFFFB74D); // CTA buttons
  static const Color darkError = Color(0xFFEF5350);
  static const Color darkBackground = Color(0xFF0A1929);
  static const Color darkSurface = Color(0xFF1E2A3A);
  static const Color darkOnPrimary = Colors.black;
  static const Color darkOnSecondary = Colors.black;
  static const Color darkOnTertiary = Colors.black;
  static const Color darkOnSurface = Colors.white;
  static const Color darkOnBg = Colors.white;
  static const Color darkOnError = Colors.black;

  // Input / card backgrounds
  static const Color darkInputFill = Color(0xFF1E2A3A);
  static const Color darkDivider = Color(0xFF2A3A4A);
  static const Color darkCardBg = Color(0xFF1E2A3A);
  static const Color darkTextSub = Color(0xFF90A4AE);
  static const Color darkTextHint = Color(0xFF546E7A);
  static const Color darkElevated = Color(0xFF243044);
  static const Color darkSeparator = Color(0xFF2A3A4A);

  // ════════════════════════════════════════════════════════════════
  // ROLE COLORS (used for badges, chips, gradients — both themes)
  // ════════════════════════════════════════════════════════════════

  static const Color roleStudent = Color(0xFF4CAF50);
  static const Color roleFaculty = Color(0xFF00BCD4);
  static const Color roleHOD = Color(0xFFF44336);
  static const Color rolePrincipal = Color(0xFF9C27B0);

  // ════════════════════════════════════════════════════════════════
  // SEMANTIC STATUS COLORS (same in both themes)
  // ════════════════════════════════════════════════════════════════

  static const Color success = Color(0xFF4CAF50);
  static const Color successDark = Color(0xFF66BB6A);
  static const Color warning = Color(0xFFFF9800);
  static const Color warningMid = Color(0xFFFFC107);
  static const Color danger = Color(0xFFFF6B6B);
  static const Color dangerDark = Color(0xFFEE5A6F);
  static const Color info = Color(0xFF2196F3);
  static const Color urgent = Color(0xFFFF5722);
  static const Color amber = Color(0xFFFFC107);

  static const Color statusPending = Color(0xFFFFA726);
  static const Color statusInProgress = Color(0xFF42A5F5);
  static const Color statusResolved = Color(0xFF66BB6A);
  static const Color statusRejected = Color(0xFFEF5350);

  static const Color priorityCritical = Color(0xFFFF5722);
  static const Color priorityHigh = Color(0xFFFF9800);
  static const Color priorityMedium = Color(0xFFFFC107);
  static const Color priorityLow = Color(0xFF4CAF50);

  // ════════════════════════════════════════════════════════════════
  // GRADIENTS
  // ════════════════════════════════════════════════════════════════

  static const LinearGradient primaryGradientLight = LinearGradient(
    colors: [lightPrimary, Color(0xFF1565C0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryGradientDark = LinearGradient(
    colors: [darkPrimary, Color(0xFF1976D2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient dangerGradient = LinearGradient(
    colors: [danger, dangerDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF16213E), Color(0xFF0F3460)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ════════════════════════════════════════════════════════════════

  static Color attendanceColor(double pct) => pct >= 75 ? success : danger;

  static Color notificationColor(String type) {
    switch (type) {
      case 'info':
        return info;
      case 'warning':
        return warning;
      case 'urgent':
        return urgent;
      case 'announcement':
        return darkPrimary;
      default:
        return darkTextSub;
    }
  }

  static Color priorityColor(String? priority) {
    switch ((priority ?? '').toLowerCase()) {
      case 'critical':
        return priorityCritical;
      case 'high':
        return priorityHigh;
      case 'medium':
        return priorityMedium;
      case 'low':
        return priorityLow;
      default:
        return darkTextSub;
    }
  }

  static Color complaintStatusColor(String? status) {
    switch (status ?? '') {
      case 'pending':
        return statusPending;
      case 'in_progress':
        return statusInProgress;
      case 'resolved':
        return statusResolved;
      case 'rejected':
        return statusRejected;
      default:
        return darkTextSub;
    }
  }

  // ════════════════════════════════════════════════════════════════
  // LIGHT THEME
  // ════════════════════════════════════════════════════════════════

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: lightPrimary,
      onPrimary: lightOnPrimary,
      secondary: lightSecondary,
      onSecondary: lightOnSecondary,
      tertiary: lightTertiary,
      onTertiary: lightOnTertiary,
      error: lightError,
      onError: lightOnError,
      surface: lightSurface,
      onSurface: lightOnSurface,
      background: lightBackground,
      onBackground: lightOnBg,
    ),
    scaffoldBackgroundColor: lightBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: lightSurface,
      foregroundColor: lightOnSurface,
      elevation: 1,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: lightOnSurface,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: lightOnSurface),
    ),
    cardTheme: CardThemeData(
      color: lightCardBg,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: lightSurface,
      selectedItemColor: lightPrimary,
      unselectedItemColor: lightTextSub,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: lightTertiary,
        foregroundColor: lightOnTertiary,
        elevation: 2,
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: lightPrimary,
        side: const BorderSide(color: lightPrimary),
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lightInputFill,
      labelStyle: const TextStyle(color: lightTextSub),
      hintStyle: const TextStyle(color: lightTextHint),
      prefixIconColor: lightPrimary,
      suffixIconColor: lightPrimary,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: lightDivider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: lightDivider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: lightPrimary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: lightError),
      ),
    ),
    dividerTheme: const DividerThemeData(color: lightDivider, thickness: 1),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFFE3F2FD),
      selectedColor: lightPrimary,
      labelStyle: const TextStyle(fontSize: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );

  // ════════════════════════════════════════════════════════════════
  // DARK THEME
  // ════════════════════════════════════════════════════════════════

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: darkPrimary,
      onPrimary: darkOnPrimary,
      secondary: darkSecondary,
      onSecondary: darkOnSecondary,
      tertiary: darkTertiary,
      onTertiary: darkOnTertiary,
      error: darkError,
      onError: darkOnError,
      surface: darkSurface,
      onSurface: darkOnSurface,
      background: darkBackground,
      onBackground: darkOnBg,
    ),
    scaffoldBackgroundColor: darkBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: darkSurface,
      foregroundColor: darkOnSurface,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: darkOnSurface,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: darkOnSurface),
    ),
    cardTheme: CardThemeData(
      color: darkCardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: darkSurface,
      selectedItemColor: darkPrimary,
      unselectedItemColor: darkTextSub,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: darkTertiary,
        foregroundColor: darkOnTertiary,
        elevation: 0,
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: darkPrimary,
        side: const BorderSide(color: darkPrimary),
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkInputFill,
      labelStyle: const TextStyle(color: darkTextSub),
      hintStyle: const TextStyle(color: darkTextHint),
      prefixIconColor: darkPrimary,
      suffixIconColor: darkPrimary,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: darkDivider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: darkDivider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: darkPrimary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: darkError),
      ),
    ),
    dividerTheme: const DividerThemeData(color: darkDivider, thickness: 1),
    chipTheme: ChipThemeData(
      backgroundColor: darkSurface,
      selectedColor: darkPrimary,
      labelStyle: const TextStyle(fontSize: 13, color: darkOnSurface),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );
}
