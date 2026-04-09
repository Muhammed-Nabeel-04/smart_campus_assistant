import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_campus_assistant/core/session.dart';
import 'core/app_theme.dart';
import 'screens/auth/role_selection_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/faculty/faculty_dashboard_screen.dart';
import 'screens/faculty/attendance_qr_screen.dart';
import 'screens/faculty/view_attendance_screen.dart';
import 'screens/student/scan_qr_screen.dart';
import 'screens/student/student_dashboard_screen.dart';
import 'screens/auth/student_login_screen.dart';
import 'screens/auth/student_register_screen.dart';
import 'screens/student/student_onboarding_scan_screen.dart';
import 'core/app_config.dart';
import 'core/notification_service.dart';
import 'screens/settings/backend_settings_screen.dart';
import 'screens/student/student_mark_attendance_screen.dart';
import 'screens/student/student_password_setup_screen.dart';
import 'screens/faculty/faculty_password_setup_screen.dart';
import 'screens/auth/faculty_login_screen.dart';
import 'screens/faculty/faculty_qr_onboarding_screen.dart';
import 'screens/faculty/faculty_department_selection_screen.dart';
import 'screens/faculty/faculty_class_selection_screen.dart';
import 'screens/faculty/faculty_subject_selection_screen.dart';
import 'screens/faculty/faculty_classroom_management_screen.dart';
import 'screens/faculty/faculty_add_student_screen.dart';
import 'screens/faculty/faculty_start_attendance_screen.dart';
import 'screens/faculty/faculty_attendance_reports_screen.dart';
import 'screens/faculty/faculty_post_notification_screen.dart';
import 'screens/faculty/faculty_profile_screen.dart';
import 'screens/faculty/faculty_manual_attendance_screen.dart';
import 'screens/faculty/faculty_generate_student_qr_screen.dart';
import 'screens/faculty/faculty_student_details_screen.dart';
import 'screens/faculty/faculty_edit_student_screen.dart';
import 'screens/admin/admin_login_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/admin_faculty_management_screen.dart';
import 'screens/admin/admin_initial_setup_screen.dart';
import 'screens/admin/admin_add_faculty_screen.dart';
import 'screens/admin/admin_edit_faculty_screen.dart';
import 'screens/admin/admin_faculty_details_screen.dart';
import 'screens/admin/admin_generate_faculty_qr_screen.dart';
import 'screens/admin/admin_complaints_management_screen.dart';
import 'screens/admin/admin_system_reports_screen.dart';
import 'screens/admin/admin_profile_screen.dart';
import 'screens/admin/hod_subject_management_screen.dart';
import 'screens/admin/hod_qr_onboarding_screen.dart';
import 'screens/admin/hod_password_setup_screen.dart';
import 'screens/principal/principal_login_screen.dart';
import 'screens/principal/principal_initial_setup_screen.dart';
import 'screens/principal/principal_dashboard_screen.dart';
import 'screens/principal/principal_department_management_screen.dart';
import 'screens/principal/principal_complaints_screen.dart';
import 'screens/principal/principal_add_department_screen.dart';
import 'screens/principal/principal_hod_management_screen.dart';
import 'screens/principal/principal_add_hod_screen.dart';
import 'screens/principal/principal_hod_details_screen.dart';
import 'screens/principal/principal_generate_hod_qr_screen.dart';
import 'screens/principal/principal_profile_screen.dart';
import 'screens/faculty/cc_timetable_editor_screen.dart';
import 'screens/student/ssm_form_screen.dart';
import 'screens/student/ssm_result_screen.dart';
import 'screens/faculty/faculty_ssm_review_screen.dart';
import 'screens/admin/hod_ssm_approval_screen.dart';
import 'models/ssm_models.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

const String _kThemeKey = 'theme_mode';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SessionManager.initialize();
  await AppConfig.load();
  await NotificationService.initialize();
  runApp(const SmartCampusApp());
}

class SmartCampusApp extends StatefulWidget {
  const SmartCampusApp({super.key});

  static _SmartCampusAppState? _instance;

  static void setTheme(ThemeMode mode) => _instance?._setTheme(mode);
  static ThemeMode get currentTheme =>
      _instance?._themeMode ?? ThemeMode.system;

  @override
  State<SmartCampusApp> createState() => _SmartCampusAppState();
}

