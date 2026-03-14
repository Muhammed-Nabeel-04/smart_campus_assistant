import 'package:flutter/material.dart';

class PostNotificationsScreen extends StatelessWidget {
  const PostNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post Notifications')),
      body: const Center(
        child: Text(
          'Post Notifications Screen',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
