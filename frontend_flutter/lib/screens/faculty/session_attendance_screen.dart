// File: lib/screens/faculty/session_attendance_screen.dart

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
      if (mounted) {
        setState(() {
          records = data;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Session Attendance"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadAttendance,
          ),
        ],
      ),
      body: loading
          ? Center(child: CircularProgressIndicator(color: cs.primary))
          : records.isEmpty
          ? _buildEmptyState(cs)
          : RefreshIndicator(
              onRefresh: loadAttendance,
              color: cs.primary,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: records.length,
                itemBuilder: (context, index) {
                  final r = records[index];
                  return _buildAttendanceCard(r, cs);
                },
              ),
            ),
    );
  }

  Widget _buildAttendanceCard(Map<String, dynamic> record, ColorScheme cs) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.onSurface.withOpacity(0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: cs.primary.withOpacity(0.1),
          child: Icon(Icons.person_outline, color: cs.primary),
        ),
        title: Text(
          record["full_name"] ?? "Student ID: ${record["student_id"]}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              "Marked at: ${record["timestamp"] ?? record["date"]}",
              style: TextStyle(
                color: cs.onSurface.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, color: Color(0xFF4CAF50), size: 20),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_ind_outlined,
            size: 80,
            color: cs.onSurface.withOpacity(0.1),
          ),
          const SizedBox(height: 16),
          Text(
            "No attendance records yet",
            style: TextStyle(
              fontSize: 18,
              color: cs.onSurface.withOpacity(0.5),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Pull down to refresh",
            style: TextStyle(
              fontSize: 14,
              color: cs.onSurface.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }
}
