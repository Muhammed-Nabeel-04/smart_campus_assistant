// File: lib/screens/faculty/manual_attendance_screen.dart

import 'package:flutter/material.dart';

class ManualAttendanceScreen extends StatelessWidget {
  const ManualAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manual Attendance'),
        // Theme handles background and elevation automatically
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fact_check_outlined,
              size: 80,
              color: cs.primary.withOpacity(0.2),
            ),
            const SizedBox(height: 20),
            Text(
              'Manual Attendance Screen',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '(UI Implementation Pending)',
              style: TextStyle(
                fontSize: 14,
                color: cs.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
