// File: lib/core/session.dart
import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  // Keys
  static const String _keyUserId = 'user_id';
  static const String _keyName = 'name';
  static const String _keyEmail = 'email';
  static const String _keyRole = 'role';
  static const String _keyToken = 'token';
  static const String _keyStudentId = 'student_id';
  static const String _keyFacultyId = 'faculty_id';
  static const String _keyAdminId = 'admin_id';
  static const String _keyDepartment = 'department';
  static const String _keyYear = 'year';
  static const String _keySection = 'section';
  static const String _keyRegisterNumber = 'register_number';
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyLoginTime = 'login_time';

  // In-memory cache
  static int? _userId;
  static String? _name;
  static String? _email;
  static String? _role;
  static String? _token;
  static int? _studentId;
  static int? _facultyId;
  static int? _adminId;
  static String? _department;
  static String? _year;
  static String? _section;
  static String? _registerNumber;
  static DateTime? _loginTime;

  // ============================================================================
  // INITIALIZATION
  // ============================================================================

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    _userId = prefs.getInt(_keyUserId);
    _name = prefs.getString(_keyName);
    _email = prefs.getString(_keyEmail);
    _role = prefs.getString(_keyRole);
    _token = prefs.getString(_keyToken);
    _studentId = prefs.getInt(_keyStudentId);
    _facultyId = prefs.getInt(_keyFacultyId);
    _adminId = prefs.getInt(_keyAdminId);
    _department = prefs.getString(_keyDepartment);
    _year = prefs.getString(_keyYear);
    _section = prefs.getString(_keySection);
    _registerNumber = prefs.getString(_keyRegisterNumber);

    final loginTimeStr = prefs.getString(_keyLoginTime);
    if (loginTimeStr != null) {
      _loginTime = DateTime.parse(loginTimeStr);
    }

    // ✅ CRITICAL FIX: If user is logged in but has no token, clear session — forces re-login
    if (_userId != null && _token == null) {
      await clearSession();
    }
  }

  // ============================================================================
  // SAVE SESSION
  // ============================================================================

  static Future<void> saveSession({
    required int userId,
    required String name,
    required String email,
    required String role,
    String? token,
    int? studentId,
    int? facultyId,
    int? adminId,
    String? department,
    String? year,
    String? section,
    String? registerNumber,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Update memory
    _userId = userId;
    _name = name;
    _email = email;
    _role = role.toLowerCase();
    _token = token;
    _studentId = studentId;
    _facultyId = facultyId;
    _adminId = adminId;
    _department = department;
    _year = year;
    _section = section;
    _registerNumber = registerNumber;
    _loginTime = DateTime.now();

    // Save to storage
    await prefs.setInt(_keyUserId, userId);
    await prefs.setString(_keyName, name);
    await prefs.setString(_keyEmail, email);
    await prefs.setString(_keyRole, role.toLowerCase());
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyLoginTime, _loginTime!.toIso8601String());

    if (token != null) {
      await prefs.setString(_keyToken, token);
    }
    if (studentId != null) {
      await prefs.setInt(_keyStudentId, studentId);
    }
    if (facultyId != null) {
      await prefs.setInt(_keyFacultyId, facultyId);
    }
    if (adminId != null) {
      await prefs.setInt(_keyAdminId, adminId);
    }
    if (department != null) {
      await prefs.setString(_keyDepartment, department);
    }
    if (year != null) {
      await prefs.setString(_keyYear, year);
    }
    if (section != null) {
      await prefs.setString(_keySection, section);
    }
    if (registerNumber != null) {
      await prefs.setString(_keyRegisterNumber, registerNumber);
    }
  }

  // ============================================================================
  // CLEAR SESSION
  // ============================================================================

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();

    // Clear memory
    _userId = null;
    _name = null;
    _email = null;
    _role = null;
    _token = null;
    _studentId = null;
    _facultyId = null;
    _adminId = null;
    _department = null;
    _year = null;
    _section = null;
    _registerNumber = null;
    _loginTime = null;

    // ✅ Clear only session keys — preserve hod_setup_done_ flags
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyName);
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyRole);
    await prefs.remove(_keyToken);
    await prefs.remove(_keyStudentId);
    await prefs.remove(_keyFacultyId);
    await prefs.remove(_keyAdminId);
    await prefs.remove(_keyDepartment);
    await prefs.remove(_keyYear);
    await prefs.remove(_keySection);
    await prefs.remove(_keyRegisterNumber);
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyLoginTime);
  }

  // ============================================================================
  // GETTERS
  // ============================================================================

  static bool isLoggedIn() => _userId != null && _role != null;

  static int? get userId => _userId;
  static String? get name => _name;
  static String? get email => _email;
  static String? get role => _role;
  static String? get token => _token;
  static int? get studentId => _studentId;
  static int? get facultyId => _facultyId;
  static int? get adminId => _adminId;
  static String? get department => _department;
  static String? get year => _year;
  static String? get section => _section;
  static String? get registerNumber => _registerNumber;
  static DateTime? get loginTime => _loginTime;

  // Role checks
  static bool isStudent() => _role?.toLowerCase() == 'student';
  static bool isFaculty() => _role?.toLowerCase() == 'faculty';
  static bool isAdmin() => _role?.toLowerCase() == 'admin';

  // Get display name
  static String get displayName => _name ?? 'Guest';

  // Get role badge
  static String get roleBadge => _role?.toUpperCase() ?? '';

  // Get class display for students
  static String? get classDisplay {
    if (_department == null || _year == null || _section == null) return null;
    return '$_department - $_year - Section $_section';
  }

  // ============================================================================
  // SESSION VALIDATION
  // ============================================================================

  /// Token lasts 30 days — matches backend JWT expiry
  static bool isSessionValid() {
    if (_loginTime == null || _token == null) return false;
    final difference = DateTime.now().difference(_loginTime!);
    return difference.inDays < 30;
  }

  static Future<bool> validateAndRefresh() async {
    if (!isLoggedIn()) return false;
    if (!isSessionValid()) {
      await clearSession();
      return false;
    }
    return true;
  }

  // ============================================================================
  // ROUTING
  // ============================================================================

  static String getInitialRoute() {
    if (!isLoggedIn()) return '/';
    if (!isSessionValid()) {
      clearSession();
      return '/';
    }
    switch (_role?.toLowerCase()) {
      case 'student':
        return '/studentDashboard';
      case 'faculty':
        return '/facultyDashboard';
      case 'admin':
        return '/adminDashboard';
      case 'principal':
        return '/principalDashboard';
      default:
        return '/';
    }
  }

  // ============================================================================
  // UTILITIES
  // ============================================================================

  static Map<String, dynamic> getSessionInfo() {
    return {
      'user_id': _userId,
      'name': _name,
      'email': _email,
      'role': _role,
      'token': _token != null ? '${_token!.substring(0, 20)}...' : null,
      'student_id': _studentId,
      'faculty_id': _facultyId,
      'department': _department,
      'year': _year,
      'section': _section,
      'register_number': _registerNumber,
      'login_time': _loginTime?.toIso8601String(),
      'is_logged_in': isLoggedIn(),
      'is_valid': isSessionValid(),
    };
  }

  static Future<void> updateProfile({
    String? name,
    String? email,
    String? department,
    String? year,
    String? section,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (name != null) {
      _name = name;
      await prefs.setString(_keyName, name);
    }
    if (email != null) {
      _email = email;
      await prefs.setString(_keyEmail, email);
    }
    if (department != null) {
      _department = department;
      await prefs.setString(_keyDepartment, department);
    }
    if (year != null) {
      _year = year;
      await prefs.setString(_keyYear, year);
    }
    if (section != null) {
      _section = section;
      await prefs.setString(_keySection, section);
    }
  }
}
