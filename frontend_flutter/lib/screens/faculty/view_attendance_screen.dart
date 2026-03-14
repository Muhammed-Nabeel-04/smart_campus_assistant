import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../core/app_colors.dart';

class ViewAttendanceScreen extends StatefulWidget {
  const ViewAttendanceScreen({super.key});

  @override
  State<ViewAttendanceScreen> createState() => _ViewAttendanceScreenState();
}

class _ViewAttendanceScreenState extends State<ViewAttendanceScreen> {
  List<dynamic> _students = [];
  bool _loading = true;
  String? _subjectName;
  String? _className;
  int? _classId;
  int? _subjectId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final classData = args?['class'] as Map<String, dynamic>?;
    final subject = args?['subject'] as Map<String, dynamic>?;

    _classId = classData?['id'];
    _subjectId = subject?['id'];
    _subjectName = subject?['name'] ?? 'Subject';
    _className = '${classData?['year']} - Section ${classData?['section']}';

    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    if (_classId == null || _subjectId == null) {
      setState(() => _loading = false);
      return;
    }

    setState(() => _loading = true);

    try {
      final data = await ApiService.getAttendanceReports(
        classId: _classId!,
        subjectId: _subjectId!,
      );

      if (mounted) {
        setState(() {
          _students = data['students'] ?? [];
          _loading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.danger),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _getAttendanceColor(dynamic percentage) {
    final pct = (percentage ?? 0).toDouble();
    if (pct >= 75) return Colors.green;
    if (pct >= 60) return Colors.orange;
    return AppColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgCard,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _subjectName ?? 'Attendance',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (_className != null)
              Text(
                _className!,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _loadAttendance,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _students.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bar_chart_outlined,
                    size: 80,
                    color: AppColors.textSecondary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No attendance records yet',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadAttendance,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _students.length,
                itemBuilder: (context, index) {
                  final s = _students[index];
                  final percentage = s['attendance_percentage'] ?? 0;
                  final color = _getAttendanceColor(percentage);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        // Avatar
                        CircleAvatar(
                          backgroundColor: color.withOpacity(0.2),
                          child: Text(
                            (s['full_name'] ?? '?')[0].toUpperCase(),
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Name + register number
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s['full_name'] ?? 'Unknown',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                s['register_number'] ?? '',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Percentage
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${percentage.toStringAsFixed(1)}%',
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '${s['attended']}/${s['total']} classes',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}
