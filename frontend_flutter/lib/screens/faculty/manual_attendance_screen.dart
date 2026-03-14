import 'package:flutter/material.dart';

class ManualAttendanceScreen extends StatelessWidget {
  const ManualAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manual Attendance')),
      body: const Center(
        child: Text('Manual Attendance Screen', style: TextStyle(fontSize: 20)),
      ),
    );
  }
}
