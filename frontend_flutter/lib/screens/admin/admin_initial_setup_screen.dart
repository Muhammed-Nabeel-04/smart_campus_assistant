// File: lib/screens/admin/admin_initial_setup_screen.dart
// HOD first-time setup: Change password + Add subjects by year

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../../core/session.dart';

class AdminInitialSetupScreen extends StatefulWidget {
  final String department; // Department from login (e.g., "AIDS", "CSE")
  final int? userId; // Used to mark setup complete locally

  const AdminInitialSetupScreen({
    super.key,
    required this.department,
    this.userId,
  });

  @override
  State<AdminInitialSetupScreen> createState() =>
      _AdminInitialSetupScreenState();
}

class _AdminInitialSetupScreenState extends State<AdminInitialSetupScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  int _currentStep = 0;

  final Map<String, YearSubjects> _yearData = {
    '1st Year': YearSubjects(selectedSemester: 1),
    '2nd Year': YearSubjects(selectedSemester: 3),
    '3rd Year': YearSubjects(selectedSemester: 5),
    '4th Year': YearSubjects(selectedSemester: 7),
  };

  final Map<String, List<int>> _yearSemesters = {
    '1st Year': [1, 2],
    '2nd Year': [3, 4],
    '3rd Year': [5, 6],
    '4th Year': [7, 8],
  };

  @override
  void dispose() {
    for (var year in _yearData.values) {
      year.dispose();
    }
    super.dispose();
  }

  Future<void> _handleComplete() async {
    final cs = Theme.of(context).colorScheme;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      List<Map<String, dynamic>> allSubjects = [];

      for (var entry in _yearData.entries) {
        String year = entry.key;
        YearSubjects yearSubjects = entry.value;

        if (yearSubjects.subjectCount > 0) {
          for (int i = 0; i < yearSubjects.subjectCount; i++) {
            String subjectName = yearSubjects.subjectControllers[i].text.trim();
            if (subjectName.isNotEmpty) {
              allSubjects.add({
                'name': subjectName,
                'department': widget.department,
                'year': year,
                'semester': yearSubjects.selectedSemester,
              });
            }
          }
        }
      }

      if (allSubjects.isNotEmpty) {
        await ApiService.createSubjectsBatch(allSubjects);
      }

      if (mounted) {
        final uid = widget.userId ?? SessionManager.userId;
        if (uid != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('hod_setup_done_$uid', true);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Setup completed successfully!'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
        Navigator.pushReplacementNamed(context, '/adminDashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: cs.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.department} HOD Setup'),
        automaticallyImplyLeading: false,
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          type: StepperType.vertical,
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep < 3) {
              setState(() => _currentStep++);
            } else {
              _handleComplete();
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            }
          },
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : details.onStepContinue,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _currentStep == 3
                                  ? 'Complete Setup'
                                  : 'Next Step',
                            ),
                    ),
                  ),
                  if (_currentStep > 0) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: details.onStepCancel,
                        child: const Text('Back'),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
          steps: [
            _buildStep(0, '1st Year Subjects', cs),
            _buildStep(1, '2nd Year Subjects', cs),
            _buildStep(2, '3rd Year Subjects', cs),
            _buildStep(3, '4th Year Subjects', cs),
          ],
        ),
      ),
    );
  }

  Step _buildStep(int index, String title, ColorScheme cs) {
    return Step(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      content: _buildYearStep(title.split(' Subjects')[0], cs),
      isActive: _currentStep >= index,
      state: _currentStep > index ? StepState.complete : StepState.indexed,
    );
  }

  Widget _buildYearStep(String year, ColorScheme cs) {
    final yearData = _yearData[year]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<int>(
          value: yearData.selectedSemester,
          decoration: const InputDecoration(
            labelText: 'Ongoing Semester',
            prefixIcon: Icon(Icons.calendar_today_outlined),
          ),
          dropdownColor: cs.surface,
          items: [
            for (int i in _yearSemesters[year]!)
              DropdownMenuItem(value: i, child: Text('Semester $i')),
          ],
          onChanged: (value) =>
              setState(() => yearData.selectedSemester = value!),
        ),

        const SizedBox(height: 16),

        DropdownButtonFormField<int>(
          value: yearData.subjectCount,
          decoration: const InputDecoration(
            labelText: 'Number of Subjects',
            prefixIcon: Icon(Icons.menu_book_outlined),
          ),
          dropdownColor: cs.surface,
          items: [
            for (int i = 0; i <= 10; i++)
              DropdownMenuItem(
                value: i,
                child: Text(i == 0 ? 'No subjects' : '$i subjects'),
              ),
          ],
          onChanged: (value) =>
              setState(() => yearData.updateSubjectCount(value!)),
        ),

        if (yearData.subjectCount > 0) ...[
          const SizedBox(height: 24),
          Text(
            'Subject Names:',
            style: TextStyle(
              color: cs.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(
            yearData.subjectCount,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextFormField(
                controller: yearData.subjectControllers[index],
                style: TextStyle(color: cs.onSurface),
                decoration: InputDecoration(
                  labelText: 'Subject ${index + 1}',
                  prefixIcon: const Icon(Icons.subject),
                  suffixIcon: IconButton(
                    icon: Icon(
                      Icons.clear,
                      size: 18,
                      color: cs.onSurface.withOpacity(0.3),
                    ),
                    onPressed: () => yearData.subjectControllers[index].clear(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class YearSubjects {
  int selectedSemester;
  int subjectCount;
  List<TextEditingController> subjectControllers;

  YearSubjects({required this.selectedSemester, this.subjectCount = 0})
    : subjectControllers = [];

  void updateSubjectCount(int newCount) {
    if (newCount > subjectControllers.length) {
      for (int i = subjectControllers.length; i < newCount; i++) {
        subjectControllers.add(TextEditingController());
      }
    } else if (newCount < subjectControllers.length) {
      for (int i = newCount; i < subjectControllers.length; i++) {
        subjectControllers[i].dispose();
      }
      subjectControllers = subjectControllers.sublist(0, newCount);
    }
    subjectCount = newCount;
  }

  void dispose() {
    for (var controller in subjectControllers) {
      controller.dispose();
    }
  }
}
