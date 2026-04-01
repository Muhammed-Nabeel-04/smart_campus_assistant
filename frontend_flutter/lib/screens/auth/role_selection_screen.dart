// lib/screens/auth/role_selection_screen.dart
import 'package:flutter/material.dart';
import '../../core/session.dart';
import '../../main.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Check if we are currently in Dark Mode to determine icon look
    final isDark = SmartCampusApp.currentTheme == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Hides the back arrow
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // ── Theme Toggle Button ──────────────────────────────────
          IconButton(
            // Show filled moon if dark mode is active, outlined if system
            icon: Icon(
              isDark ? Icons.brightness_2 : Icons.brightness_2_outlined,
            ),
            tooltip: isDark ? 'Switch to System Theme' : 'Switch to Dark Theme',
            onPressed: () {
              setState(() {
                // Logic: If System -> Dark. If anything else (Dark) -> System.
                final newMode = SmartCampusApp.currentTheme == ThemeMode.system
                    ? ThemeMode.dark
                    : ThemeMode.system;
                SmartCampusApp.setTheme(newMode);
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.pushNamed(context, '/backendSettings'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          child: Column(
            children: [
              const SizedBox(height: 12),

              // ── Logo (Floating Emblem with Soft Glow) ─────────────
              Container(
                width: 120, // Slightly larger to show off the details
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: cs.primary.withOpacity(0.25), // Soft ambient glow
                      blurRadius:
                          60, // Wide blur so it doesn't look like a solid shape
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/college_logo.png',
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: 32),

              // ── Title ──────────────────────────────────────────
              Text(
                'Dhaanish-itech',
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Smart Campus',
                style: TextStyle(
                  color: cs.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 2,
                ),
              ),

              const SizedBox(height: 48),

              // ── Role Buttons ───────────────────────────────────
              _RoleButton(
                icon: Icons.person_rounded,
                label: 'Student',
                subtitle: 'View attendance, notices & complaints',
                color: const Color(0xFF4CAF50),
                onTap: () =>
                    Navigator.pushNamed(context, '/studentOnboardingScan'),
              ),
              const SizedBox(height: 16),
              _RoleButton(
                icon: Icons.badge_rounded,
                label: 'Faculty / HOD',
                subtitle: 'Manage sessions, classes & complaints',
                color: const Color(0xFF00BCD4),
                onTap: () => Navigator.pushNamed(context, '/facultyLogin'),
              ),
              const SizedBox(height: 16),
              _RoleButton(
                icon: Icons.account_balance_rounded,
                label: 'Principal',
                subtitle: 'Manage departments & HODs',
                color: const Color(0xFF9C27B0),
                onTap: () => Navigator.pushNamed(context, '/principalLogin'),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
//  Role Button Component
// ────────────────────────────────────────────────────────────────

class _RoleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _RoleButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isUiDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: isUiDark ? 0 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: cs.onSurface.withOpacity(isUiDark ? 0.08 : 0.1),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: cs.onSurface.withOpacity(0.55),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: cs.onSurface.withOpacity(0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
