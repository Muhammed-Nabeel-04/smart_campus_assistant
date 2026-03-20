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

class _FacultyDashboardScreenState extends State<FacultyDashboardScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _activeSessions = [];
  bool _isLoading = true;
  late AnimationController _blinkController;
  late Animation<double> _blinkAnim;

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
      await ApiService.logout();
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
                                color: AppColors.danger.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.danger),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.radio_button_checked,
                                    color: AppColors.danger,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      '${_activeSessions.length} Active Session${_activeSessions.length > 1 ? 's' : ''} Running — Tap to manage',
                                      style: const TextStyle(
                                        color: AppColors.danger,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_ios,
                                    color: AppColors.danger,
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
                          const Color(0xFF4CAF50),
                          () => _showSessionsSheet(),
                        ),
                        _buildTappableStatCard(
                          'Active Sessions',
                          '${_activeSessions.length}',
                          Icons.play_circle,
                          const Color(0xFF2196F3),
                          () => _showActiveSessionsSheet(),
                        ),
                        _buildTappableStatCard(
                          'Total Students',
                          '${_stats?['total_students'] ?? 0}',
                          Icons.people,
                          const Color(0xFFFF9800),
                          () => _showStudentsSheet(),
                        ),
                        _buildStatCard(
                          'Avg Attendance',
                          '${_stats?['average_attendance'] ?? 0}%',
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

  void _showStudentsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
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
                        // Departments for filter
                        final depts = [
                          'All',
                          ...{
                            ...allStudents.map(
                              (s) => s['department'].toString(),
                            ),
                          },
                        ];

                        // Filter
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

                        // Sort
                        filtered.sort((a, b) {
                          if (_sortBy == 'name') {
                            return (a['full_name'] ?? '').compareTo(
                              b['full_name'] ?? '',
                            );
                          } else if (_sortBy == 'register') {
                            return (a['register_number'] ?? '').compareTo(
                              b['register_number'] ?? '',
                            );
                          } else {
                            return (a['year'] ?? '').compareTo(b['year'] ?? '');
                          }
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
                                    color: Color(0xFFFF9800),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Students (${filtered.length})',
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Search
                              TextField(
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Search by name or register no...',
                                  hintStyle: const TextStyle(
                                    color: AppColors.textHint,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.search,
                                    color: AppColors.textSecondary,
                                  ),
                                  filled: true,
                                  fillColor: AppColors.bgDark,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                ),
                                onChanged: (v) =>
                                    setInner(() => _searchQuery = v),
                              ),
                              const SizedBox(height: 12),

                              // Filter by dept
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
                                                  ? const Color(0xFFFF9800)
                                                  : AppColors.bgDark,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              d.toUpperCase(),
                                              style: TextStyle(
                                                color: _filterDept == d
                                                    ? Colors.white
                                                    : AppColors.textSecondary,
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
                              const SizedBox(height: 8),

                              // Sort options
                              Row(
                                children: [
                                  const Text(
                                    'Sort:',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ...[
                                    ['name', 'Name'],
                                    ['register', 'Reg No'],
                                    ['year', 'Year'],
                                  ].map(
                                    (s) => GestureDetector(
                                      onTap: () =>
                                          setInner(() => _sortBy = s[0]),
                                      child: Container(
                                        margin: const EdgeInsets.only(right: 8),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _sortBy == s[0]
                                              ? AppColors.primary.withOpacity(
                                                  0.2,
                                                )
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: _sortBy == s[0]
                                                ? AppColors.primary
                                                : AppColors.bgSeparator,
                                          ),
                                        ),
                                        child: Text(
                                          s[1],
                                          style: TextStyle(
                                            color: _sortBy == s[0]
                                                ? AppColors.primary
                                                : AppColors.textSecondary,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Student list
                              Expanded(
                                child: filtered.isEmpty
                                    ? const Center(
                                        child: Text(
                                          'No students found',
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      )
                                    : ListView.builder(
                                        controller: scroll,
                                        itemCount: filtered.length,
                                        itemBuilder: (ctx, i) {
                                          final s = filtered[i];
                                          return Container(
                                            margin: const EdgeInsets.only(
                                              bottom: 8,
                                            ),
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: AppColors.bgDark,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Row(
                                              children: [
                                                CircleAvatar(
                                                  backgroundColor: const Color(
                                                    0xFFFF9800,
                                                  ).withOpacity(0.2),
                                                  child: Text(
                                                    (s['full_name'] ?? 'S')
                                                        .toString()
                                                        .substring(0, 1)
                                                        .toUpperCase(),
                                                    style: const TextStyle(
                                                      color: Color(0xFFFF9800),
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        s['full_name'] ?? '',
                                                        style: const TextStyle(
                                                          color: AppColors
                                                              .textPrimary,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                      Text(
                                                        '${s['register_number']} • ${s['year']} Sec ${s['section']}',
                                                        style: const TextStyle(
                                                          color: AppColors
                                                              .textSecondary,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.primary
                                                        .withOpacity(0.15),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    s['department']
                                                            ?.toString()
                                                            .toUpperCase() ??
                                                        '',
                                                    style: const TextStyle(
                                                      color: AppColors.primary,
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
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
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.radio_button_checked,
                    color: AppColors.danger,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Active Sessions',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_activeSessions.isEmpty)
                const Text(
                  'No active sessions',
                  style: TextStyle(color: AppColors.textSecondary),
                )
              else
                ..._activeSessions.map(
                  (s) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.bgDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.danger.withOpacity(0.4),
                      ),
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
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${s['class_name']} • ${s['students_present']} present',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
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
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Session ended'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.danger,
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
      ),
    );
  }

  void _showSessionsSheet() {
    String _period = 'today';
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
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
                  const Text(
                    'My Classes',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Period tabs
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
                                    ? const Color(0xFF1565C0)
                                    : AppColors.bgDark,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                p[0].toUpperCase() + p.substring(1),
                                style: TextStyle(
                                  color: _period == p
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
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
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        final sessions = snap.data ?? [];
                        if (sessions.isEmpty) {
                          return const Center(
                            child: Text(
                              'No sessions found',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          );
                        }
                        return ListView.builder(
                          controller: scroll,
                          itemCount: sessions.length,
                          itemBuilder: (ctx, i) {
                            final s = sessions[i];
                            final isActive = s['status'] == 'active';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.bgDark,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isActive
                                      ? AppColors.danger.withOpacity(0.5)
                                      : AppColors.bgSeparator,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isActive
                                        ? Icons.radio_button_checked
                                        : Icons.check_circle,
                                    color: isActive
                                        ? AppColors.danger
                                        : AppColors.success,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          s['subject_name'] ?? '',
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          '${s['class_name']} • ${s['students_present']} present',
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    s['started_at']?.toString().substring(
                                          11,
                                          16,
                                        ) ??
                                        '',
                                    style: const TextStyle(
                                      color: AppColors.textHint,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
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
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
      final isActive = session['status'] == 'active';
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? AppColors.danger.withOpacity(0.4)
                : AppColors.bgSeparator,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (isActive ? AppColors.danger : const Color(0xFF1565C0))
                    .withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isActive ? Icons.radio_button_checked : Icons.schedule,
                color: isActive ? AppColors.danger : const Color(0xFF1565C0),
              ),
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
            Text(
              session['started_at']?.toString().substring(11, 16) ?? '',
              style: const TextStyle(color: AppColors.textHint, fontSize: 11),
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
