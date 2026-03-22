// File: lib/screens/faculty/faculty_dashboard_screen.dart
// Main faculty dashboard with stats, quick actions, and navigation

import 'package:flutter/material.dart';
import '../../core/session.dart';
import '../../services/api_service.dart';

class FacultyDashboardScreen extends StatefulWidget {
  const FacultyDashboardScreen({super.key});

  @override
  State<FacultyDashboardScreen> createState() => _FacultyDashboardScreenState();
}

class _FacultyDashboardScreenState extends State<FacultyDashboardScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _activeSessions = [];
  bool _isLoading = true;
  late AnimationController _blinkController;
  late Animation<double> _blinkAnim;

  // Fixed Role Colors from Guide
  static const Color roleHOD = Color(0xFFF44336); // Red for Alerts/Active
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color infoBlue = Color(0xFF2196F3);
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color principalPurple = Color(0xFF9C27B0);

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _blinkAnim = Tween<double>(begin: 0.3, end: 1.0).animate(_blinkController);
    _loadStats();
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final facultyId = SessionManager.facultyId!;
      final data = await ApiService.getFacultyStats(facultyId);
      final active = await ApiService.getActiveSessions(facultyId);
      final recent = await ApiService.getSessionsByPeriod(
        facultyId,
        period: 'all',
      );
      setState(() {
        _stats = {...data, 'recent_sessions': recent};
        _activeSessions = List<Map<String, dynamic>>.from(active);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    final cs = Theme.of(context).colorScheme;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cs.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Logout', style: TextStyle(color: cs.onSurface)),
        content: Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: cs.onSurface.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: cs.onSurface.withOpacity(0.6)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.error,
              foregroundColor: cs.onError,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await ApiService.logout();
      await SessionManager.clearSession();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
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
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withOpacity(0.6),
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
          color: cs.primary,
          child: _isLoading
              ? Center(child: CircularProgressIndicator(color: cs.primary))
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Active Session Blinking Banner
                    if (_activeSessions.isNotEmpty)
                      GestureDetector(
                        onTap: () => _showActiveSessionsSheet(),
                        child: AnimatedBuilder(
                          animation: _blinkAnim,
                          builder: (context, child) => Opacity(
                            opacity: _blinkAnim.value,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: roleHOD.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: roleHOD),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.radio_button_checked,
                                    color: roleHOD,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      '${_activeSessions.length} Active Session${_activeSessions.length > 1 ? 's' : ''} Running — Tap to manage',
                                      style: const TextStyle(
                                        color: roleHOD,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_ios,
                                    color: roleHOD,
                                    size: 14,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Stats Grid
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.3,
                      children: [
                        _buildTappableStatCard(
                          'Total Classes',
                          '${_stats?['total_sessions'] ?? 0}',
                          Icons.class_,
                          successGreen,
                          () => _showSessionsSheet(),
                          cs,
                        ),
                        _buildTappableStatCard(
                          'Active Sessions',
                          '${_activeSessions.length}',
                          Icons.play_circle,
                          infoBlue,
                          () => _showActiveSessionsSheet(),
                          cs,
                        ),
                        _buildTappableStatCard(
                          'Total Students',
                          '${_stats?['total_students'] ?? 0}',
                          Icons.people,
                          warningOrange,
                          () => _showStudentsSheet(),
                          cs,
                        ),
                        _buildStatCard(
                          'Avg Attendance',
                          '${_stats?['average_attendance'] ?? 0}%',
                          Icons.trending_up,
                          principalPurple,
                          cs,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Quick Actions
                    Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
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
                        _buildActionCard(
                          'Start Attendance',
                          Icons.qr_code,
                          cs.primary,
                          () => Navigator.pushNamed(
                            context,
                            '/facultyDepartmentSelect',
                            arguments: 'attendance',
                          ),
                          cs,
                        ),
                        _buildActionCard(
                          'Manual Attendance',
                          Icons.fact_check,
                          roleHOD, // Red for manual intervention
                          () => Navigator.pushNamed(
                            context,
                            '/facultyDepartmentSelect',
                            arguments: 'manual',
                          ),
                          cs,
                        ),
                        _buildActionCard(
                          'Manage Classes',
                          Icons.class_,
                          successGreen,
                          () => Navigator.pushNamed(
                            context,
                            '/facultyDepartmentSelect',
                            arguments: 'classroom',
                          ),
                          cs,
                        ),
                        _buildActionCard(
                          'View Reports',
                          Icons.assessment,
                          principalPurple,
                          () => Navigator.pushNamed(
                            context,
                            '/facultyDepartmentSelect',
                            arguments: 'reports',
                          ),
                          cs,
                        ),
                        _buildActionCard(
                          'Post Notice',
                          Icons.notifications,
                          warningOrange,
                          () => Navigator.pushNamed(
                            context,
                            '/facultyPostNotification',
                          ),
                          cs,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Recent Activity
                    Text(
                      'Recent Sessions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),

                    const SizedBox(height: 12),

                    if (_stats?['recent_sessions'] != null)
                      ..._buildRecentSessions(_stats!['recent_sessions'], cs)
                    else
                      _buildEmptyState(cs),
                  ],
                ),
        ),
      ),
    );
  }

  void _showStudentsSheet() {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          String _sortBy = 'name';
          String _filterDept = 'All';
          String _searchQuery = '';

          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.7,
            maxChildSize: 0.95,
            builder: (ctx, scroll) => FutureBuilder<List<dynamic>>(
              future: ApiService.getFacultyMyClasses(),
              builder: (ctx, classSnap) {
                if (classSnap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final classes = classSnap.data ?? [];

                return FutureBuilder<List<Map<String, dynamic>>>(
                  future:
                      Future.wait(
                        classes.map(
                          (cls) => ApiService.getClassStudents(
                            departmentId: cls['department_id'],
                            year: cls['year'],
                            section: cls['section'],
                          ),
                        ),
                      ).then(
                        (lists) => lists
                            .expand((l) => l.cast<Map<String, dynamic>>())
                            .toList(),
                      ),
                  builder: (ctx, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final allStudents = snap.data ?? [];

                    return StatefulBuilder(
                      builder: (ctx, setInner) {
                        final depts = [
                          'All',
                          ...{
                            ...allStudents.map(
                              (s) => s['department'].toString(),
                            ),
                          },
                        ];

                        var filtered = _filterDept == 'All'
                            ? allStudents
                            : allStudents
                                  .where((s) => s['department'] == _filterDept)
                                  .toList();

                        if (_searchQuery.isNotEmpty) {
                          filtered = filtered
                              .where(
                                (s) =>
                                    (s['full_name'] ?? '')
                                        .toString()
                                        .toLowerCase()
                                        .contains(_searchQuery.toLowerCase()) ||
                                    (s['register_number'] ?? '')
                                        .toString()
                                        .toLowerCase()
                                        .contains(_searchQuery.toLowerCase()),
                              )
                              .toList();
                        }

                        filtered.sort((a, b) {
                          if (_sortBy == 'name')
                            return (a['full_name'] ?? '').compareTo(
                              b['full_name'] ?? '',
                            );
                          if (_sortBy == 'register')
                            return (a['register_number'] ?? '').compareTo(
                              b['register_number'] ?? '',
                            );
                          return (a['year'] ?? '').compareTo(b['year'] ?? '');
                        });

                        return Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.people,
                                    color: warningOrange,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Students (${filtered.length})',
                                    style: TextStyle(
                                      color: cs.onSurface,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                style: TextStyle(color: cs.onSurface),
                                decoration: InputDecoration(
                                  hintText: 'Search by name or register no...',
                                  prefixIcon: const Icon(Icons.search),
                                ),
                                onChanged: (v) =>
                                    setInner(() => _searchQuery = v),
                              ),
                              const SizedBox(height: 12),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: depts
                                      .map(
                                        (d) => GestureDetector(
                                          onTap: () =>
                                              setInner(() => _filterDept = d),
                                          child: Container(
                                            margin: const EdgeInsets.only(
                                              right: 8,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _filterDept == d
                                                  ? warningOrange
                                                  : cs.onSurface.withOpacity(
                                                      0.1,
                                                    ),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              d.toUpperCase(),
                                              style: TextStyle(
                                                color: _filterDept == d
                                                    ? Colors.white
                                                    : cs.onSurface,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: filtered.isEmpty
                                    ? Center(
                                        child: Text(
                                          'No students found',
                                          style: TextStyle(
                                            color: cs.onSurface.withOpacity(
                                              0.5,
                                            ),
                                          ),
                                        ),
                                      )
                                    : ListView.builder(
                                        controller: scroll,
                                        itemCount: filtered.length,
                                        itemBuilder: (ctx, i) {
                                          final s = filtered[i];
                                          return Card(
                                            margin: const EdgeInsets.only(
                                              bottom: 8,
                                            ),
                                            child: ListTile(
                                              leading: CircleAvatar(
                                                backgroundColor: warningOrange
                                                    .withOpacity(0.2),
                                                child: Text(
                                                  (s['full_name'] ?? 'S')
                                                      .toString()
                                                      .substring(0, 1)
                                                      .toUpperCase(),
                                                  style: const TextStyle(
                                                    color: warningOrange,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              title: Text(
                                                s['full_name'] ?? '',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              subtitle: Text(
                                                '${s['register_number']} • ${s['year']} Sec ${s['section']}',
                                              ),
                                              trailing: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: cs.primary.withOpacity(
                                                    0.1,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  s['department']
                                                          ?.toString()
                                                          .toUpperCase() ??
                                                      '',
                                                  style: TextStyle(
                                                    color: cs.primary,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showActiveSessionsSheet() {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.radio_button_checked,
                  color: roleHOD,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Active Sessions',
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_activeSessions.isEmpty)
              Text(
                'No active sessions',
                style: TextStyle(color: cs.onSurface.withOpacity(0.5)),
              )
            else
              ..._activeSessions.map(
                (s) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: roleHOD.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s['subject_name'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${s['class_name']} • ${s['students_present']} present',
                              style: TextStyle(
                                color: cs.onSurface.withOpacity(0.6),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await ApiService.endAttendanceSession(
                            s['session_id'],
                          );
                          _loadStats();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: roleHOD,
                        ),
                        child: const Text('End'),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showSessionsSheet() {
    final cs = Theme.of(context).colorScheme;
    String _period = 'today';
    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.6,
            maxChildSize: 0.9,
            builder: (ctx, scroll) => Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Classes',
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: ['today', 'yesterday', 'all']
                        .map(
                          (p) => GestureDetector(
                            onTap: () => setSheet(() => _period = p),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: _period == p
                                    ? cs.primary
                                    : cs.onSurface.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                p[0].toUpperCase() + p.substring(1),
                                style: TextStyle(
                                  color: _period == p
                                      ? cs.onPrimary
                                      : cs.onSurface,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: FutureBuilder<List<dynamic>>(
                      future: ApiService.getSessionsByPeriod(
                        SessionManager.facultyId!,
                        period: _period,
                      ),
                      builder: (ctx, snap) {
                        if (snap.connectionState == ConnectionState.waiting)
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        final sessions = snap.data ?? [];
                        if (sessions.isEmpty)
                          return Center(
                            child: Text(
                              'No sessions found',
                              style: TextStyle(
                                color: cs.onSurface.withOpacity(0.5),
                              ),
                            ),
                          );

                        return ListView.builder(
                          controller: scroll,
                          itemCount: sessions.length,
                          itemBuilder: (ctx, i) {
                            final s = sessions[i];
                            final isActive = s['status'] == 'active';
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              shape: RoundedRectangleBorder(
                                side: BorderSide(
                                  color: isActive
                                      ? roleHOD.withOpacity(0.5)
                                      : Colors.transparent,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                leading: Icon(
                                  isActive
                                      ? Icons.radio_button_checked
                                      : Icons.check_circle,
                                  color: isActive ? roleHOD : successGreen,
                                ),
                                title: Text(
                                  s['subject_name'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  '${s['class_name']} • ${s['students_present']} present',
                                ),
                                trailing: Text(
                                  s['started_at']?.toString().substring(
                                        11,
                                        16,
                                      ) ??
                                      '',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: cs.onSurface.withOpacity(0.4),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTappableStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    VoidCallback onTap,
    ColorScheme cs,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 28),
                Icon(
                  Icons.open_in_new,
                  color: color.withOpacity(0.5),
                  size: 14,
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: cs.onSurface.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    ColorScheme cs,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
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
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
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

  Widget _buildActionCard(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
    ColorScheme cs,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  color: cs.onSurface,
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

  List<Widget> _buildRecentSessions(List<dynamic> sessions, ColorScheme cs) {
    return sessions.take(5).map((session) {
      final isActive = session['status'] == 'active';
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: isActive ? roleHOD.withOpacity(0.4) : Colors.transparent,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          leading: Icon(
            isActive ? Icons.radio_button_checked : Icons.schedule,
            color: isActive ? roleHOD : cs.primary,
          ),
          title: Text(
            session['subject_name'] ?? 'Subject',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            '${session['class_name']} • ${session['students_present']} present',
          ),
          trailing: Text(
            session['started_at']?.toString().substring(11, 16) ?? '',
            style: TextStyle(
              fontSize: 11,
              color: cs.onSurface.withOpacity(0.4),
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildEmptyState(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Text(
          'No recent sessions',
          style: TextStyle(color: cs.onSurface.withOpacity(0.5)),
        ),
      ),
    );
  }
}
