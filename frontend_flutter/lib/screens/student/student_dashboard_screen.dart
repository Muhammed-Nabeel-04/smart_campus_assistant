// File: lib/screens/student/student_dashboard_screen.dart
// COMPLETE Student Dashboard with 4 Tabs

import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import 'dart:async';
import '../../core/session.dart';

import '../../services/api_service.dart';

import 'student_attendance_tab.dart'; // Ensure these paths match your folder structure
import 'student_notifications_tab.dart';
import 'student_complaints_tab.dart';
import 'dart:io';
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
    // ✅ 1. WRAPPED IN WillPopScope
    return WillPopScope(
      onWillPop: () async {
        // If not on Home tab → go back to Home
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
          return false; // Do not pop route
        }

        // If on Home tab → show exit dialog
        final exitApp = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A2332),
            title: const Text(
              "Exit App",
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              "Do you want to exit the app?",
              style: TextStyle(color: Colors.white.withOpacity(0.8)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  "Exit",
                  style: TextStyle(color: Color(0xFFFF6B6B)),
                ),
              ),
            ],
          ),
        );

        if (exitApp == true) {
          exit(0); // Actually close the app
        }

        return false; // Keep the app open if they hit cancel
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F1419),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A2332),
          elevation: 0,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00D9FF), Color(0xFF0099CC)],
                  ),
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
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    SessionManager.department ?? '',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF00D9FF),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: Colors.white),
              onPressed: () => Navigator.pushNamed(context, '/backendSettings'),
            ),
          ],
        ),
        body: _pages[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFF1A2332),
          selectedItemColor: const Color(0xFF00D9FF),
          unselectedItemColor: Colors.white.withOpacity(0.5),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
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
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
        floatingActionButton: _currentIndex == 0
            ? FloatingActionButton.extended(
                onPressed: () =>
                    Navigator.pushNamed(context, '/studentMarkAttendance'),
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Mark Attendance'),
                backgroundColor: const Color(0xFF00D9FF),
                foregroundColor: const Color(0xFF0F1419),
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

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _blinkAnim = Tween<double>(begin: 0.3, end: 1.0).animate(_blinkController);
    _loadStats();
    // Poll for active sessions every 10 seconds
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) _checkActiveSession();
    });
  }

  @override
  void dispose() {
    _blinkController.dispose();
    _pollTimer?.cancel();
    super.dispose();
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
      await _checkActiveSession();
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00D9FF)),
      );
    }

    final overallPercentage = _stats?['overall_percentage'] ?? 0.0;

    return RefreshIndicator(
      onRefresh: _loadStats,
      color: const Color(0xFF00D9FF),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Active Session Banner
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
                      color: AppColors.success.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.success),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.radio_button_checked,
                          color: AppColors.success,
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
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'by ${_activeSession!['faculty_name']} — Tap to mark attendance',
                                style: const TextStyle(
                                  color: AppColors.success,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: AppColors.success,
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Overall Attendance Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: overallPercentage >= 75
                    ? [const Color(0xFF00D9FF), const Color(0xFF0099CC)]
                    : [const Color(0xFFFF6B6B), const Color(0xFFEE5A6F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color:
                      (overallPercentage >= 75
                              ? const Color(0xFF00D9FF)
                              : const Color(0xFFFF6B6B))
                          .withOpacity(0.3),
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
                  overallPercentage >= 75
                      ? '✓ Above Required 75%'
                      : '⚠ Below Required 75%',
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

          // Subject-wise attendance
          const Text(
            'Subject-wise Attendance',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          if (_stats?['subjects'] != null)
            ..._buildSubjectCards(_stats!['subjects'])
          else
            _buildEmptyState('No subjects data available'),

          const SizedBox(height: 24),

          // Quick stats grid
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Classes',
                  '${_stats?['total_classes'] ?? 0}',
                  Icons.calendar_month,
                  const Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Attended',
                  '${_stats?['attended'] ?? 0}',
                  Icons.check_circle,
                  const Color(0xFF2196F3),
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
                  const Color(0xFFFF5722),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Required',
                  '75%',
                  Icons.flag,
                  const Color(0xFFFF9800),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSubjectCards(List<dynamic> subjects) {
    return subjects.map((subject) {
      final percentageRaw = subject['percentage'] ?? 0;
      final percentage = (percentageRaw is num)
          ? percentageRaw.toDouble()
          : double.tryParse(percentageRaw.toString()) ?? 0.0;

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2332),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: percentage >= 75
                ? const Color(0xFF00D9FF).withOpacity(0.3)
                : const Color(0xFFFF6B6B).withOpacity(0.3),
          ),
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
                    style: const TextStyle(
                      color: Colors.white,
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
                    color: percentage >= 75
                        ? const Color(0xFF00D9FF).withOpacity(0.2)
                        : const Color(0xFFFF6B6B).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: percentage >= 75
                          ? const Color(0xFF00D9FF)
                          : const Color(0xFFFF6B6B),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: const Color(0xFF2A3A4A),
              valueColor: AlwaysStoppedAnimation<Color>(
                percentage >= 75
                    ? const Color(0xFF00D9FF)
                    : const Color(0xFFFF6B6B),
              ),
              minHeight: 6,
            ),
            const SizedBox(height: 8),
            Text(
              '${subject['attended']}/${subject['total']} classes',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
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
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2332),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Text(
          message,
          style: TextStyle(color: Colors.white.withOpacity(0.5)),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
