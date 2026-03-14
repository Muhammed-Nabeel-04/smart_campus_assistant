// File: lib/screens/faculty/faculty_dashboard_screen.dart
// Main faculty dashboard with stats, quick actions, and navigation

import 'package:flutter/material.dart';
import '../../core/session.dart';
import '../../core/app_colors.dart';
import '../../services/api_service.dart';

class FacultyDashboardScreen extends StatefulWidget {
  const FacultyDashboardScreen({super.key});

  @override
  State<FacultyDashboardScreen> createState() => _FacultyDashboardScreenState();
}

class _FacultyDashboardScreenState extends State<FacultyDashboardScreen> {
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getFacultyStats(SessionManager.facultyId!);
      setState(() {
        _stats = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Logout',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await SessionManager.clearSession();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Wrapped with PopScope to prevent accidental back-button logout
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.bgDark,
        appBar: AppBar(
          backgroundColor: AppColors.bgCard,
          elevation: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                SessionManager.displayName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                SessionManager.department ?? 'Faculty',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: () => Navigator.pushNamed(context, '/facultyProfile'),
              tooltip: 'Profile',
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => Navigator.pushNamed(context, '/backendSettings'),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _loadStats,
          color: const Color(0xFF1565C0),
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF1565C0)),
                )
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Stats Grid
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.3,
                      children: [
                        _buildStatCard(
                          'Total Classes',
                          '${_stats?['total_classes'] ?? 0}',
                          Icons.class_,
                          const Color(0xFF4CAF50),
                        ),
                        _buildStatCard(
                          'Active Sessions',
                          '${_stats?['active_sessions'] ?? 0}',
                          Icons.play_circle,
                          const Color(0xFF2196F3),
                        ),
                        _buildStatCard(
                          'Total Students',
                          '${_stats?['total_students'] ?? 0}',
                          Icons.people,
                          const Color(0xFFFF9800),
                        ),
                        _buildStatCard(
                          'Avg Attendance',
                          '${_stats?['avg_attendance'] ?? 0}%',
                          Icons.trending_up,
                          const Color(0xFF9C27B0),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Quick Actions
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 12),

                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.2,
                      children: [
                        // ✅ START ATTENDANCE
                        _buildActionCard(
                          'Start Attendance',
                          Icons.qr_code,
                          const Color(0xFF1565C0),
                          () => Navigator.pushNamed(
                            context,
                            '/facultyDepartmentSelect',
                            arguments: 'attendance',
                          ),
                        ),
                        // ✅ MANUAL ATTENDANCE
                        _buildActionCard(
                          'Manual Attendance',
                          Icons.fact_check,
                          const Color(0xFFD84315),
                          () => Navigator.pushNamed(
                            context,
                            '/facultyDepartmentSelect',
                            arguments: 'manual',
                          ),
                        ),
                        // ✅ MANAGE CLASSES
                        _buildActionCard(
                          'Manage Classes',
                          Icons.class_,
                          const Color(0xFF00897B),
                          () => Navigator.pushNamed(
                            context,
                            '/facultyDepartmentSelect',
                            arguments: 'classroom',
                          ),
                        ),
                        // ✅ VIEW REPORTS
                        _buildActionCard(
                          'View Reports',
                          Icons.assessment,
                          const Color(0xFF6A1B9A),
                          () => Navigator.pushNamed(
                            context,
                            '/facultyDepartmentSelect',
                            arguments: 'reports',
                          ),
                        ),
                        // ✅ POST NOTICE
                        _buildActionCard(
                          'Post Notice',
                          Icons.notifications,
                          const Color(0xFFE65100),
                          () => Navigator.pushNamed(
                            context,
                            '/facultyPostNotification',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Recent Activity
                    const Text(
                      'Recent Sessions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 12),

                    if (_stats?['recent_sessions'] != null)
                      ..._buildRecentSessions(_stats!['recent_sessions'])
                    else
                      _buildEmptyState(),
                  ],
                ),
        ),
      ),
    );
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
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 28),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildRecentSessions(List<dynamic> sessions) {
    return sessions.take(5).map((session) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.schedule, color: Color(0xFF1565C0)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session['subject_name'] ?? 'Subject',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${session['class_name']} • ${session['students_present']} present',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: const Center(
        child: Text(
          'No recent sessions',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
