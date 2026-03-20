// File: lib/services/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../core/app_config.dart';
import '../core/session.dart';
import '../main.dart';

class ApiService {
  static String get _baseUrl => AppConfig.backendUrl;
  static const Duration _timeout = Duration(seconds: 30);

  // ============================================================================
  // AUTH HEADERS
  // ============================================================================

  static Map<String, String> get _authHeaders => {
    "Content-Type": "application/json",
    if (SessionManager.token != null)
      "Authorization": "Bearer ${SessionManager.token}",
  };

  static Map<String, String> get _authHeadersGet => {
    if (SessionManager.token != null)
      "Authorization": "Bearer ${SessionManager.token}",
  };

  // ============================================================================
  // AUTHENTICATION APIs
  // ============================================================================

  static Future<Map<String, dynamic>> registerStudent({
    required String name,
    required String email,
    required String password,
    required String department,
    required String year,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse("$_baseUrl/auth/register-student"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "name": name,
              "email": email,
              "password": password,
              "department": department,
              "year": year,
            }),
          )
          .timeout(_timeout);
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> registerFaculty({
    required String name,
    required String email,
    required String password,
    required String employeeId,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse("$_baseUrl/auth/register-faculty"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "name": name,
              "email": email,
              "password": password,
              "employee_id": employeeId,
            }),
          )
          .timeout(_timeout);
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse("$_baseUrl/auth/login"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"email": email, "password": password}),
          )
          .timeout(_timeout);
      // isLogin: true → shows "Invalid email or password" instead of "Session expired"
      return _handleResponse(response, isLogin: true) as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================================================
  // ONBOARDING APIs (no token needed)
  // ============================================================================

  static Future<Map<String, dynamic>> validateFacultyQR(String token) async {
    try {
      final response = await http
          .post(
            Uri.parse("$_baseUrl/onboarding/faculty/validate-qr"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"token": token}),
          )
          .timeout(_timeout);
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> setFacultyPassword({
    required int facultyId,
    required String password,
    required String token,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse("$_baseUrl/onboarding/faculty/set-password"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "faculty_id": facultyId,
              "password": password,
              "token": token,
            }),
          )
          .timeout(_timeout);
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> validateStudentQR({
    required String token,
  }) async {
    try {
      // ✅ Use new login endpoint that saves session token
      final response = await http
          .post(
            Uri.parse("$_baseUrl/auth/student-qr-login"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"token": token}),
          )
          .timeout(_timeout);
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> completeStudentRegistration({
    required String token,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse("$_baseUrl/onboarding/student/complete-registration"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"token": token, "password": password}),
          )
          .timeout(_timeout);
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================================================
  // FACULTY APIs
  // ============================================================================

  static Future<Map<String, dynamic>> getFacultyProfile() async {
    try {
      final response = await http
          .get(Uri.parse("$_baseUrl/faculty/me"), headers: _authHeadersGet)
          .timeout(_timeout);
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> getFacultyStats(int facultyId) async {
    try {
      final response = await http
          .get(
            Uri.parse("$_baseUrl/faculty/$facultyId/stats"),
            headers: _authHeadersGet,
          )
          .timeout(_timeout);
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  static Future<List<dynamic>> getActiveSessions(int facultyId) async {
    try {
      final response = await http
          .get(
            Uri.parse("$_baseUrl/faculty/$facultyId/active-sessions"),
            headers: _authHeadersGet,
          )
          .timeout(_timeout);
      return _handleResponse(response) as List<dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  static Future<List<dynamic>> getSessionsByPeriod(
    int facultyId, {
    String period = 'all',
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              "$_baseUrl/faculty/$facultyId/sessions-by-period?period=$period",
            ),
            headers: _authHeadersGet,
          )
          .timeout(_timeout);
      return _handleResponse(response) as List<dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  static Future<List<dynamic>> getRecentSessions(
    int facultyId, {
    int limit = 10,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              "$_baseUrl/faculty/$facultyId/recent-sessions?limit=$limit",
            ),
            headers: _authHeadersGet,
          )
          .timeout(_timeout);
      return _handleResponse(response) as List<dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> generateFacultyQR(int facultyId) async {
    try {
      final response = await http
          .post(
            Uri.parse("$_baseUrl/faculty/generate-qr"),
            headers: _authHeaders,
            body: jsonEncode({"faculty_id": facultyId}),
          )
          .timeout(_timeout);
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================================================
  // DEPARTMENT / CLASS / SUBJECT APIs
  // ============================================================================

  static Future<List<dynamic>> getDepartments() async {
    try {
      final response = await http
          .get(Uri.parse("$_baseUrl/departments/"))
          .timeout(_timeout);
      return _handleResponse(response) as List<dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  static Future<List<dynamic>> getFacultyMyDepartments() async {
    try {
      final response = await http
          .get(
            Uri.parse("$_baseUrl/faculty/my-departments"),
            headers: _authHeadersGet,
          )
          .timeout(_timeout);
      return _handleResponse(response) as List<dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  static Future<List<dynamic>> getFacultyMyClasses({int? departmentId}) async {
    try {
      final query = departmentId != null ? "?department_id=$departmentId" : "";
      final response = await http
          .get(
            Uri.parse("$_baseUrl/faculty/my-classes$query"),
            headers: _authHeadersGet,
          )
          .timeout(_timeout);
      return _handleResponse(response) as List<dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  static Future<List<dynamic>> getClassesByDepartment(
    dynamic departmentId,
  ) async {
    try {
      final response = await http
          .get(Uri.parse("$_baseUrl/classes/?department_id=$departmentId"))
          .timeout(_timeout);
      return _handleResponse(response) as List<dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  static Future<List<dynamic>> getSubjectsByClass(int classId) async {
    try {
      final response = await http
          .get(Uri.parse("$_baseUrl/subjects/?class_id=$classId"))
          .timeout(_timeout);
      return _handleResponse(response) as List<dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================================================
  // STUDENTS CRUD APIs
  // ============================================================================

  static Future<List<dynamic>> getClassStudents({
    required int departmentId,
    required String year,
    required String section,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              "$_baseUrl/students/?department_id=$departmentId&year=$year&section=$section",
            ),
            headers: _authHeadersGet,
          )
          .timeout(_timeout);
      return _handleResponse(response) as List<dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> addStudent(
    Map<String, dynamic> studentData,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse("$_baseUrl/students/"),
            headers: _authHeaders,
            body: jsonEncode(studentData),
          )
          .timeout(_timeout);
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> updateStudent(
    int studentId,
    Map<String, dynamic> studentData,
  ) async {
    try {
      final response = await http
          .put(
            Uri.parse("$_baseUrl/students/$studentId"),
            headers: _authHeaders,
            body: jsonEncode(studentData),
          )
          .timeout(_timeout);
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> generateStudentQR(int studentId) async {
    try {
      final response = await http
          .post(
            Uri.parse("$_baseUrl/students/$studentId/generate-qr/"),
            headers: _authHeaders,
          )
          .timeout(_timeout);
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================================================
  // STUDENT PROFILE APIs
  // ============================================================================

  static Future<Map<String, dynamic>> getStudentProfile(int studentId) async {
    try {
      final response = await http
          .get(
            Uri.parse("$_baseUrl/student/profile/$studentId"),
            headers: _authHeadersGet,
          )
          .timeout(_timeout);
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================================================
  // ATTENDANCE APIs
  // ============================================================================

  static Future<Map<String, dynamic>> getActiveSessionForStudent(
    int studentId,
  ) async {
    try {
      final response = await http
          .get(
            Uri.parse("$_baseUrl/attendance/active-for-student/$studentId"),
            headers: _authHeadersGet,
          )
          .timeout(_timeout);
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> getStudentAttendance(
    int studentId,
  ) async {
    try {
      final response = await http
          .get(
            Uri.parse("$_baseUrl/attendance/student/$studentId"),
            headers: _authHeadersGet,
          )
          .timeout(_timeout);
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  static Future<List<dynamic>> getStudentAttendanceHistory(
    int studentId,
  ) async {
    try {
      final response = await http
          .get(
            Uri.parse("$_baseUrl/attendance/student/$studentId/history"),
            headers: _authHeadersGet,
          )
          .timeout(_timeout);
      final data = _handleResponse(response);
      if (data is Map && data.containsKey('records')) {
        return List<dynamic>.from(data['records']);
      }
      if (data is List) return List<dynamic>.from(data);
      return [];
    } catch (e) {
      throw _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> startAttendanceSession({
    required int subjectId,
    required int classId,
    int? durationMinutes,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse("$_baseUrl/attendance/sessions/start/"),
            headers: _authHeaders,
            body: jsonEncode({
              "subject_id": subjectId,
              "class_id": classId,
              if (durationMinutes != null) "duration_minutes": durationMinutes,
            }),
          )
          .timeout(_timeout);
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> refreshAttendanceToken(
    int sessionId,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse(
              "$_baseUrl/attendance/sessions/$sessionId/refresh-token/",
            ),
            headers: _authHeaders,
          )
          .timeout(_timeout);
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  static Future<void> endAttendanceSession(int sessionId) async {
    try {
      final response = await http
          .post(
            Uri.parse("$_baseUrl/attendance/sessions/$sessionId/end/"),
            headers: _authHeaders,
          )
          .timeout(_timeout);
      _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  static Future<List<dynamic>> getSessionAttendance(int sessionId) async {
    try {
      final response = await http
          .get(
            Uri.parse("$_baseUrl/attendance/session/$sessionId"),
            headers: _authHeadersGet,
          )
          .timeout(_timeout);
      final data = _handleResponse(response);
      if (data is Map && data.containsKey("records")) {
        return List<dynamic>.from(data["records"]);
      }
      if (data is List) return List<dynamic>.from(data);
      return [];
    } catch (e) {
      throw _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> markAttendance({
    required String token,
    required int studentId,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse("$_baseUrl/attendance/mark/"),
            headers: _authHeaders,
            body: jsonEncode({"token": token, "student_id": studentId}),
          )
          .timeout(_timeout);
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> getAttendanceReports({
    required int classId,
    required int subjectId,
    String? fromDate,
    String? toDate,
  }) async {
    try {
      String url =
          "$_baseUrl/attendance/reports/?class_id=$classId&subject_id=$subjectId";
      if (fromDate != null) url += "&from_date=$fromDate";
      if (toDate != null) url += "&to_date=$toDate";
      final response = await http
          .get(Uri.parse(url), headers: _authHeadersGet)
          .timeout(_timeout);
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  static Future<void> submitManualAttendance(
    List<Map<String, dynamic>> records,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse("$_baseUrl/attendance/manual/"),
            headers: _authHeaders,
            body: jsonEncode({"records": records}),
          )
          .timeout(_timeout);
      _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================================================
  // NOTIFICATIONS APIs
  // ============================================================================

  static Future<List<dynamic>> getStudentNotifications({
    required int studentId,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse("$_baseUrl/notifications/student/$studentId"),
            headers: _authHeadersGet,
          )
          .timeout(_timeout);
      return _handleResponse(response) as List<dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  static Future<void> postNotification({
    required String title,
    required String message,
    required String type,
    required String target,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse("$_baseUrl/notifications/"),
            headers: _authHeaders,
            body: jsonEncode({
              "title": title,
              "message": message,
              "type": type,
              "target": target,
              "sent_by": SessionManager.facultyId,
            }),
          )
          .timeout(_timeout);
      _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================================================
  // COMPLAINTS APIs
  // ============================================================================

  static Future<List<dynamic>> getHODComplaints({String? status}) async {
    try {
      String url = "$_baseUrl/complaints/department";
      if (status != null) url += "?status=$status";
      final response = await http
          .get(Uri.parse(url), headers: _authHeadersGet)
          .timeout(_timeout);
      return _handleResponse(response) as List<dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  static Future<List<dynamic>> getPrincipalComplaints({
    String? status,
    int? departmentId,
  }) async {
    try {
      String url = "$_baseUrl/complaints/principal";
      final params = <String>[];
      if (status != null) params.add("status=$status");
      if (departmentId != null) params.add("department_id=$departmentId");
      if (params.isNotEmpty) url += "?${params.join('&')}";
      final response = await http
          .get(Uri.parse(url), headers: _authHeadersGet)
          .timeout(_timeout);
      return _handleResponse(response) as List<dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  static Future<void> escalateComplaint(int complaintId) async {
    try {
      final response = await http
          .post(
            Uri.parse("$_baseUrl/complaints/$complaintId/escalate"),
            headers: _authHeaders,
          )
          .timeout(_timeout);
      _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  static Future<dynamic> getStudentComplaints(int studentId) async {
    try {
      final response = await http
          .get(
            Uri.parse("$_baseUrl/complaints/student/$studentId"),
            headers: _authHeadersGet,
          )
          .timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  static Future<void> submitComplaint({
    required int studentId,
    required String category,
    required String priority,
    required String title,
    required String description,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse("$_baseUrl/complaints/"),
            headers: _authHeaders,
            body: jsonEncode({
              "student_id": studentId,
              "category": category,
              "priority": priority,
              "title": title,
              "description": description,
            }),
          )
          .timeout(_timeout);
      _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================================================
  // UTILITY
  // ============================================================================

  static Future<bool> checkConnection() async {
    try {
      final response = await http
          .get(Uri.parse("$_baseUrl/"))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static dynamic _handleResponse(
    http.Response response, {
    bool isLogin = false,
  }) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      if (isLogin) {
        throw ApiException('Invalid email or password.');
      }
      final error = jsonDecode(response.body);
      final detail = error['detail'] ?? 'Session expired. Please log in again.';
      SessionManager.clearSession();
      // ✅ Navigate to role selection from anywhere
      navigatorKey.currentState?.pushNamedAndRemoveUntil('/', (route) => false);
      throw ApiException(detail);
    } else if (response.statusCode == 403) {
      if (isLogin) {
        throw ApiException('Invalid email or password.');
      }
      final error = jsonDecode(response.body);
      throw ApiException(error['detail'] ?? 'Access denied.');
    } else {
      final error = jsonDecode(response.body);
      throw ApiException(error['detail'] ?? 'Request failed');
    }
  }

  static Exception _handleError(dynamic error) {
    if (error is SocketException) {
      return ApiException('Cannot connect to server. Check your connection.');
    } else if (error is HttpException) {
      return ApiException('Server error occurred.');
    } else if (error is FormatException) {
      return ApiException('Invalid data received from server.');
    } else if (error is ApiException) {
      return error;
    } else {
      return ApiException('An unexpected error occurred: ${error.toString()}');
    }
  }

  // ============================================================================
  // ADMIN APIs
  // ============================================================================

  static Future<Map<String, dynamic>> getAdminStats() async {
    try {
      final response = await http
          .get(Uri.parse("$_baseUrl/admin/stats"), headers: _authHeadersGet)
          .timeout(_timeout);
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  static Future<List<dynamic>> getAllFaculty() async {
    try {
      final response = await http
          .get(Uri.parse("$_baseUrl/admin/faculty"), headers: _authHeadersGet)
          .timeout(_timeout);
      return _handleResponse(response) as List<dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> createFaculty(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse("$_baseUrl/admin/faculty"),
            headers: _authHeaders,
            body: jsonEncode(data),
          )
          .timeout(_timeout);
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> updateFaculty(
    int facultyId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http
          .put(
            Uri.parse("$_baseUrl/admin/faculty/$facultyId"),
            headers: _authHeaders,
            body: jsonEncode(data),
          )
          .timeout(_timeout);
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> deleteFaculty(int facultyId) async {
    try {
      final response = await http
          .delete(
            Uri.parse("$_baseUrl/admin/faculty/$facultyId"),
            headers: _authHeadersGet,
          )
          .timeout(_timeout);
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> generateAdminFacultyQR(
    int facultyId,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse("$_baseUrl/admin/faculty/$facultyId/generate-qr"),
            headers: _authHeaders,
          )
          .timeout(_timeout);
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  static Future<List<dynamic>> getAllComplaints({String? status}) async {
    try {
      String url = "$_baseUrl/admin/complaints";
      if (status != null) url += "?status=$status";
      final response = await http
          .get(Uri.parse(url), headers: _authHeadersGet)
          .timeout(_timeout);
      return _handleResponse(response) as List<dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> adminUpdateComplaint(
    int complaintId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http
          .put(
            Uri.parse("$_baseUrl/complaints/$complaintId"),
            headers: _authHeaders,
            body: jsonEncode(data),
          )
          .timeout(_timeout);
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> getSystemReports({
    String period = 'today',
    int? departmentId,
  }) async {
    try {
      String url = "$_baseUrl/admin/reports?period=$period";
      if (departmentId != null) url += "&department_id=$departmentId";
      final response = await http
          .get(Uri.parse(url), headers: _authHeadersGet)
          .timeout(_timeout);
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================================================
  // PRINCIPAL SETUP METHODS
  // ============================================================================

  static Future<Map<String, dynamic>> checkPrincipalSetupStatus() async {
    try {
      final response = await http
          .get(
            Uri.parse("$_baseUrl/principal/setup/status"),
            headers: _authHeadersGet,
          )
          .timeout(_timeout);
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> setPrincipalInitialPassword({
    required String newPassword,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse("$_baseUrl/principal/setup/set-password"),
            headers: _authHeaders,
            body: jsonEncode({'new_password': newPassword}),
          )
          .timeout(_timeout);
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> changePrincipalPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse("$_baseUrl/principal/setup/change-password"),
            headers: _authHeaders,
            body: jsonEncode({
              'current_password': currentPassword,
              'new_password': newPassword,
            }),
          )
          .timeout(_timeout);
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> changePrincipalEmail({
    required String newEmail,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse("$_baseUrl/principal/setup/change-email"),
            headers: _authHeaders,
            body: jsonEncode({'new_email': newEmail, 'password': password}),
          )
          .timeout(_timeout);
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> createDepartmentsBatch(
    List<Map<String, dynamic>> departments,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse("$_baseUrl/principal/setup/departments/batch"),
            headers: _authHeaders,
            body: jsonEncode({'departments': departments}),
          )
          .timeout(_timeout);
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================================================
  // PRINCIPAL MANAGEMENT METHODS
  // ============================================================================

  static Future<Map<String, dynamic>> getPrincipalStats() async {
    try {
      final response = await http
          .get(Uri.parse("$_baseUrl/principal/stats"), headers: _authHeadersGet)
          .timeout(_timeout);
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  static Future<List<dynamic>> getPrincipalDepartments() async {
    try {
      final response = await http
          .get(
            Uri.parse("$_baseUrl/principal/departments"),
            headers: _authHeadersGet,
          )
          .timeout(_timeout);
      return _handleResponse(response) as List<dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ✅ Alias used by principal screens
  static Future<List<dynamic>> getAllDepartments() => getPrincipalDepartments();

  static Future<Map<String, dynamic>> createDepartment({
    required String name,
    required String code,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse("$_baseUrl/principal/departments"),
            headers: _authHeaders,
            body: jsonEncode({'name': name, 'code': code}),
          )
          .timeout(_timeout);
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> updateDepartment({
    required int id,
    String? name,
    String? code,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse("$_baseUrl/principal/departments/$id"),
            headers: _authHeaders,
            body: jsonEncode({
              if (name != null) 'name': name,
              if (code != null) 'code': code,
            }),
          )
          .timeout(_timeout);
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> deleteDepartment(int id) async {
    try {
      final response = await http
          .delete(
            Uri.parse("$_baseUrl/principal/departments/$id"),
            headers: _authHeadersGet,
          )
          .timeout(_timeout);
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  static Future<List<dynamic>> getAllHODs() async {
    try {
      final response = await http
          .get(Uri.parse("$_baseUrl/principal/hods"), headers: _authHeadersGet)
          .timeout(_timeout);
      return _handleResponse(response) as List<dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> createHOD({
    required String name,
    required String email,
    required int departmentId,
    String? phoneNumber,
    String? employeeId,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse("$_baseUrl/principal/hods"),
            headers: _authHeaders,
            body: jsonEncode({
              'name': name,
              'email': email,
              'department_id': departmentId,
              if (phoneNumber != null) 'phone_number': phoneNumber,
              if (employeeId != null) 'employee_id': employeeId,
            }),
          )
          .timeout(_timeout);
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> updateHOD({
    required int id,
    String? name,
    String? email,
    int? departmentId,
    String? phoneNumber,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse("$_baseUrl/principal/hods/$id"),
            headers: _authHeaders,
            body: jsonEncode({
              if (name != null) 'name': name,
              if (email != null) 'email': email,
              if (departmentId != null) 'department_id': departmentId,
              if (phoneNumber != null) 'phone_number': phoneNumber,
            }),
          )
          .timeout(_timeout);
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> deleteHOD(int id) async {
    try {
      final response = await http
          .delete(
            Uri.parse("$_baseUrl/principal/hods/$id"),
            headers: _authHeadersGet,
          )
          .timeout(_timeout);
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> generateHODQR(int hodId) async {
    try {
      final response = await http
          .post(
            Uri.parse("$_baseUrl/principal/hods/$hodId/generate-qr"),
            headers: _authHeaders,
            body: jsonEncode({}),
          )
          .timeout(_timeout);
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> validateHODQR(String token) async {
    try {
      final response = await http
          .post(
            Uri.parse("$_baseUrl/onboarding/hod/validate-qr"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"token": token}),
          )
          .timeout(_timeout);
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> setHODPassword({
    required int hodId,
    required String password,
    required String token,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse("$_baseUrl/onboarding/hod/set-password"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "hod_id": hodId,
              "password": password,
              "token": token,
            }),
          )
          .timeout(_timeout);
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ── HOD Setup Methods ─────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> checkSetupStatus() async {
    try {
      final response = await http
          .get(
            Uri.parse("$_baseUrl/hod/setup-status"),
            headers: _authHeadersGet,
          )
          .timeout(_timeout);
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> getHODDepartment() async {
    try {
      final response = await http
          .get(Uri.parse("$_baseUrl/hod/department"), headers: _authHeadersGet)
          .timeout(_timeout);
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> changeAdminPassword({
    required String newPassword,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse("$_baseUrl/hod/change-password"),
            headers: _authHeaders,
            body: jsonEncode({'new_password': newPassword}),
          )
          .timeout(_timeout);
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================================================
  // HOD SUBJECT MANAGEMENT
  // ============================================================================

  static Future<Map<String, dynamic>> getHODSubjects() async {
    try {
      final response = await http
          .get(Uri.parse("$_baseUrl/hod/subjects"), headers: _authHeadersGet)
          .timeout(_timeout);
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> addHODSubject({
    required String name,
    required String year,
    required int semester,
    int credits = 3,
    String subjectType = 'Theory',
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse("$_baseUrl/hod/subjects/add"),
            headers: _authHeaders,
            body: jsonEncode({
              'name': name,
              'year': year,
              'semester': semester,
              'credits': credits,
              'subject_type': subjectType,
            }),
          )
          .timeout(_timeout);
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> deleteHODSubject(int subjectId) async {
    try {
      final response = await http
          .delete(
            Uri.parse("$_baseUrl/hod/subjects/$subjectId"),
            headers: _authHeadersGet,
          )
          .timeout(_timeout);
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> updateClassSemester({
    required String year,
    required int semester,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse("$_baseUrl/hod/classes/update-semester"),
            headers: _authHeaders,
            body: jsonEncode({'year': year, 'semester': semester}),
          )
          .timeout(_timeout);
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> createSubjectsBatch(
    List<Map<String, dynamic>> subjects,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse("$_baseUrl/hod/subjects/batch"),
            headers: _authHeaders,
            body: jsonEncode({'subjects': subjects}),
          )
          .timeout(_timeout);
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  static Future<void> logout() async {
    try {
      await http
          .post(Uri.parse("$_baseUrl/auth/logout"), headers: _authHeaders)
          .timeout(_timeout);
    } catch (_) {
      // Ignore errors — clear session regardless
    }
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}
