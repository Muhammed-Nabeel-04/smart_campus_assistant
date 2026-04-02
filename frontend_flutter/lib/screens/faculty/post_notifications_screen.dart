// File: lib/screens/faculty/post_notifications_screen.dart

import 'package:flutter/material.dart';

class PostNotificationsScreen extends StatelessWidget {
  const PostNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Post Notifications')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.campaign_outlined,
              size: 80,
              color: cs.primary.withOpacity(0.2),
            ),
            const SizedBox(height: 20),
            Text(
              'Post Notifications Screen',
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
