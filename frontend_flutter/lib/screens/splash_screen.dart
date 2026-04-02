// File: lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import '../core/session.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    _navigate();
  }

  Future<void> _navigate() async {
    // Just wait for 1.5 seconds to let the user see the beautiful animation
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    final route = SessionManager.getInitialRoute();
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),

                  // ── Logo ───────────────────────────────────────
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: cs.primary.withOpacity(0.18),
                          blurRadius: 60,
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/college_logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── College Name ───────────────────────────────
                  Text(
                    'Dhaanish-itech',
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'Smart Campus',
                    style: TextStyle(
                      color: cs.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 3,
                    ),
                  ),

                  const Spacer(),

                  // ── Loading Indicator ──────────────────────────
                  Padding(
                    padding: const EdgeInsets.only(bottom: 48),
                    child: Column(
                      children: [
                        SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: cs.primary.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Loading...',
                          style: TextStyle(
                            color: cs.onSurface.withOpacity(0.35),
                            fontSize: 12,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
