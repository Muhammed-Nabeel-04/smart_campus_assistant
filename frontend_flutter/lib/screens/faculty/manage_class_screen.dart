// File: lib/screens/faculty/manage_class_screen.dart

import 'package:flutter/material.dart';

class ManageClassScreen extends StatelessWidget {
  const ManageClassScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Class'),
        // backgroundColor and elevation removed to let theme handle it
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.class_outlined,
              size: 80,
              color: cs.primary.withOpacity(0.2),
            ),
            const SizedBox(height: 20),
            Text(
              'Manage Class Screen',
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
