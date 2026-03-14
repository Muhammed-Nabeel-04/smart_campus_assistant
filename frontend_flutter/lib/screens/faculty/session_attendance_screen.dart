import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class SessionAttendanceScreen extends StatefulWidget {
  final int sessionId;

  const SessionAttendanceScreen({super.key, required this.sessionId});

  @override
  State<SessionAttendanceScreen> createState() =>
      _SessionAttendanceScreenState();
}

class _SessionAttendanceScreenState extends State<SessionAttendanceScreen> {
  List<dynamic> records = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadAttendance();
  }

  Future<void> loadAttendance() async {
    try {
      final data = await ApiService.getSessionAttendance(widget.sessionId);

      setState(() {
        records = data;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (records.isEmpty) {
      return const Scaffold(body: Center(child: Text("No attendance yet")));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Session Attendance")),
      body: ListView.builder(
        itemCount: records.length,
        itemBuilder: (context, index) {
          final r = records[index];

          return ListTile(
            leading: const Icon(Icons.person),
            title: Text("Student ID: ${r["student_id"]}"),
            subtitle: Text(r["date"].toString()),
            trailing: const Icon(Icons.check_circle, color: Colors.green),
          );
        },
      ),
    );
  }
}