class _SmartCampusAppState extends State<SmartCampusApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    SmartCampusApp._instance = this;
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kThemeKey) ?? 'system';
    setState(() => _themeMode = _fromString(saved));
  }

  Future<void> _setTheme(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeKey, _toString(mode));
    setState(() => _themeMode = mode);
  }

  ThemeMode _fromString(String s) {
    switch (s) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String _toString(ThemeMode m) {
    switch (m) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      default:
        return 'system';
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Dhaanishitech Campus',
      themeMode: _themeMode,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/': (context) => const RoleSelectionScreen(),
        '/attendanceQR': (context) => const AttendanceQRScreen(),
        '/viewAttendance': (context) => const ViewAttendanceScreen(),
        //'/studentOnboardingQR': (context) => const StudentOnboardingQRScreen(),
        '/scanQR': (context) => const ScanQRScreen(),
        '/studentOnboardingScan': (context) =>
            const StudentOnboardingScanScreen(),
        //'/studentOnboarding': (context) => const StudentOnboardingScreen(),
        '/studentLogin': (context) => const StudentLoginScreen(),
        '/studentRegister': (context) => const StudentRegisterScreen(),
        '/backendSettings': (context) => const BackendSettingsScreen(),
        '/studentDashboard': (context) => const StudentDashboardScreen(),
        '/studentMarkAttendance': (context) =>
            const StudentMarkAttendanceScreen(),
        '/studentPasswordSetup': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return StudentPasswordSetupScreen(studentData: args);
        },
        '/facultyLogin': (context) => const FacultyLoginScreen(),
        '/facultyDashboard': (context) => const FacultyDashboardScreen(),
        '/facultyQrOnboarding': (context) => const FacultyQROnboardingScreen(),
        '/facultyPasswordSetup': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return FacultyPasswordSetupScreen(facultyData: args);
        },
        '/facultyDepartmentSelect': (context) {
          final action = ModalRoute.of(context)!.settings.arguments as String;
          return FacultyDepartmentSelectionScreen(action: action);
        },
        '/facultyClassSelect': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return FacultyClassSelectionScreen(
            department: args['department'],
            action: args['action'],
          );
        },
        '/facultySubjectSelect': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return FacultySubjectSelectionScreen(
            department: args['department'],
            classData: args['class'],
            action: args['action'],
            isNew: args['isNew'] ?? false,
          );
        },
        '/facultyClassroomManagement': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return FacultyClassroomManagementScreen(
            department: args['department'],
            classData: args['class'],
            subject: args['subject'],
            semester: args['semester'],
          );
        },
        '/facultyAddStudent': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return FacultyAddStudentScreen(
            department: args['department'],
            classData: args['classData'],
          );
        },
        '/facultyStartAttendance': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return FacultyStartAttendanceScreen(
            department: args['department'],
            classData: args['class'],
            subject: args['subject'],
            semester: args['semester'],
          );
        },
        '/facultyAttendanceReports': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return FacultyAttendanceReportsScreen(
            department: args['department'],
            classData: args['class'],
            subject: args['subject'],
            semester: args['semester'],
          );
        },
        '/facultyManualAttendance': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return FacultyManualAttendanceScreen(
            department: args['department'],
            classData: args['class'],
            subject: args['subject'],
          );
        },
        '/facultyPostNotification': (context) =>
            const FacultyPostNotificationScreen(),
        '/facultyProfile': (context) => const FacultyProfileScreen(),
        '/facultyGenerateStudentQR': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return FacultyGenerateStudentQRScreen(student: args);
        },
        '/facultyStudentDetails': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return FacultyStudentDetailsScreen(
            student: args['student'] ?? args,
            classData: args['classData'] ?? {},
          );
        },
        '/facultyEditStudent': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return FacultyEditStudentScreen(
            studentData: args['studentData'],
            classData: args['classData'],
          );
        },
        '/adminLogin': (context) => const AdminLoginScreen(),
        '/adminDashboard': (context) => const AdminDashboardScreen(),
        '/adminInitialSetup': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return AdminInitialSetupScreen(
            department: args['department'],
            userId: args['userId'] as int?,
          );
        },
        '/adminFacultyManagement': (context) =>
            const AdminFacultyManagementScreen(),
        '/adminAddFaculty': (context) => const AdminAddFacultyScreen(),
        '/adminEditFaculty': (context) {
          final faculty = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return AdminEditFacultyScreen(faculty: faculty);
        },
        '/adminFacultyDetails': (context) {
          final faculty = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return AdminFacultyDetailsScreen(faculty: faculty);
        },
        '/adminGenerateFacultyQR': (context) {
          final faculty = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return AdminGenerateFacultyQRScreen(faculty: faculty);
        },
        '/adminComplaintsManagement': (context) =>
            const AdminComplaintsManagementScreen(),
        '/adminSystemReports': (context) => const AdminSystemReportsScreen(),
        '/adminProfile': (context) => const AdminProfileScreen(),
        '/hodSubjectManagement': (context) =>
            const HODSubjectManagementScreen(),
        '/hodQROnboarding': (context) => const HODQROnboardingScreen(),
        '/hodPasswordSetup': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return HODPasswordSetupScreen(hodData: args);
        },
        '/principalLogin': (context) => const PrincipalLoginScreen(),
        '/principalDashboard': (context) => const PrincipalDashboardScreen(),
        '/principalInitialSetup': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>?;
          return PrincipalInitialSetupScreen(userId: args?['userId'] as int?);
        },
        '/principalDepartments': (context) =>
            const PrincipalDepartmentManagementScreen(),
        '/principalAddDepartment': (context) =>
            const PrincipalAddDepartmentScreen(),
        '/principalHODs': (context) => const PrincipalHODManagementScreen(),
        '/principalAddHOD': (context) => const PrincipalAddHODScreen(),
        '/principalHODDetails': (context) {
          final hod = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return PrincipalHODDetailsScreen(hod: hod);
        },
        '/principalGenerateHODQR': (context) {
          final hod = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return PrincipalGenerateHODQRScreen(hod: hod);
        },
        '/principalProfile': (context) => const PrincipalProfileScreen(),
        '/principalComplaints': (context) => const PrincipalComplaintsScreen(),
        '/ccTimetableEditor': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return CCTimetableEditorScreen(
            classId: args['class_id'],
            facultyId: args['faculty_id'],
          );
        },
        // ── SSM Routes ────────────────────────────────────────────────────
        '/ssmForm': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>?;
          return SSMFormScreen(
            existingFormData: args?['form_data'] as Map<String, dynamic>?,
          );
        },
        '/ssmResult': (context) {
          final submission =
              ModalRoute.of(context)!.settings.arguments as SSMSubmission;
          return SSMResultScreen(submission: submission);
        },
        '/facultySSMReview': (context) => const FacultySSMReviewScreen(),
        '/hodSSMApproval': (context) => const HODSSMApprovalScreen(),
      },
    );
  }
}
