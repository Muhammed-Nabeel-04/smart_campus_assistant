// File: lib/screens/student/student_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import '../../core/session.dart';
import '../../core/notification_service.dart';
import '../../services/api_service.dart';
import 'student_attendance_tab.dart';
import 'student_notifications_tab.dart';
import 'student_complaints_tab.dart';
import 'student_profile_tab.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    _HomeTab(),
    StudentAttendanceTab(),
    StudentNotificationsTab(),
    StudentComplaintsTab(),
    StudentProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return WillPopScope(
      onWillPop: () async {
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
          return false;
        }

        final exitApp = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit App'),
            content: const Text('Do you want to exit the app?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Exit', style: TextStyle(color: cs.error)),
              ),
            ],
          ),
        );

        if (exitApp == true) exit(0);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [cs.primary, cs.secondary]),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.school, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    SessionManager.name ?? 'Student',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  Text(
                    SessionManager.department ??
                        SessionManager.registerNumber ??
                        '',
                    style: TextStyle(fontSize: 12, color: cs.primary),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => Navigator.pushNamed(context, '/backendSettings'),
            ),
          ],
        ),
        body: _pages[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              activeIcon: Icon(Icons.assignment),
              label: 'Attendance',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications_outlined),
              activeIcon: Icon(Icons.notifications),
              label: 'Notices',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.report_problem_outlined),
              activeIcon: Icon(Icons.report_problem),
              label: 'Complaints',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
        floatingActionButton: _currentIndex == 0
            ? FloatingActionButton.extended(
                onPressed: () =>
                    Navigator.pushNamed(context, '/studentMarkAttendance'),
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Mark Attendance'),
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
              )
            : null,
      ),
    );
  }
}

// ============================================================================
// HOME TAB
// ============================================================================

class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _stats;
  Map<String, dynamic>? _activeSession;
  bool _isLoading = true;
  late AnimationController _blinkController;
  late Animation<double> _blinkAnim;
  Timer? _pollTimer;
  Timer? _notificationTimer;
  int _lastNotificationCount = -1;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _blinkAnim = Tween<double>(begin: 0.3, end: 1.0).animate(_blinkController);
    _loadStats();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) _checkActiveSession();
    });
    _notificationTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _checkNewNotifications();
    });
  }

  @override
  void dispose() {
    _blinkController.dispose();
    _pollTimer?.cancel();
    _notificationTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkNewNotifications() async {
    try {
      final data = await ApiService.getStudentNotifications(
        studentId: SessionManager.studentId!,
      );
      final count = (data as List).length;
      if (_lastNotificationCount == -1) {
        _lastNotificationCount = count;
        return;
      }
      if (count > _lastNotificationCount) {
        final newOnes = data.take(count - _lastNotificationCount);
        for (final n in newOnes) {
          await NotificationService.showNotification(
            id: n['id'] ?? DateTime.now().millisecondsSinceEpoch,
            title: n['title'] ?? 'New Notification',
            body: n['message'] ?? '',
          );
        }
      }
      _lastNotificationCount = count;
    } catch (_) {}
  }

  Future<void> _checkActiveSession() async {
    try {
      final data = await ApiService.getActiveSessionForStudent(
        SessionManager.studentId!,
      );
      if (mounted) setState(() => _activeSession = data);
    } catch (_) {}
  }

  Future<void> _loadStats() async {
    try {
      final stats = await ApiService.getStudentAttendance(
        SessionManager.studentId!,
      );
      try {
        final profile = await ApiService.getStudentProfile(
          SessionManager.studentId!,
        );
        if (profile['department'] != null) {
          await SessionManager.updateProfile(department: profile['department']);
        }
      } catch (_) {}
      await _checkActiveSession();
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: cs.primary));
    }

    final overallPercentage = (_stats?['overall_percentage'] ?? 0.0) as num;
    final isGood = overallPercentage >= 75;
    final attendanceColor = isGood ? const Color(0xFF4CAF50) : cs.error;

    return RefreshIndicator(
      onRefresh: _loadStats,
      color: cs.primary,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Active Session Banner ─────────────────────────
          if (_activeSession?['active'] == true)
            GestureDetector(
              onTap: () =>
                  Navigator.pushNamed(context, '/studentMarkAttendance'),
              child: AnimatedBuilder(
                animation: _blinkAnim,
                builder: (context, child) => Opacity(
                  opacity: _blinkAnim.value,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF4CAF50)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.radio_button_checked,
                          color: Color(0xFF4CAF50),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_activeSession!['subject_name']} class is ongoing!',
                                style: const TextStyle(
                                  color: Color(0xFF4CAF50),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'by ${_activeSession!['faculty_name']} — Tap to mark attendance',
                                style: const TextStyle(
                                  color: Color(0xFF4CAF50),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: Color(0xFF4CAF50),
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // ── Overall Attendance Card ───────────────────────
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isGood
                    ? [cs.primary, cs.secondary]
                    : [cs.error, cs.error.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: (isGood ? cs.primary : cs.error).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'Overall Attendance',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${overallPercentage.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: overallPercentage / 100,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 6,
                ),
                const SizedBox(height: 16),
                Text(
                  isGood ? '✓ Above Required 75%' : '⚠ Below Required 75%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Subject-wise Attendance ───────────────────────
          Text(
            'Subject-wise Attendance',
            style: TextStyle(
              color: cs.onBackground,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          if (_stats?['subjects'] != null &&
              (_stats!['subjects'] as List).isNotEmpty)
            ..._buildSubjectCards(_stats!['subjects'], cs)
          else
            _buildEmptyState('No subjects data available', cs),

          const SizedBox(height: 24),

          // ── Quick Stats Grid ──────────────────────────────
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Classes',
                  '${_stats?['total_classes'] ?? 0}',
                  Icons.calendar_month,
                  const Color(0xFF4CAF50),
                  cs,
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Attended',
                  '${_stats?['attended'] ?? 0}',
                  Icons.check_circle,
                  cs.primary,
                  cs,
                  isDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Absent',
                  '${_stats?['absent'] ?? 0}',
                  Icons.cancel,
                  cs.error,
                  cs,
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Required',
                  '75%',
                  Icons.flag,
                  cs.tertiary,
                  cs,
                  isDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 80), // Space for FAB
        ],
      ),
    );
  }

  List<Widget> _buildSubjectCards(List<dynamic> subjects, ColorScheme cs) {
    return subjects.map((subject) {
      final percentageRaw = subject['percentage'] ?? 0;
      final percentage = (percentageRaw is num)
          ? percentageRaw.toDouble()
          : double.tryParse(percentageRaw.toString()) ?? 0.0;
      final isGood = percentage >= 75;
      final color = isGood ? cs.primary : cs.error;

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    subject['subject_name'] ?? 'Unknown',
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: cs.onSurface.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
            const SizedBox(height: 8),
            Text(
              '${subject['attended']}/${subject['total']} classes',
              style: TextStyle(
                color: cs.onSurface.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    ColorScheme cs,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: cs.onSurface.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Text(
          message,
          style: TextStyle(color: cs.onBackground.withOpacity(0.5)),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
