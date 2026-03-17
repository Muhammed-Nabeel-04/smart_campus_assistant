// File: lib/screens/admin/admin_initial_setup_screen.dart
// HOD first-time setup: Change password + Add subjects by year

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_colors.dart';
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

  // ✅ Semesters per year
  final Map<String, List<int>> _yearSemesters = {
    '1st Year': [1, 2],
    '2nd Year': [3, 4],
    '3rd Year': [5, 6],
    '4th Year': [7, 8],
  };

  @override
  void dispose() {
    // Dispose subject controllers
    for (var year in _yearData.values) {
      year.dispose();
    }
    super.dispose();
  }

  Future<void> _handleComplete() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Add all subjects
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

      // Batch create subjects
      if (allSubjects.isNotEmpty) {
        await ApiService.createSubjectsBatch(allSubjects);
      }

      if (mounted) {
        // Mark setup complete locally so login skips wizard next time
        final uid = widget.userId ?? SessionManager.userId;
        if (uid != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('hod_setup_done_$uid', true);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Setup completed successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pushReplacementNamed(context, '/adminDashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: Text('${widget.department} HOD Setup'),
        automaticallyImplyLeading: false,
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
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
                  if (_currentStep > 0)
                    TextButton(
                      onPressed: details.onStepCancel,
                      child: const Text('Back'),
                    ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : details.onStepContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(_currentStep == 3 ? 'Complete Setup' : 'Next'),
                  ),
                ],
              ),
            );
          },
          steps: [
            // Step 0: 1st Year Subjects
            Step(
              title: const Text('1st Year Subjects'),
              content: _buildYearStep('1st Year'),
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            ),

            // Step 1: 2nd Year Subjects
            Step(
              title: const Text('2nd Year Subjects'),
              content: _buildYearStep('2nd Year'),
              isActive: _currentStep >= 1,
              state: _currentStep > 1 ? StepState.complete : StepState.indexed,
            ),

            // Step 2: 3rd Year Subjects
            Step(
              title: const Text('3rd Year Subjects'),
              content: _buildYearStep('3rd Year'),
              isActive: _currentStep >= 2,
              state: _currentStep > 2 ? StepState.complete : StepState.indexed,
            ),

            // Step 3: 4th Year Subjects
            Step(
              title: const Text('4th Year Subjects'),
              content: _buildYearStep('4th Year'),
              isActive: _currentStep >= 3,
              state: StepState.indexed,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYearStep(String year) {
    final yearData = _yearData[year]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<int>(
          value: yearData.selectedSemester,
          decoration: const InputDecoration(
            labelText: 'Ongoing Semester',
            prefixIcon: Icon(Icons.calendar_today),
          ),
          items: [
            for (int i in _yearSemesters[year]!)
              DropdownMenuItem(value: i, child: Text('Semester $i')),
          ],
          onChanged: (value) {
            setState(() {
              yearData.selectedSemester = value!;
            });
          },
        ),

        const SizedBox(height: 24),

        // Number of Subjects
        DropdownButtonFormField<int>(
          value: yearData.subjectCount,
          decoration: const InputDecoration(
            labelText: 'Number of Subjects',
            prefixIcon: Icon(Icons.book),
          ),
          items: [
            for (int i = 0; i <= 10; i++)
              DropdownMenuItem(
                value: i,
                child: Text(i == 0 ? 'No subjects' : '$i subjects'),
              ),
          ],
          onChanged: (value) {
            setState(() {
              yearData.updateSubjectCount(value!);
            });
          },
        ),

        const SizedBox(height: 24),

        // Subject Input Fields
        if (yearData.subjectCount > 0) ...[
          const Text(
            'Enter Subject Names:',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),

          ...List.generate(
            yearData.subjectCount,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextFormField(
                controller: yearData.subjectControllers[index],
                decoration: InputDecoration(
                  labelText: 'Subject ${index + 1}',
                  prefixIcon: const Icon(Icons.subject),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      yearData.subjectControllers[index].clear();
                    },
                  ),
                ),
                validator: (value) {
                  // Optional validation - subjects can be empty
                  return null;
                },
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
      // Add more controllers
      for (int i = subjectControllers.length; i < newCount; i++) {
        subjectControllers.add(TextEditingController());
      }
    } else if (newCount < subjectControllers.length) {
      // Remove excess controllers
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
