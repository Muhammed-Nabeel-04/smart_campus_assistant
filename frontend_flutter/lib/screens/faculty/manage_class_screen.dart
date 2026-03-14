import 'package:flutter/material.dart';

class ManageClassScreen extends StatelessWidget {
  const ManageClassScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Class'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: const Center(
        child: Text(
          'Manage Class Screen (UI Coming Next)',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
