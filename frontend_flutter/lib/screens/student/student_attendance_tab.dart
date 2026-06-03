// File: lib/screens/student/student_attendance_tab.dart
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../core/session.dart';
import '../../models/complete_models.dart';
import '../../widgets/skeleton.dart';

class StudentAttendanceTab extends StatefulWidget {
  const StudentAttendanceTab({super.key});

  @override
  State<StudentAttendanceTab> createState() => _StudentAttendanceTabState();
}

class _StudentAttendanceTabState extends State<StudentAttendanceTab> {
  List<AttendanceRecord> _records = [];
  bool _isLoading = true;
  String _filterBy = 'all';

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final studentId = SessionManager.studentId;
    if (studentId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getStudentAttendanceHistory(studentId);
      setState(() {
        _records = data.map<AttendanceRecord>((json) {
          return AttendanceRecord(
            id: json['id'],
            sessionId: json['id'] ?? 0,
            studentId: studentId,
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
    if (_filterBy == 'all') return _records;
    return _records.where((r) => r.status == _filterBy).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        // ── Filter Bar ────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: cs.surface,
          // We wrap the button in a SizedBox to force it to full width
          child: SizedBox(
            width: double.infinity, // <-- This is the magic line
            child: SegmentedButton<String>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 'all', label: Text('All')),
                ButtonSegment(value: 'present', label: Text('Present')),
                ButtonSegment(value: 'absent', label: Text('Absent')),
              ],
              selected: {_filterBy},
              onSelectionChanged: (Set<String> selected) {
                setState(() => _filterBy = selected.first);
              },
            ),
          ),
        ),

        // ── Records List ──────────────────────────────────────
        Expanded(
          child: _isLoading
              ? ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: 6,
                  itemBuilder: (context, index) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        const Skeleton(
                            width: 48,
                            height: 48,
                            borderRadius:
                                BorderRadius.all(Radius.circular(12))),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Skeleton(width: 120, height: 20),
                              SizedBox(height: 8),
                              Skeleton(width: 180, height: 16),
                            ],
                          ),
                        ),
                        const Skeleton(
                            width: 60,
                            height: 24,
                            borderRadius:
                                BorderRadius.all(Radius.circular(12))),
                      ],
                    ),
                  ),
                )
              : _filteredRecords.isEmpty
                  ? _buildEmptyState(cs)
                  : RefreshIndicator(
                      onRefresh: _loadRecords,
                      color: cs.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredRecords.length,
                        itemBuilder: (context, index) =>
                            _buildRecordCard(_filteredRecords[index], cs),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildRecordCard(AttendanceRecord record, ColorScheme cs) {
    final isPresent = record.status == 'present';
    final statusColor = isPresent ? const Color(0xFF4CAF50) : cs.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // ── Status Icon ───────────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isPresent ? Icons.check_circle : Icons.cancel,
              color: statusColor,
              size: 24,
            ),
          ),

          const SizedBox(width: 16),

          // ── Details ───────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.timestamp.toString().substring(0, 10),
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  record.remarks ?? '',
                  style: TextStyle(
                    color: cs.onSurface.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // ── Status Badge ──────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isPresent ? 'Present' : 'Absent',
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 80,
            color: cs.onBackground.withOpacity(0.3),
          ),
          const SizedBox(height: 20),
          Text(
            'No attendance records',
            style: TextStyle(
              color: cs.onBackground.withOpacity(0.5),
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your attendance history will appear here',
            style: TextStyle(
              color: cs.onBackground.withOpacity(0.3),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
