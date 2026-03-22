// File: lib/screens/principal/principal_dashboard_screen.dart
// Principal overview dashboard with college-wide statistics and management actions

import 'package:flutter/material.dart';
import '../../core/session.dart';
import '../../services/api_service.dart';

class PrincipalDashboardScreen extends StatefulWidget {
  const PrincipalDashboardScreen({super.key});

  @override
  State<PrincipalDashboardScreen> createState() =>
      _PrincipalDashboardScreenState();
}

class _PrincipalDashboardScreenState extends State<PrincipalDashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};

  // Semantic Role Colors for Principal Context
  static const Color roleDept = Color(0xFF6A1B9A);
  static const Color roleHOD = Color(0xFF1565C0);
  static const Color statusSuccess = Color(0xFF4CAF50);
  static const Color statusInfo = Color(0xFF2196F3);
  static const Color statusError = Color(0xFFF44336);

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final stats = await ApiService.getPrincipalStats();
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
              Text(
                SessionManager.displayName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Principal · Campus Overview',
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
              tooltip: 'Settings',
            ),
            IconButton(
              icon: const Icon(Icons.account_circle_outlined),
              onPressed: () =>
                  Navigator.pushNamed(context, '/principalProfile'),
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
                      // Stats Grid
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.4,
                        children: [
                          _StatCard(
                            title: 'Departments',
                            value: '${_stats['total_departments'] ?? 0}',
                            icon: Icons.account_tree_outlined,
                            color: roleDept,
                          ),
                          _StatCard(
                            title: 'HODs',
                            value: '${_stats['total_hods'] ?? 0}',
                            icon: Icons.manage_accounts_outlined,
                            color: roleHOD,
                          ),
                          _StatCard(
                            title: 'Faculty',
                            value: '${_stats['total_faculty'] ?? 0}',
                            icon: Icons.badge_outlined,
                            color: statusSuccess,
                          ),
                          _StatCard(
                            title: 'Total Students',
                            value: '${_stats['total_students'] ?? 0}',
                            icon: Icons.people_outline,
                            color: statusInfo,
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      Text(
                        'Administrative Actions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: _ActionCard(
                              title: 'Manage\nDepartments',
                              icon: Icons.business_outlined,
                              color: roleDept,
                              onTap: () => Navigator.pushNamed(
                                context,
                                '/principalDepartments',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ActionCard(
                              title: 'HOD\nControl',
                              icon: Icons.assignment_ind_outlined,
                              color: roleHOD,
                              onTap: () => Navigator.pushNamed(
                                context,
                                '/principalHODs',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _ActionCard(
                              title: 'System\nReports',
                              icon: Icons.analytics_outlined,
                              color: statusInfo,
                              onTap: () => Navigator.pushNamed(
                                context,
                                '/adminSystemReports',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ActionCard(
                              title: 'Escalated\nIssues',
                              icon: Icons.notification_important_outlined,
                              color: statusError,
                              onTap: () => Navigator.pushNamed(
                                context,
                                '/principalComplaints',
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Department Snapshot List
                      if (_stats['departments'] != null) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Department Overview',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: cs.onSurface,
                              ),
                            ),
                            Icon(
                              Icons.list_alt_rounded,
                              size: 18,
                              color: cs.primary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...(_stats['departments'] as List).map(
                          (d) => _DeptRow(dept: d),
                        ),
                      ],
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: cs.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.onSurface.withOpacity(0.05)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeptRow extends StatelessWidget {
  final Map<String, dynamic> dept;
  const _DeptRow({required this.dept});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.onSurface.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF6A1B9A).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              dept['code'] ?? '??',
              style: const TextStyle(
                color: Color(0xFF6A1B9A),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              dept['name'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
          Text(
            dept['hod_name'] ?? 'Vacant',
            style: TextStyle(
              color: dept['hod_name'] != null
                  ? const Color(0xFF4CAF50)
                  : cs.onSurface.withOpacity(0.4),
              fontSize: 12,
              fontStyle: dept['hod_name'] != null
                  ? FontStyle.normal
                  : FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
