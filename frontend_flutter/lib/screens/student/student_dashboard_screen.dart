// File: lib/screens/student/student_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
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

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
          return;
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
        if (exitApp == true) SystemNavigator.pop();
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
  Map<String, dynamic>? _nextSlot;
  int? _classId;
  bool _isLoading = true;
  late AnimationController _blinkController;
  late Animation<double> _blinkAnim;
  Timer? _pollTimer;
  Timer? _notificationTimer;
  Timer? _nextSlotTimer;
  Timer? _countdownTimer;
  DateTime? _targetClassTime;
  int _lastNotificationCount = -1;
  bool _alertSent = false;

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
    _nextSlotTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (mounted) _loadNextSlot();
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _targetClassTime != null) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _blinkController.dispose();
    _pollTimer?.cancel();
    _notificationTimer?.cancel();
    _nextSlotTimer?.cancel();
    _countdownTimer?.cancel();
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

  Future<void> _loadNextSlot() async {
    try {
      final slot = await ApiService.getNextSlotStudent(
        SessionManager.studentId!,
      );
      if (mounted) {
        setState(() {
          _nextSlot = slot.isNotEmpty ? slot : null;
          // Cache class_id directly from slot — no extra API calls needed
          if (slot.isNotEmpty && slot['class_id'] != null && _classId == null) {
            _classId = slot['class_id'] as int;
          }
          if (slot.isNotEmpty) {
            final mins = slot['minutes_until'] as int? ?? 0;
            final fetchedTarget = DateTime.now().add(Duration(minutes: mins));
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
        title: '📚 Class Starting Soon',
        body:
            '${slot['subject_name']} by ${slot['faculty_name']} in $minutesUntil min',
      );
    }
    if (minutesUntil <= 0) _alertSent = false;
  }

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
    if (hours > 0) return '${twoDigits(hours)}:$minutes:$seconds';
    return '$minutes:$seconds';
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
        // class_id is set in _loadNextSlot from the timetable slot directly
      } catch (_) {}
      await _loadNextSlot();
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

    return RefreshIndicator(
      onRefresh: _loadStats,
      color: cs.primary,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Next Class Card ───────────────────────────────
          if (_nextSlot != null) _buildNextClassCard(cs),

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

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildNextClassCard(ColorScheme cs) {
    final slot = _nextSlot!;
    final minutesUntil = slot['minutes_until'] as int? ?? 0;
    final isUrgent = minutesUntil <= 15;
    final isBlinking = minutesUntil <= 5 && minutesUntil > 0;
    final color = isUrgent ? const Color(0xFFF44336) : cs.primary;

    final timeLabel = _getRealtimeCountdownLabel();

    final card = Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.school_outlined, color: color, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Next Class',
                      style: TextStyle(
                        color: cs.onSurface.withOpacity(0.5),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        timeLabel,
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  slot['subject_name'] ?? 'Unknown',
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${slot['faculty_name']} • ${slot['day_of_week']} ${slot['start_time']}',
                  style: TextStyle(
                    color: cs.onSurface.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    // Wrap in GestureDetector to open timetable sheet
    final tappable = GestureDetector(
      onTap: () => _showTimetableSheet(cs),
      child: card,
    );

    if (isBlinking) {
      return AnimatedBuilder(
        animation: _blinkAnim,
        builder: (context, child) =>
            Opacity(opacity: _blinkAnim.value, child: tappable),
      );
    }
    return tappable;
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

  void _showTimetableSheet(ColorScheme cs) {
    bool showWeekly = false;
    // Use _classId if set, otherwise fall back to class_id from _nextSlot
    final effectiveClassId = _classId ?? (_nextSlot?['class_id'] as int?);
    final timetableFuture = effectiveClassId != null
        ? ApiService.getClassTimetable(effectiveClassId)
        : Future.value(<String, dynamic>{});
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──────────────────────────────
                  Row(
                    children: [
                      Icon(Icons.calendar_today, color: cs.primary, size: 22),
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
                        selected: {showWeekly},
                        onSelectionChanged: (v) =>
                            setSheet(() => showWeekly = v.first),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Next class highlight ─────────────────
                  if (_nextSlot != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cs.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: cs.primary.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: cs.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.schedule,
                              color: cs.primary,
                              size: 22,
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
                                  '${_nextSlot!['faculty_name']} • ${_nextSlot!['day_of_week']} ${_nextSlot!['start_time']}',
                                  style: TextStyle(
                                    color: cs.onSurface.withOpacity(0.6),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Minutes until badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: cs.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _getRealtimeCountdownLabel(),
                              style: TextStyle(
                                color: cs.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── Timetable list ───────────────────────
                  Expanded(
                    child: FutureBuilder<Map<String, dynamic>>(
                      future: timetableFuture,
                      builder: (ctx, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return Center(
                            child: CircularProgressIndicator(color: cs.primary),
                          );
                        }

                        final rawSlots =
                            (snap.data?['slots'] as Map<String, dynamic>?) ??
                                {};
                        // Normalize keys to lowercase — same fix as faculty dashboard
                        final slots = <String, List<dynamic>>{};
                        rawSlots.forEach((key, value) {
                          slots[key.trim().toLowerCase()] =
                              List<dynamic>.from(value as List? ?? []);
                        });
                        final today = _todayName().toLowerCase();
                        final days = showWeekly
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
                          (d) => slots[d]?.isNotEmpty == true,
                        );

                        if (snap.data == null ||
                            snap.data!.isEmpty ||
                            !hasAny) {
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
                                  showWeekly
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
                            final daySlots = (slots[day] as List?) ?? [];
                            if (daySlots.isEmpty) {
                              return const SizedBox();
                            }
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Day label
                                Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: 8,
                                    top: 4,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: day == today
                                          ? cs.primary
                                          : cs.onSurface.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      day == today
                                          ? 'Today'
                                          : day[0].toUpperCase() +
                                              day.substring(1),
                                      style: TextStyle(
                                        color: day == today
                                            ? cs.onPrimary
                                            : cs.onSurface.withOpacity(0.6),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                // Slots
                                ...daySlots.map(
                                  (slot) => _buildStudentSlotTile(slot, cs),
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

  Widget _buildStudentSlotTile(Map<String, dynamic> slot, ColorScheme cs) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.onSurface.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          // Time
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
                  '${slot['faculty_name']}${slot['room'] != null ? ' • ${slot['room']}' : ''}',
                  style: TextStyle(
                    color: cs.onSurface.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
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
