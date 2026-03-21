// Smart Campus Assistant — Demo Dashboard Screen
// Style: AetherOS-inspired dark dashboard with cyan/purple accents

import 'package:flutter/material.dart';
import 'dart:math' as math;

void main() {
  runApp(const SmartCampusDemoApp());
}

class SmartCampusDemoApp extends StatelessWidget {
  const SmartCampusDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Campus Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF080B14),
        textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'monospace'),
      ),
      home: const DemoDashboardScreen(),
    );
  }
}

// ── Color System ─────────────────────────────────────────────────────────────
class DC {
  static const bg = Color(0xFF080B14);
  static const surface = Color(0xFF0F1420);
  static const card = Color(0xFF131926);
  static const border = Color(0xFF1E2840);
  static const cyan = Color(0xFF00D9FF);
  static const purple = Color(0xFF7C6FFF);
  static const green = Color(0xFF00E676);
  static const orange = Color(0xFFFF9500);
  static const red = Color(0xFFFF4757);
  static const textPri = Color(0xFFE8EDF5);
  static const textSec = Color(0xFF6B7A99);
  static const textHint = Color(0xFF3D4F6B);
}

class DemoDashboardScreen extends StatefulWidget {
  const DemoDashboardScreen({super.key});

  @override
  State<DemoDashboardScreen> createState() => _DemoDashboardScreenState();
}

