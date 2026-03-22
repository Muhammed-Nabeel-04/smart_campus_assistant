// File: lib/screens/student/tabs/student_attendance_tab.dart
// Detailed attendance history with filters

import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../core/session.dart';
import '../../models/complete_models.dart';

class StudentAttendanceTab extends StatefulWidget {
  const StudentAttendanceTab({super.key});

  @override
  State<StudentAttendanceTab> createState() => _StudentAttendanceTabState();
}

class _StudentAttendanceTabState extends State<StudentAttendanceTab> {
  List<AttendanceRecord> _records = [];
  List<Map<String, dynamic>> _rawRecords = [];
  bool _isLoading = true;
  String _filterBy = 'all';

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);

    try {
      final data = await ApiService.getStudentAttendanceHistory(
        SessionManager.studentId!,
      );

      setState(() {
        _rawRecords = List<Map<String, dynamic>>.from(data);
        _records = data.map<AttendanceRecord>((json) {
          return AttendanceRecord(
            id: json['id'],
            sessionId: json['id'] ?? 0,
            studentId: SessionManager.studentId ?? 0,
            status: json['status'] ?? 'absent',
            timestamp:
                DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
            remarks: json['subject'] ?? json['remarks'],
          );
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<AttendanceRecord> get _filteredRecords {
    var filtered = _records;

    if (_filterBy != 'all') {
      filtered = filtered.where((r) => r.status == _filterBy).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter bar
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFF1A2332),
          child: Row(
            children: [
              Expanded(
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'all', label: Text('All')),
                    ButtonSegment(value: 'present', label: Text('Present')),
                    ButtonSegment(value: 'absent', label: Text('Absent')),
                  ],
                  selected: {_filterBy},
                  onSelectionChanged: (Set<String> selected) {
                    setState(() => _filterBy = selected.first);
                  },
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.resolveWith((
                      states,
                    ) {
                      if (states.contains(MaterialState.selected)) {
                        return const Color(0xFF00D9FF);
                      }
                      return const Color(0xFF2A3A4A);
                    }),
                    foregroundColor: MaterialStateProperty.resolveWith((
                      states,
                    ) {
                      if (states.contains(MaterialState.selected)) {
                        return const Color(0xFF0F1419);
                      }
                      return Colors.white;
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Records list
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF00D9FF)),
                )
              : _filteredRecords.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadRecords,
                  color: const Color(0xFF00D9FF),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredRecords.length,
                    itemBuilder: (context, index) {
                      return _buildRecordCard(_filteredRecords[index]);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildRecordCard(AttendanceRecord record) {
    final isPresent = record.status == 'present';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2332),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPresent
              ? const Color(0xFF00D9FF).withOpacity(0.3)
              : const Color(0xFFFF6B6B).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          // Status icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isPresent
                  ? const Color(0xFF00D9FF).withOpacity(0.2)
                  : const Color(0xFFFF6B6B).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isPresent ? Icons.check_circle : Icons.cancel,
              color: isPresent
                  ? const Color(0xFF00D9FF)
                  : const Color(0xFFFF6B6B),
              size: 24,
            ),
          ),

          const SizedBox(width: 16),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.timestamp.toString().substring(0, 10),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  record.remarks ?? '',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
                if (record.remarks != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    record.remarks!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isPresent
                  ? const Color(0xFF00D9FF).withOpacity(0.2)
                  : const Color(0xFFFF6B6B).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isPresent ? 'Present' : 'Absent',
              style: TextStyle(
                color: isPresent
                    ? const Color(0xFF00D9FF)
                    : const Color(0xFFFF6B6B),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 80,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 20),
          Text(
            'No attendance records',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your attendance history will appear here',
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
