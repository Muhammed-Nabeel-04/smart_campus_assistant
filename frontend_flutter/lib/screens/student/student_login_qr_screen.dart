import 'package:flutter/material.dart';

class StudentLoginQRScreen extends StatelessWidget {
  const StudentLoginQRScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Login QR')),
      body: const Center(
        child: Text('Student Login QR Screen', style: TextStyle(fontSize: 20)),
      ),
    );
  }
}