class _DemoDashboardScreenState extends State<DemoDashboardScreen>
    with TickerProviderStateMixin {
  int _selectedNav = 0;
  late AnimationController _pulseCtrl;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  final _navItems = [
    {'icon': Icons.dashboard_outlined, 'label': 'Overview'},
    {'icon': Icons.people_outline, 'label': 'Students'},
    {'icon': Icons.fact_check_outlined, 'label': 'Attendance'},
    {'icon': Icons.report_problem_outlined, 'label': 'Complaints'},
    {'icon': Icons.settings_outlined, 'label': 'Settings'},
  ];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DC.bg,
      bottomNavigationBar: _buildBottomNav(),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Column(
          children: [
            _buildMobileTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Overview',
                        style: TextStyle(
                          color: DC.textPri,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    _buildStatsMobile(),
                    const SizedBox(height: 16),
                    _buildAttendanceChart(),
                    const SizedBox(height: 16),
                    _buildRecentSessionsMobile(),
                    const SizedBox(height: 16),
                    _buildComplaintsPanel(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: DC.surface,
        border: Border(top: BorderSide(color: DC.border)),
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedNav,
        onTap: (i) => setState(() => _selectedNav = i),
        backgroundColor: Colors.transparent,
        selectedItemColor: DC.cyan,
        unselectedItemColor: DC.textHint,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        items: _navItems
            .map(
              (item) => BottomNavigationBarItem(
                icon: Icon(item['icon'] as IconData, size: 20),
                label: item['label'] as String,
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildMobileTopBar() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 12,
      ),
      decoration: const BoxDecoration(
        color: DC.surface,
        border: Border(bottom: BorderSide(color: DC.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [DC.cyan, DC.purple]),
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Icon(Icons.school, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          const Text(
            'SmartCampus',
            style: TextStyle(
              color: DC.textPri,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Stack(
            children: [
              const Icon(
                Icons.notifications_outlined,
                color: DC.textSec,
                size: 22,
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: DC.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [DC.purple, DC.cyan]),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'P',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsMobile() {
    final stats = [
      {
        'label': 'Total Students',
        'value': '1,248',
        'change': '+12',
        'color': DC.cyan,
        'icon': Icons.people_outline,
      },
      {
        'label': 'Active Sessions',
        'value': '3',
        'change': 'LIVE',
        'color': DC.green,
        'icon': Icons.radio_button_checked,
      },
      {
        'label': 'Open Complaints',
        'value': '7',
        'change': '+2',
        'color': DC.orange,
        'icon': Icons.report_problem_outlined,
      },
      {
        'label': 'Avg Attendance',
        'value': '78.4%',
        'change': '-1.2%',
        'color': DC.purple,
        'icon': Icons.trending_up,
      },
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: stats.map((s) {
        final color = s['color'] as Color;
        final isLive = s['change'] == 'LIVE';
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: DC.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: DC.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(s['icon'] as IconData, color: color, size: 14),
                  const Spacer(),
                  if (isLive)
                    AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (_, __) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: DC.green.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: DC.green,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: DC.green.withOpacity(
                                      _pulseCtrl.value,
                                    ),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 3),
                            const Text(
                              'LIVE',
                              style: TextStyle(
                                color: DC.green,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Text(
                      s['change'] as String,
                      style: TextStyle(
                        color: (s['change'] as String).startsWith('-')
                            ? DC.red
                            : DC.green,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s['value'] as String,
                    style: TextStyle(
                      color: color,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    s['label'] as String,
                    style: const TextStyle(color: DC.textSec, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentSessionsMobile() {
    final sessions = [
      {
        'subject': 'Advanced Mathematics',
        'class': '3rd Year • Sec A',
        'pct': 0.90,
        'status': 'ended',
        'time': '2h ago',
      },
      {
        'subject': 'Data Structures',
        'class': '2nd Year • Sec B',
        'pct': 0.83,
        'status': 'active',
        'time': 'Now',
      },
      {
        'subject': 'Physics Lab',
        'class': '1st Year • Sec A',
        'pct': 0.68,
        'status': 'ended',
        'time': '4h ago',
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: DC.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DC.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Recent Sessions',
              style: TextStyle(
                color: DC.textPri,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(color: DC.border, height: 1),
          ...sessions.map((s) {
            final pct = s['pct'] as double;
            final isActive = s['status'] == 'active';
            final color = pct >= 0.75
                ? DC.green
                : pct >= 0.6
                ? DC.orange
                : DC.red;
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: DC.border, width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isActive ? DC.green : DC.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s['subject'] as String,
                          style: const TextStyle(
                            color: DC.textPri,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          s['class'] as String,
                          style: const TextStyle(
                            color: DC.textSec,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${(pct * 100).toInt()}%',
                        style: TextStyle(
                          color: color,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? DC.green.withOpacity(0.15)
                              : DC.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isActive
                                ? DC.green.withOpacity(0.4)
                                : DC.border,
                          ),
                        ),
                        child: Text(
                          isActive ? 'active' : s['time'] as String,
                          style: TextStyle(
                            color: isActive ? DC.green : DC.textSec,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Sidebar ─────────────────────────────────────────────────────────────────
  Widget _buildSidebar() {
    return Container(
      width: 220,
      decoration: const BoxDecoration(
        color: DC.surface,
        border: Border(right: BorderSide(color: DC.border, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [DC.cyan, DC.purple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.school,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SmartCampus',
                      style: TextStyle(
                        color: DC.textPri,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'Assistant',
                      style: TextStyle(color: DC.textSec, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(color: DC.border, height: 1),
          ),

          const SizedBox(height: 16),

          // Nav items
          ...List.generate(_navItems.length, (i) {
            final item = _navItems[i];
            final isSelected = _selectedNav == i;
            return GestureDetector(
              onTap: () => setState(() => _selectedNav = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? DC.cyan.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: isSelected
                      ? Border.all(color: DC.cyan.withOpacity(0.3))
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      item['icon'] as IconData,
                      size: 16,
                      color: isSelected ? DC.cyan : DC.textSec,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      item['label'] as String,
                      style: TextStyle(
                        color: isSelected ? DC.cyan : DC.textSec,
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    if (i == 3) ...[
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: DC.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          '2',
                          style: TextStyle(color: DC.red, fontSize: 10),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),

          const Spacer(),

          // User profile at bottom
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: DC.card,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: DC.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [DC.purple, DC.cyan],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        'P',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Principal',
                        style: TextStyle(
                          color: DC.textPri,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Admin',
                        style: TextStyle(color: DC.textSec, fontSize: 10),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Icon(Icons.more_horiz, color: DC.textHint, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Top Bar ──────────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: DC.surface,
        border: Border(bottom: BorderSide(color: DC.border, width: 1)),
      ),
      child: Row(
        children: [
          const Text(
            'Overview',
            style: TextStyle(
              color: DC.textPri,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          // Search
          Container(
            width: 200,
            height: 34,
            decoration: BoxDecoration(
              color: DC.card,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: DC.border),
            ),
            child: const Row(
              children: [
                SizedBox(width: 10),
                Icon(Icons.search, color: DC.textHint, size: 16),
                SizedBox(width: 8),
                Text(
                  'Search...',
                  style: TextStyle(color: DC.textHint, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Notification bell
          Stack(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: DC.card,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: DC.border),
                ),
                child: const Icon(
                  Icons.notifications_outlined,
                  color: DC.textSec,
                  size: 16,
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: DC.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Stats Row ────────────────────────────────────────────────────────────────
  Widget _buildStatsRow() {
    final stats = [
      {
        'label': 'Total Students',
        'value': '1,248',
        'change': '+12',
        'color': DC.cyan,
        'icon': Icons.people_outline,
      },
      {
        'label': 'Active Sessions',
        'value': '3',
        'change': 'LIVE',
        'color': DC.green,
        'icon': Icons.radio_button_checked,
      },
      {
        'label': 'Open Complaints',
        'value': '7',
        'change': '+2',
        'color': DC.orange,
        'icon': Icons.report_problem_outlined,
      },
      {
        'label': 'Avg Attendance',
        'value': '78.4%',
        'change': '-1.2%',
        'color': DC.purple,
        'icon': Icons.trending_up,
      },
    ];

    return Row(
      children: stats.map((s) {
        final color = s['color'] as Color;
        final isLive = s['change'] == 'LIVE';
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(
              right: stats.indexOf(s) < stats.length - 1 ? 16 : 0,
            ),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: DC.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: DC.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(s['icon'] as IconData, color: color, size: 16),
                    const Spacer(),
                    if (isLive)
                      AnimatedBuilder(
                        animation: _pulseCtrl,
                        builder: (_, __) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: DC.green.withOpacity(
                              0.1 + _pulseCtrl.value * 0.1,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: DC.green.withOpacity(0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: DC.green,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: DC.green.withOpacity(
                                        _pulseCtrl.value,
                                      ),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'LIVE',
                                style: TextStyle(
                                  color: DC.green,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Text(
                        s['change'] as String,
                        style: TextStyle(
                          color: (s['change'] as String).startsWith('-')
                              ? DC.red
                              : DC.green,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  s['value'] as String,
                  style: TextStyle(
                    color: color,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  s['label'] as String,
                  style: const TextStyle(color: DC.textSec, fontSize: 12),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Recent Sessions ──────────────────────────────────────────────────────────
  Widget _buildRecentSessions() {
    final sessions = [
      {
        'subject': 'Advanced Mathematics',
        'class': '3rd Year • Section A',
        'faculty': 'Dr. Rahman',
        'present': 38,
        'total': 42,
        'status': 'ended',
        'time': '2h ago',
      },
      {
        'subject': 'Data Structures',
        'class': '2nd Year • Section B',
        'faculty': 'Prof. Sharma',
        'present': 29,
        'total': 35,
        'status': 'active',
        'time': 'Now',
      },
      {
        'subject': 'Physics Lab',
        'class': '1st Year • Section A',
        'faculty': 'Dr. Kumar',
        'present': 45,
        'total': 50,
        'status': 'ended',
        'time': '4h ago',
      },
      {
        'subject': 'Computer Networks',
        'class': '3rd Year • Section B',
        'faculty': 'Ms. Priya',
        'present': 31,
        'total': 38,
        'status': 'ended',
        'time': '6h ago',
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: DC.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DC.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                const Text(
                  'Recent Sessions',
                  style: TextStyle(
                    color: DC.textPri,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: DC.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: DC.border),
                  ),
                  child: const Text(
                    'All sessions',
                    style: TextStyle(color: DC.textSec, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: DC.border, height: 1),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Row(
              children: const [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Subject',
                    style: TextStyle(color: DC.textHint, fontSize: 11),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Faculty',
                    style: TextStyle(color: DC.textHint, fontSize: 11),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Attend.',
                    style: TextStyle(color: DC.textHint, fontSize: 11),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Status',
                    style: TextStyle(color: DC.textHint, fontSize: 11),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Time',
                    style: TextStyle(color: DC.textHint, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: DC.border, height: 1),
          ...sessions.map((s) {
            final pct = (s['present'] as int) / (s['total'] as int) * 100;
            final isActive = s['status'] == 'active';
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                border: const Border(
                  bottom: BorderSide(color: DC.border, width: 0.5),
                ),
                color: isActive
                    ? DC.green.withOpacity(0.03)
                    : Colors.transparent,
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s['subject'] as String,
                          style: const TextStyle(
                            color: DC.textPri,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          s['class'] as String,
                          style: const TextStyle(
                            color: DC.textSec,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      s['faculty'] as String,
                      style: const TextStyle(color: DC.textSec, fontSize: 12),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${pct.toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: pct >= 75
                                ? DC.green
                                : pct >= 60
                                ? DC.orange
                                : DC.red,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${s['present']}/${s['total']}',
                          style: const TextStyle(
                            color: DC.textHint,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? DC.green.withOpacity(0.15)
                            : DC.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isActive
                              ? DC.green.withOpacity(0.4)
                              : DC.border,
                        ),
                      ),
                      child: Text(
                        isActive ? 'active' : 'ended',
                        style: TextStyle(
                          color: isActive ? DC.green : DC.textSec,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      s['time'] as String,
                      style: const TextStyle(color: DC.textHint, fontSize: 11),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Complaints Panel ─────────────────────────────────────────────────────────
  Widget _buildComplaintsPanel() {
    final complaints = [
      {
        'title': 'Hostel food quality',
        'student': 'Nabeel K.',
        'priority': 'Critical',
        'color': DC.red,
        'status': 'Escalated',
      },
      {
        'title': 'Library access issue',
        'student': 'Fathima A.',
        'priority': 'Medium',
        'color': DC.orange,
        'status': 'Pending',
      },
      {
        'title': 'AC not working',
        'student': 'Rahul M.',
        'priority': 'High',
        'color': DC.orange,
        'status': 'In Progress',
      },
      {
        'title': 'Exam schedule clash',
        'student': 'Arjun P.',
        'priority': 'High',
        'color': DC.orange,
        'status': 'Pending',
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: DC.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DC.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                const Text(
                  'Complaints',
                  style: TextStyle(
                    color: DC.textPri,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: DC.red.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    '7',
                    style: TextStyle(
                      color: DC.red,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: DC.border, height: 1),
          ...complaints.map((c) {
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: DC.border, width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 36,
                    decoration: BoxDecoration(
                      color: c['color'] as Color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c['title'] as String,
                          style: const TextStyle(
                            color: DC.textPri,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          c['student'] as String,
                          style: const TextStyle(
                            color: DC.textSec,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: (c['color'] as Color).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          c['priority'] as String,
                          style: TextStyle(
                            color: c['color'] as Color,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        c['status'] as String,
                        style: const TextStyle(color: DC.textSec, fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
          Padding(
            padding: const EdgeInsets.all(14),
            child: GestureDetector(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: DC.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: DC.border),
                ),
                child: const Text(
                  'View all complaints',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: DC.textSec, fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Attendance Chart (Bar) ───────────────────────────────────────────────────
  Widget _buildAttendanceChart() {
    final data = [
      {'day': 'Mon', 'pct': 0.82},
      {'day': 'Tue', 'pct': 0.75},
      {'day': 'Wed', 'pct': 0.91},
      {'day': 'Thu', 'pct': 0.68},
      {'day': 'Fri', 'pct': 0.78},
      {'day': 'Sat', 'pct': 0.55},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DC.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DC.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Attendance This Week',
                style: TextStyle(
                  color: DC.textPri,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              _legendDot(DC.cyan, 'Present'),
              const SizedBox(width: 16),
              _legendDot(DC.border, 'Absent'),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.map((d) {
                final pct = d['pct'] as double;
                final color = pct >= 0.75
                    ? DC.cyan
                    : pct >= 0.6
                    ? DC.orange
                    : DC.red;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${(pct * 100).toInt()}%',
                          style: TextStyle(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            // Background bar
                            Container(
                              height: 90,
                              decoration: BoxDecoration(
                                color: DC.border.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            // Value bar
                            Container(
                              height: 90 * pct,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [color.withOpacity(0.6), color],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          d['day'] as String,
                          style: const TextStyle(
                            color: DC.textSec,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(color: DC.textSec, fontSize: 11)),
      ],
    );
  }
}
