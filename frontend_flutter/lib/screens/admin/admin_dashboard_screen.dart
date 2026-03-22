// File: lib/screens/admin/admin_dashboard_screen.dart
// Admin dashboard with system stats and quick actions

import 'package:flutter/material.dart';
import '../../core/session.dart';
import '../../services/api_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};

  // Fixed Role Colors for Admin context
  static const Color roleAdmin = Color(0xFF1565C0);
  static const Color statusSuccess = Color(0xFF4CAF50);
  static const Color statusWarning = Color(0xFFFF9800);
  static const Color statusError = Color(0xFFF44336);
  static const Color statusInfo = Color(0xFF2196F3);

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await ApiService.getAdminStats();
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Admin Dashboard'),
              Text(
                SessionManager.name ?? 'Administrator',
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => Navigator.pushNamed(context, '/backendSettings'),
              tooltip: 'Server Settings',
            ),
            IconButton(
              icon: const Icon(Icons.person_outline),
              onPressed: () => Navigator.pushNamed(context, '/adminProfile'),
              tooltip: 'Profile',
            ),
          ],
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator(color: cs.primary))
            : RefreshIndicator(
                onRefresh: _loadStats,
                color: cs.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatsGrid(cs),
                      const SizedBox(height: 24),
                      Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildQuickActions(cs),
                      const SizedBox(height: 24),
                      Text(
                        'System Overview',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSystemOverview(cs),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildStatsGrid(ColorScheme cs) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        _StatCard(
          title: 'Total Faculty',
          value: '${_stats['total_faculty'] ?? 0}',
          icon: Icons.badge_outlined,
          color: roleAdmin,
          cs: cs,
        ),
        _StatCard(
          title: 'Total Students',
          value: '${_stats['total_students'] ?? 0}',
          icon: Icons.people_outline,
          color: cs.primary,
          cs: cs,
        ),
        _StatCard(
          title: 'Departments',
          value: '${_stats['total_departments'] ?? 0}',
          icon: Icons.account_tree_outlined,
          color: statusInfo,
          cs: cs,
        ),
        _StatCard(
          title: 'Pending Issues',
          value: '${_stats['pending_complaints'] ?? 0}',
          icon: Icons.report_problem_outlined,
          color: statusWarning,
          cs: cs,
        ),
      ],
    );
  }

  Widget _buildQuickActions(ColorScheme cs) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                title: 'Manage Faculty',
                icon: Icons.badge,
                color: roleAdmin,
                onTap: () async {
                  await Navigator.pushNamed(context, '/adminFacultyManagement');
                  if (mounted) _loadStats();
                },
                cs: cs,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                title: 'Add Faculty',
                icon: Icons.person_add,
                color: statusSuccess,
                onTap: () async {
                  await Navigator.pushNamed(context, '/adminAddFaculty');
                  if (mounted) _loadStats();
                },
                cs: cs,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                title: 'Subjects & Semesters',
                icon: Icons.menu_book,
                color: statusError,
                onTap: () =>
                    Navigator.pushNamed(context, '/hodSubjectManagement'),
                cs: cs,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                title: 'Complaints',
                icon: Icons.inbox,
                color: statusWarning,
                onTap: () =>
                    Navigator.pushNamed(context, '/adminComplaintsManagement'),
                cs: cs,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                title: 'Reports',
                icon: Icons.analytics_outlined,
                color: statusInfo,
                onTap: () =>
                    Navigator.pushNamed(context, '/adminSystemReports'),
                cs: cs,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }

  Widget _buildSystemOverview(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.onSurface.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          _OverviewRow(
            label: 'Active Sessions Today',
            value: '${_stats['active_sessions'] ?? 0}',
            icon: Icons.timer_outlined,
            cs: cs,
          ),
          Divider(height: 24, color: cs.onSurface.withOpacity(0.05)),
          _OverviewRow(
            label: "Today's Attendance",
            value: '${_stats['today_attendance'] ?? 0}%',
            icon: Icons.check_circle_outline,
            cs: cs,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final ColorScheme cs;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final ColorScheme cs;

  const _QuickActionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurface,
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
}

class _OverviewRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final ColorScheme cs;

  const _OverviewRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: cs.primary, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: cs.onSurface.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
