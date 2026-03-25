// File: lib/screens/faculty/cc_timetable_editor_screen.dart
// CC Faculty timetable grid editor

import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../core/session.dart';

class CCTimetableEditorScreen extends StatefulWidget {
  final int classId;
  final int facultyId;

  const CCTimetableEditorScreen({
    super.key,
    required this.classId,
    required this.facultyId,
  });

  @override
  State<CCTimetableEditorScreen> createState() =>
      _CCTimetableEditorScreenState();
}

class _CCTimetableEditorScreenState extends State<CCTimetableEditorScreen> {
  List<Map<String, dynamic>> _periods = [];
  List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];
  // grid[day][periodIndex] = slot or null
  Map<String, Map<int, Map<String, dynamic>?>> _grid = {};
  List<Map<String, dynamic>> _subjects = [];
  List<Map<String, dynamic>> _faculty = [];
  bool _isLoading = true;
  String _classInfo = '';

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    try {
      // Load period timings (Universal for all sections)
      final timings = await ApiService.getPeriodTimings();
      // Load timetable days from backend (shared with HOD)
      final days = await ApiService.getTimetableDays();
      // Load subjects for this class
      final subjects = await ApiService.getSubjectsByClass(widget.classId);
      // Load all faculty
      final faculty = await ApiService.getAllFaculty();
      // Load existing timetable
      final timetable = await ApiService.getClassTimetable(widget.classId);

      // Build grid
      final grid = <String, Map<int, Map<String, dynamic>?>>{};
      for (final day in days) {
        grid[day] = {};
        for (int i = 0; i < timings.length; i++) {
          grid[day]![i] = null;
        }
      }

      // Fill existing slots
      final slots = timetable['slots'] as Map<String, dynamic>? ?? {};
      slots.forEach((day, daySlots) {
        if (daySlots is List) {
          for (final slot in daySlots) {
            // Match slot to period index by start time
            final startTime = slot['start_time'];
            final pIdx = timings.indexWhere((p) => p['start'] == startTime);
            if (pIdx >= 0 && grid[day] != null) {
              grid[day]![pIdx] = slot;
            }
          }
        }
      });

      // Get class info
      final ccInfo = await ApiService.getCCClass(widget.facultyId);

      if (mounted) {
        setState(() {
          _periods = timings;
          _days = days;
          _subjects = List<Map<String, dynamic>>.from(subjects);
          _faculty = List<Map<String, dynamic>>.from(faculty);
          _grid = grid;
          _classInfo = ccInfo['class_name'] ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Period (Column) Management ──────────────────────────────

  void _addPeriod() async {
    final cs = Theme.of(context).colorScheme;
    final startCtrl = TextEditingController();
    final endCtrl = TextEditingController();

    // Pre-fill start time from last period's end if available
    if (_periods.isNotEmpty) {
      startCtrl.text = _periods.last['end'] ?? '';
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Period'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: startCtrl,
              decoration: const InputDecoration(
                labelText: 'Start Time (HH:MM)',
                hintText: '09:00',
              ),
              keyboardType: TextInputType.datetime,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: endCtrl,
              decoration: const InputDecoration(
                labelText: 'End Time (HH:MM)',
                hintText: '10:00',
              ),
              keyboardType: TextInputType.datetime,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (confirmed == true &&
        startCtrl.text.isNotEmpty &&
        endCtrl.text.isNotEmpty) {
      final newPeriods = [
        ..._periods,
        {
          'period': _periods.length + 1,
          'start': startCtrl.text.trim(),
          'end': endCtrl.text.trim(),
        },
      ];
      try {
        await ApiService.updatePeriodTimings(newPeriods);
        _loadAll();
      } catch (_) {
        _showSnack('Failed to add period', isError: true);
      }
    }
  }

  Future<void> _removePeriod() async {
    if (_periods.isEmpty) return;
    final cs = Theme.of(context).colorScheme;

    // Check if last period has any slots assigned
    final lastIdx = _periods.length - 1;
    final lastPeriod = _periods[lastIdx];
    final hasSlots = _days.any((day) => _grid[day]?[lastIdx] != null);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Last Period?'),
        content: Text(
          hasSlots
              ? 'P${lastIdx + 1} (${lastPeriod['start']}–${lastPeriod['end']}) has assigned slots.\n\nRemoving it will delete those slots globally.'
              : 'Remove P${lastIdx + 1} (${lastPeriod['start']}–${lastPeriod['end']})?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: cs.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Delete all slots in the last period column from backend
    for (final day in _days) {
      final slot = _grid[day]?[lastIdx];
      if (slot != null && slot['id'] != null) {
        try {
          await ApiService.deleteTimetableSlot(slot['id']);
        } catch (_) {}
      }
    }

    // Save updated period timings (without last one)
    final newPeriods = _periods.sublist(0, lastIdx);
    await ApiService.updatePeriodTimings(newPeriods);
    _loadAll();
  }

  // ── Day (Row) Management ────────────────────────────────────

  void _addDay() async {
    final days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final remaining = days.where((d) => !_days.contains(d)).toList();
    if (remaining.isEmpty) return;

    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Day'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: remaining
              .map(
                (d) => ListTile(
                  title: Text(d),
                  onTap: () => Navigator.pop(ctx, d),
                ),
              )
              .toList(),
        ),
      ),
    );

    if (selected != null) {
      setState(() {
        _days.add(selected);
        _grid[selected] = {};
        for (int i = 0; i < _periods.length; i++) {
          _grid[selected]![i] = null;
        }
      });
      // Save updated days to backend so HOD sees the change
      try {
        await ApiService.updateTimetableDays(_days);
      } catch (_) {}
    }
  }

  Future<void> _removeDay(String day) async {
    final cs = Theme.of(context).colorScheme;

    final hasSlots = _grid[day]?.values.any((s) => s != null) == true;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove $day?'),
        content: Text(
          hasSlots
              ? '$day has assigned slots. Removing it will delete those slots.'
              : 'Remove $day from the timetable?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: cs.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Delete all slots for this day from backend
    final daySlots = _grid[day]?.values ?? [];
    for (final slot in daySlots) {
      if (slot != null && slot['id'] != null) {
        try {
          await ApiService.deleteTimetableSlot(slot['id']);
        } catch (_) {}
      }
    }

    setState(() {
      _days.remove(day);
      _grid.remove(day);
    });
    // Save updated days to backend so HOD sees the change
    try {
      await ApiService.updateTimetableDays(_days);
    } catch (_) {}
  }

  // ── Grid Interactions ───────────────────────────────────────

  Future<void> _tapCell(String day, int periodIndex) async {
    final cs = Theme.of(context).colorScheme;
    final period = _periods[periodIndex];
    final existingSlot = _grid[day]?[periodIndex];

    // If cell has a slot — show edit/clear options
    if (existingSlot != null) {
      final action = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('$day — Period ${periodIndex + 1}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${existingSlot['subject_name']}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '${existingSlot['faculty_name']}',
                style: TextStyle(
                  color: cs.onSurface.withOpacity(0.6),
                  fontSize: 13,
                ),
              ),
              Text(
                '${period['start']} – ${period['end']}',
                style: TextStyle(color: cs.primary, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'clear'),
              child: Text('Clear', style: TextStyle(color: cs.error)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'edit'),
              child: const Text('Edit'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Close'),
            ),
          ],
        ),
      );

      if (action == 'clear') {
        await ApiService.deleteTimetableSlot(existingSlot['id']);
        _loadAll();
      } else if (action == 'edit') {
        _showSlotPicker(day, periodIndex, existing: existingSlot);
      }
      return;
    }

    // Empty cell — show slot picker
    _showSlotPicker(day, periodIndex);
  }

  void _showSlotPicker(
    String day,
    int periodIndex, {
    Map<String, dynamic>? existing,
  }) {
    final cs = Theme.of(context).colorScheme;
    final period = _periods[periodIndex];

    Map<String, dynamic>? selectedSubject = existing != null
        ? _subjects.firstWhere(
            (s) => s['id'] == existing['subject_id'],
            orElse: () => {},
          )
        : null;
    if (selectedSubject?.isEmpty == true) selectedSubject = null;

    Map<String, dynamic>? selectedFaculty = existing != null
        ? _faculty.firstWhere(
            (f) => f['id'] == existing['faculty_id'],
            orElse: () => {},
          )
        : null;
    if (selectedFaculty?.isEmpty == true) selectedFaculty = null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '$day — Period ${periodIndex + 1}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: cs.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${period['start']} – ${period['end']}',
                      style: TextStyle(
                        color: cs.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Select Subject',
                style: TextStyle(
                  color: cs.onSurface.withOpacity(0.5),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _subjects.map((s) {
                  final isSelected = selectedSubject?['id'] == s['id'];
                  return GestureDetector(
                    onTap: () => setSheet(() => selectedSubject = s),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? cs.primary.withOpacity(0.12)
                            : cs.surfaceVariant.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? cs.primary
                              : cs.onSurface.withOpacity(0.1),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Text(
                        s['name'] ?? '',
                        style: TextStyle(
                          color: isSelected
                              ? cs.primary
                              : cs.onSurface.withOpacity(0.8),
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text(
                'Select Faculty',
                style: TextStyle(
                  color: cs.onSurface.withOpacity(0.5),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _faculty.map((f) {
                  final isSelected = selectedFaculty?['id'] == f['id'];
                  return GestureDetector(
                    onTap: () => setSheet(() => selectedFaculty = f),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? cs.primary.withOpacity(0.12)
                            : cs.surfaceVariant.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? cs.primary
                              : cs.onSurface.withOpacity(0.1),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Text(
                        f['name'] ?? '',
                        style: TextStyle(
                          color: isSelected
                              ? cs.primary
                              : cs.onSurface.withOpacity(0.8),
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedSubject == null || selectedFaculty == null
                      ? null
                      : () async {
                          Navigator.pop(ctx);
                          try {
                            if (existing != null) {
                              await ApiService.deleteTimetableSlot(
                                existing['id'],
                              );
                            }
                            await ApiService.createTimetableSlot(
                              classId: widget.classId,
                              subjectId: selectedSubject!['id'],
                              facultyId: selectedFaculty!['id'],
                              dayOfWeek: day,
                              startTime: period['start'],
                              endTime: period['end'],
                            );
                            _loadAll();
                          } on ApiException catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e.message),
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.error,
                                ),
                              );
                            }
                          }
                        },
                  child: const Text('Save Slot'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : const Color(0xFF4CAF50),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Timetable Editor',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (_classInfo.isNotEmpty)
              Text(
                _classInfo,
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withOpacity(0.6),
                ),
              ),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: cs.primary))
          : SingleChildScrollView(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header Row (Periods) ─────────────────────────
                    Row(
                      children: [
                        // Empty Corner Box
                        Container(
                          width: 80,
                          height: 50,
                          decoration: BoxDecoration(
                            color: cs.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: cs.onSurface.withOpacity(0.1),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Day / Period',
                              style: TextStyle(
                                fontSize: 9,
                                color: cs.onSurface.withOpacity(0.4),
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),

                        // Period Boxes
                        ..._periods.asMap().entries.map((e) {
                          final i = e.key;
                          final p = e.value;
                          return Container(
                            width: 90,
                            height: 50,
                            margin: const EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(
                              color: cs.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: cs.primary.withOpacity(0.2),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'P${i + 1}',
                                  style: TextStyle(
                                    color: cs.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  '${p['start']}-${p['end']}',
                                  style: TextStyle(
                                    color: cs.primary.withOpacity(0.7),
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),

                        // Add / Remove Period Buttons (Columns)
                        GestureDetector(
                          onTap: _addPeriod,
                          child: Container(
                            width: 40,
                            height: 50,
                            decoration: BoxDecoration(
                              color: cs.surfaceVariant.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: cs.onSurface.withOpacity(0.15),
                              ),
                            ),
                            child: Icon(Icons.add, color: cs.primary, size: 20),
                          ),
                        ),
                        if (_periods.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: _removePeriod,
                            child: Container(
                              width: 40,
                              height: 50,
                              decoration: BoxDecoration(
                                color: cs.error.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: cs.error.withOpacity(0.3),
                                ),
                              ),
                              child: Icon(
                                Icons.remove,
                                color: cs.error,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),

                    // ── Grid Rows (Days) ─────────────────────────────
                    ..._days.map(
                      (day) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            // Day Box
                            Container(
                              width: 80,
                              height: 70,
                              decoration: BoxDecoration(
                                color: cs.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: cs.onSurface.withOpacity(0.1),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  day.substring(0, 3),
                                  style: TextStyle(
                                    color: cs.onSurface,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),

                            // Slot Cells
                            ..._periods.asMap().entries.map((e) {
                              final i = e.key;
                              final slot = _grid[day]?[i];
                              final isEmpty = slot == null;

                              return GestureDetector(
                                onTap: () => _tapCell(day, i),
                                child: Container(
                                  width: 90,
                                  height: 70,
                                  margin: const EdgeInsets.only(right: 4),
                                  decoration: BoxDecoration(
                                    color: isEmpty
                                        ? cs.surfaceVariant.withOpacity(0.2)
                                        : cs.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isEmpty
                                          ? cs.onSurface.withOpacity(0.08)
                                          : cs.primary.withOpacity(0.3),
                                      width: isEmpty ? 1 : 1.5,
                                    ),
                                  ),
                                  child: isEmpty
                                      ? Center(
                                          child: Icon(
                                            Icons.add,
                                            size: 18,
                                            color: cs.onSurface.withOpacity(
                                              0.25,
                                            ),
                                          ),
                                        )
                                      : Padding(
                                          padding: const EdgeInsets.all(6),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                slot['subject_name'] ?? '',
                                                style: TextStyle(
                                                  color: cs.primary,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                textAlign: TextAlign.center,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                slot['faculty_name'] ?? '',
                                                style: TextStyle(
                                                  color: cs.onSurface
                                                      .withOpacity(0.5),
                                                  fontSize: 9,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Add / Remove Day Buttons (Rows) ──────────────
                    Row(
                      children: [
                        GestureDetector(
                          onTap: _addDay,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 16,
                            ),
                            decoration: BoxDecoration(
                              color: cs.surfaceVariant.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: cs.onSurface.withOpacity(0.1),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.add, color: cs.primary, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  'Add Day',
                                  style: TextStyle(
                                    color: cs.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_days.isNotEmpty) ...[
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () => _removeDay(_days.last),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: cs.error.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: cs.error.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.remove, color: cs.error, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Remove ${_days.last}',
                                    style: TextStyle(
                                      color: cs.error,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }
}
