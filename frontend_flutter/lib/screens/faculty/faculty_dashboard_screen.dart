// File: lib/screens/faculty/faculty_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';
import '../../core/session.dart';
import '../../core/notification_service.dart';
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
  Map<String, dynamic>? _nextSlot;
  bool _isLoading = true;
  late AnimationController _blinkController;
  late Animation<double> _blinkAnim;
  Timer? _nextSlotTimer;
  Timer? _countdownTimer;
  DateTime? _targetClassTime;
  bool _alertSent = false;

  static const Color roleHOD = Color(0xFFF44336);
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color infoBlue = Color(0xFF2196F3);
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color principalPurple = Color(0xFF9C27B0);
  static const Color facultyCyan = Color(0xFF00BCD4);

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _blinkAnim = Tween<double>(begin: 0.3, end: 1.0).animate(_blinkController);
    _loadStats();

    // Timer to fetch backend data every minute
    _nextSlotTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) _loadNextSlot();
    });

    // Timer to update the UI countdown every second
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _targetClassTime != null) {
        setState(() {}); // Triggers rebuild to update the countdown text
      }
    });
  }

  @override
  void dispose() {
    _blinkController.dispose();
    _nextSlotTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadNextSlot() async {
    try {
      final facultyId = SessionManager.facultyId!;
      final slot = await ApiService.getNextSlotFaculty(facultyId);
      if (mounted) {
        setState(() {
          _nextSlot = slot.isNotEmpty ? slot : null;
          if (slot.isNotEmpty) {
            int mins = slot['minutes_until'] as int? ?? 0;
            DateTime fetchedTarget = DateTime.now().add(
              Duration(minutes: mins),
            );

            // Only update target if it's null, or if the server sync is off by > 1 minute (prevents UI jumping)
            if (_targetClassTime == null ||
                _targetClassTime!.difference(fetchedTarget).abs().inMinutes >
                    1) {
              _targetClassTime = fetchedTarget;
            }
          } else {
            _targetClassTime = null;
          }
        });
        _checkAndAlert(slot);
      }
    } catch (_) {}
  }

  void _checkAndAlert(Map<String, dynamic> slot) {
    if (slot.isEmpty) return;
    final minutesUntil = slot['minutes_until'] as int? ?? 999;
    if (minutesUntil <= 15 && minutesUntil > 0 && !_alertSent) {
      _alertSent = true;
      NotificationService.showNotification(
        id: DateTime.now().millisecondsSinceEpoch,
        title: '🎓 Class Starting Soon',
        body:
            '${slot['subject_name']} — ${slot['class_name']} in $minutesUntil min',
      );
    }
    if (minutesUntil <= 0) _alertSent = false;
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
      await _loadNextSlot();
      setState(() {
        _stats = {
          ...data,
          'recent_sessions': recent,
          'is_cc': data['is_cc'] ?? false,
          'cc_class_id': data['cc_class_id'],
        };
        _activeSessions = List<Map<String, dynamic>>.from(active);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _startSessionFromSlot(Map<String, dynamic> slot) async {
    final cs = Theme.of(context).colorScheme;
    try {
      if (!mounted) return;
      Navigator.pushNamed(
        context,
        '/facultyStartAttendance',
        arguments: {
          'department': {'id': 0, 'name': '', 'code': ''},
          'class': {
            'id': slot['class_id'],
            'year': slot['class_name']?.split(' Sec ')?.first ?? '',
            'section': slot['class_name']?.split(' Sec ')?.last ?? '',
          },
          'subject': {
            'id': slot['subject_id'],
            'name': slot['subject_name'],
            'code': slot['subject_code'] ?? '',
          },
          'semester': '',
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: cs.error),
      );
    }
  }

  Future<void> _handleLogout() async {
    final cs = Theme.of(context).colorScheme;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: cs.error),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await ApiService.logout();
      await SessionManager.clearSession();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false);
      }
    }
  }

  Future<void> _openCCTimetable() async {
    final ccClassId = _stats?['cc_class_id'];
    if (ccClassId == null) return;
    Navigator.pushNamed(
      context,
      '/ccTimetableEditor',
      arguments: {
        'class_id': ccClassId,
        'faculty_id': SessionManager.facultyId,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading:
              false, // <-- Add this line to hide the back button
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
                    // ── Active Session Banner ────────────────
                    if (_activeSessions.isNotEmpty)
                      GestureDetector(
                        onTap: _showActiveSessionsSheet,
                        behavior: HitTestBehavior.opaque,
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
                              // FIX: only the icon blinks, not the whole banner
                              AnimatedBuilder(
                                animation: _blinkAnim,
                                builder: (context, child) => Icon(
                                  Icons.radio_button_checked,
                                  color: roleHOD.withOpacity(_blinkAnim.value),
                                  size: 20,
                                ),
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

                    // ── Class Reminder (only shows ≤5 min before class) ──
                    if (_nextSlot != null &&
                        (_nextSlot!['minutes_until'] as int? ?? 999) <= 5)
                      _buildClassReminderBanner(cs),

                    const SizedBox(height: 16),

                    // ── Stats Grid ───────────────────────────
                    Column(
                      children: [
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: _buildTappableStatCard(
                                  'Total Classes',
                                  '${_stats?['total_sessions'] ?? 0}',
                                  Icons.class_,
                                  successGreen,
                                  _showSessionsSheet,
                                  cs,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTappableStatCard(
                                  'Active Sessions',
                                  '${_activeSessions.length}',
                                  Icons.play_circle,
                                  infoBlue,
                                  _showActiveSessionsSheet,
                                  cs,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: _buildTimetableCard(cs)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  'Avg Attendance',
                                  '${_stats?['average_attendance'] ?? 0}%',
                                  Icons.trending_up,
                                  principalPurple,
                                  cs,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ── Quick Actions ────────────────────────
                    Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionCard(
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
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildActionCard(
                                'Manual Attendance',
                                Icons.fact_check,
                                roleHOD,
                                () => Navigator.pushNamed(
                                  context,
                                  '/facultyDepartmentSelect',
                                  arguments: 'manual',
                                ),
                                cs,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionCard(
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
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildActionCard(
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
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionCard(
                                'Post Notice',
                                Icons.notifications,
                                warningOrange,
                                () => Navigator.pushNamed(
                                  context,
                                  '/facultyPostNotification',
                                ),
                                cs,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _stats?['is_cc'] == true
                                  ? _buildActionCard(
                                      'Manage Timetable',
                                      Icons.calendar_month,
                                      const Color(0xFF00BCD4),
                                      () => _openCCTimetable(),
                                      cs,
                                    )
                                  : const SizedBox(),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ── Recent Sessions ──────────────────────
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

  // ── Timetable card (rich grid cell with class details) ────────
  Widget _buildTimetableCard(ColorScheme cs) {
    return GestureDetector(
      onTap: _showTimetableSheet,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceVariant.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.onSurface.withOpacity(0.06)),
        ),
        padding: const EdgeInsets.all(12),
        child: _nextSlot != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: warningOrange,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _nextSlot!['subject_name'] ?? '',
                          style: TextStyle(
                            color: cs.onSurface,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_nextSlot!['class_name']} • ${_nextSlot!['day_of_week']}',
                    style: TextStyle(
                      color: cs.onSurface.withOpacity(0.5),
                      fontSize: 10,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_nextSlot!['start_time']} – ${_nextSlot!['end_time']}',
                    style: TextStyle(
                      color: cs.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: warningOrange.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getRealtimeCountdownLabel(),
                      style: TextStyle(
                        color: warningOrange,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: warningOrange.withOpacity(0.5),
                    size: 28,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No class',
                    style: TextStyle(
                      color: cs.onSurface.withOpacity(0.5),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ── Real-time Countdown label helper ─────────────────────────
  String _getRealtimeCountdownLabel() {
    if (_targetClassTime == null) return 'Now';
    final diff = _targetClassTime!.difference(DateTime.now());

    if (diff.inSeconds <= 0) return 'Now';

    if (diff.inHours > 24) {
      final days = diff.inHours ~/ 24;
      return days == 1 ? 'Tomorrow' : '${days}d left';
    }

    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = diff.inHours;
    final minutes = twoDigits(diff.inMinutes.remainder(60));
    final seconds = twoDigits(diff.inSeconds.remainder(60));

    if (hours > 0) {
      return '${twoDigits(hours)}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  // ── Blinking reminder banner (only shows ≤5 min before class) ──
  // FIX: Container is always visible; only the icon blinks
  Widget _buildClassReminderBanner(ColorScheme cs) {
    final slot = _nextSlot!;
    final minutesUntil = slot['minutes_until'] as int? ?? 0;

    return GestureDetector(
      onTap: () => _startSessionFromSlot(slot),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: roleHOD.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: roleHOD),
        ),
        child: Row(
          children: [
            AnimatedBuilder(
              animation: _blinkAnim,
              builder: (context, child) => Icon(
                Icons.alarm,
                color: roleHOD.withOpacity(_blinkAnim.value),
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _getRealtimeCountdownLabel() == 'Now'
                    ? '🔴 ${slot['subject_name']} is starting NOW — Tap to Start'
                    : '⏰ ${slot['subject_name']} starts in ${_getRealtimeCountdownLabel()} — Tap to Start',
                style: const TextStyle(
                  color: roleHOD,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: roleHOD,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Start',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showActiveSessionsSheet() {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    // FIX: full width so text doesn't render vertically
                    width: double.infinity,
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
                            minimumSize:
                                Size.zero, // Fixes the infinite width issue
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
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
    final cs = Theme.of(context).colorScheme;
    String period = 'today';
    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => DraggableScrollableSheet(
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
                          onTap: () => setSheet(() => period = p),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: period == p
                                  ? cs.primary
                                  : cs.onSurface.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              p[0].toUpperCase() + p.substring(1),
                              style: TextStyle(
                                color:
                                    period == p ? cs.onPrimary : cs.onSurface,
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
                      period: period,
                    ),
                    builder: (ctx, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final sessions = snap.data ?? [];
                      if (sessions.isEmpty) {
                        return Center(
                          child: Text(
                            'No sessions found',
                            style: TextStyle(
                              color: cs.onSurface.withOpacity(0.5),
                            ),
                          ),
                        );
                      }
                      return ListView.builder(
                        controller: scroll,
                        itemCount: sessions.length,
                        itemBuilder: (ctx, i) {
                          final s = sessions[i];
                          final isActive = s['status'] == 'active';
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
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
                                s['started_at']?.toString().substring(11, 16) ??
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
        ),
      ),
    );
  }

  void _showTimetableSheet() {
    final cs = Theme.of(context).colorScheme;

    // FIX 1: Move state variables OUTSIDE the builder so they don't reset on every tap!
    bool _showWeekly = false;

    // FIX 2: Cache the API call OUTSIDE so it only fetches once when the sheet opens
    final _timetableFuture = ApiService.getFacultyTimetable(
      SessionManager.facultyId!,
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.6,
            maxChildSize: 0.92,
            builder: (ctx, scroll) => Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Header ──────────────────────────────
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: warningOrange,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'My Timetable',
                        style: TextStyle(
                          color: cs.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(
                            value: false,
                            label: Text(
                              'Today',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          ButtonSegment(
                            value: true,
                            label: Text(
                              'Weekly',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                        selected: {_showWeekly},
                        onSelectionChanged: (v) =>
                            setSheet(() => _showWeekly = v.first),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Next session quick-start ──────────────
                  if (_nextSlot != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: warningOrange.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: warningOrange.withOpacity(0.35),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: warningOrange.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.schedule,
                              color: warningOrange,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _nextSlot!['subject_name'] ?? '',
                                  style: TextStyle(
                                    color: cs.onSurface,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  '${_nextSlot!['class_name']} • ${_nextSlot!['day_of_week']} ${_nextSlot!['start_time']}',
                                  style: TextStyle(
                                    color: cs.onSurface.withOpacity(0.6),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          StreamBuilder(
                            stream: Stream.periodic(const Duration(seconds: 1)),
                            builder: (context, _) {
                              final timerText = _getRealtimeCountdownLabel();
                              final isTimeToStart = timerText == 'Now';

                              return ElevatedButton(
                                onPressed: isTimeToStart
                                    ? () async {
                                        Navigator.pop(ctx);
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (c) => AlertDialog(
                                            title: const Text('Start Class?'),
                                            content: Text(
                                              'Start attendance for ${_nextSlot!['subject_name']} — ${_nextSlot!['class_name']}?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(c, false),
                                                child: const Text('Cancel'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () =>
                                                    Navigator.pop(c, true),
                                                child: const Text('Start'),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirm == true && mounted) {
                                          _startSessionFromSlot(_nextSlot!);
                                        }
                                      }
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: warningOrange,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor:
                                      warningOrange.withOpacity(0.15),
                                  disabledForegroundColor:
                                      warningOrange.withOpacity(0.8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  minimumSize: Size.zero,
                                ),
                                child: Text(
                                  isTimeToStart ? 'Start' : timerText,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── Timetable list ───────────────────────
                  Expanded(
                    child: FutureBuilder<Map<String, dynamic>>(
                      // Uses the cached future so it doesn't flicker/reload!
                      future: _timetableFuture,
                      builder: (ctx, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return Center(
                            child: CircularProgressIndicator(color: cs.primary),
                          );
                        }

                        // FIX 3: Robust parsing. Makes everything lowercase and removes spaces
                        // so database formatting errors don't hide your classes.
                        final rawSchedule =
                            (snap.data?['schedule'] as Map<String, dynamic>?) ??
                                {};
                        final schedule = <String, List<dynamic>>{};
                        rawSchedule.forEach((key, value) {
                          schedule[key.trim().toLowerCase()] =
                              List<dynamic>.from(value as List? ?? []);
                        });

                        final today = _todayName().toLowerCase();
                        final days = _showWeekly
                            ? [
                                'monday',
                                'tuesday',
                                'wednesday',
                                'thursday',
                                'friday',
                                'saturday',
                              ]
                            : [today];

                        final hasAny = days.any(
                          (d) => schedule[d]?.isNotEmpty == true,
                        );

                        if (!hasAny) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.event_busy_outlined,
                                  size: 60,
                                  color: cs.onSurface.withOpacity(0.2),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _showWeekly
                                      ? 'No classes this week'
                                      : 'No classes today',
                                  style: TextStyle(
                                    color: cs.onSurface.withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView(
                          controller: scroll,
                          children: days.map((day) {
                            final slots = schedule[day] ?? [];
                            if (slots.isEmpty) return const SizedBox();

                            // Re-capitalize the day for the UI
                            final displayDay =
                                day[0].toUpperCase() + day.substring(1);

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: 8,
                                    top: 4,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: (day == today
                                              ? cs.primary
                                              : cs.onSurface.withOpacity(0.08)),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          day == today ? 'Today' : displayDay,
                                          style: TextStyle(
                                            color: day == today
                                                ? cs.onPrimary
                                                : cs.onSurface.withOpacity(0.6),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ...slots.map(
                                  (slot) => _buildTimetableSlotTile(
                                    slot as Map<String, dynamic>,
                                    cs,
                                    ctx,
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                            );
                          }).toList(),
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

  String _todayName() {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[DateTime.now().weekday - 1];
  }

  Widget _buildTimetableSlotTile(
    Map<String, dynamic> slot,
    ColorScheme cs,
    BuildContext sheetCtx,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.onSurface.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text(
                slot['start_time'] ?? '',
                style: TextStyle(
                  color: cs.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                slot['end_time'] ?? '',
                style: TextStyle(
                  color: cs.onSurface.withOpacity(0.4),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Container(width: 1, height: 36, color: cs.onSurface.withOpacity(0.1)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slot['subject_name'] ?? '',
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${slot['class_name']}${slot['room'] != null ? ' • ${slot['room']}' : ''}',
                  style: TextStyle(
                    color: cs.onSurface.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // The IconButton (play button) has been removed from here!
        ],
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
    );
  }

  List<Widget> _buildRecentSessions(List<dynamic> sessions, ColorScheme cs) {
    return sessions.take(5).map((session) {
      final isActive = session['status'] == 'active';
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? roleHOD.withOpacity(0.4)
                : cs.onSurface.withOpacity(0.08),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isActive ? Icons.radio_button_checked : Icons.schedule,
              color: isActive ? roleHOD : cs.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session['subject_name'] ?? 'Subject',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${session['class_name']} • ${session['students_present']} present',
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              session['started_at']?.toString().substring(11, 16) ?? '',
              style: TextStyle(
                fontSize: 11,
                color: cs.onSurface.withOpacity(0.4),
              ),
            ),
          ],
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
