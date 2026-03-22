// lib/screens/auth/role_selection_screen.dart
import 'package:flutter/material.dart';
import '../../core/session.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
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
              const SizedBox(height: 24),

              // ── Logo ───────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [cs.primary, cs.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: cs.primary.withOpacity(0.35),
                      blurRadius: 40,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.school_rounded,
                  size: 64,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 32),

              // ── Title ──────────────────────────────────────────
              Text(
                'Smart Campus',
                style: TextStyle(
                  color: cs.onBackground,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'Assistant',
                style: TextStyle(
                  color: cs.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 2,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                'Select your role to continue',
                style: TextStyle(
                  color: cs.onBackground.withOpacity(0.6),
                  fontSize: 14,
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
                label: 'Faculty',
                subtitle: 'Manage sessions & post notifications',
                color: const Color(0xFF00BCD4),
                onTap: () => Navigator.pushNamed(context, '/facultyLogin'),
              ),

              const SizedBox(height: 16),

              _RoleButton(
                icon: Icons.admin_panel_settings_rounded,
                label: 'Admin / HOD',
                subtitle: 'Manage campus & resolve complaints',
                color: const Color(0xFFF44336),
                onTap: () => Navigator.pushNamed(context, '/adminLogin'),
              ),

              const SizedBox(height: 16),

              _RoleButton(
                icon: Icons.account_balance_rounded,
                label: 'Principal',
                subtitle: 'Manage departments & HODs',
                color: const Color(0xFF9C27B0),
                onTap: () => Navigator.pushNamed(context, '/principalLogin'),
              ),

              const SizedBox(height: 32),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: isDark ? 0 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark
              ? cs.onSurface.withOpacity(0.08)
              : cs.onSurface.withOpacity(0.1),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              // Icon container — role color
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 26),
              ),

              const SizedBox(width: 16),

              // Label + subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
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
                color: cs.onSurface.withOpacity(0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
