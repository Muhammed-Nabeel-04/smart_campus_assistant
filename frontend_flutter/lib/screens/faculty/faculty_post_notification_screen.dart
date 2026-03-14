// File: lib/screens/faculty/faculty_post_notification_screen.dart
// Post targeted notifications to students

import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../core/app_colors.dart';

class FacultyPostNotificationScreen extends StatefulWidget {
  const FacultyPostNotificationScreen({super.key});

  @override
  State<FacultyPostNotificationScreen> createState() =>
      _FacultyPostNotificationScreenState();
}

class _FacultyPostNotificationScreenState
    extends State<FacultyPostNotificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();

  String _target = 'all'; // 'all', 'department', 'class'
  String _type = 'info'; // 'info', 'warning', 'urgent', 'announcement'
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await ApiService.postNotification(
        target: _target,
        type: _type,
        title: _titleController.text.trim(),
        message: _messageController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification sent successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Color get _typeColor {
    switch (_type) {
      case 'info':
        return AppColors.info;
      case 'warning':
        return AppColors.warning;
      case 'urgent':
        return AppColors.urgent;
      case 'announcement':
        return const Color(0xFF1565C0);
      default:
        return AppColors.info;
    }
  }

  IconData get _typeIcon {
    switch (_type) {
      case 'info':
        return Icons.info;
      case 'warning':
        return Icons.warning;
      case 'urgent':
        return Icons.priority_high;
      case 'announcement':
        return Icons.campaign;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgCard,
        elevation: 0,
        title: const Text('Post Notification'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Target Selection
            const Text(
              'Send To',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTargetChip('All Students', 'all', Icons.people),
                _buildTargetChip('My Department', 'department', Icons.business),
                _buildTargetChip('Specific Class', 'class', Icons.class_),
              ],
            ),

            const SizedBox(height: 24),

            // Type Selection
            const Text(
              'Notification Type',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTypeChip('Info', 'info', Icons.info, AppColors.info),
                _buildTypeChip(
                  'Warning',
                  'warning',
                  Icons.warning,
                  AppColors.warning,
                ),
                _buildTypeChip(
                  'Urgent',
                  'urgent',
                  Icons.priority_high,
                  AppColors.urgent,
                ),
                _buildTypeChip(
                  'Announcement',
                  'announcement',
                  Icons.campaign,
                  const Color(0xFF1565C0),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Title Field
            TextFormField(
              controller: _titleController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Title',
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                helperText: '${_titleController.text.length}/100 characters',
                helperStyle: const TextStyle(
                  color: AppColors.textHint,
                  fontSize: 12,
                ),
                prefixIcon: Icon(_typeIcon, color: _typeColor),
                filled: true,
                fillColor: AppColors.bgCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.bgSeparator),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _typeColor, width: 2),
                ),
              ),
              maxLength: 100,
              validator: (v) =>
                  v?.trim().isEmpty == true ? 'Title required' : null,
              onChanged: (v) => setState(() {}),
            ),

            const SizedBox(height: 16),

            // Message Field
            TextFormField(
              controller: _messageController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Message',
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                helperText: '${_messageController.text.length}/500 characters',
                helperStyle: const TextStyle(
                  color: AppColors.textHint,
                  fontSize: 12,
                ),
                alignLabelWithHint: true,
                filled: true,
                fillColor: AppColors.bgCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.bgSeparator),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _typeColor, width: 2),
                ),
              ),
              maxLines: 5,
              maxLength: 500,
              validator: (v) =>
                  v?.trim().isEmpty == true ? 'Message required' : null,
              onChanged: (v) => setState(() {}),
            ),

            const SizedBox(height: 24),

            // Preview
            const Text(
              'Preview',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _typeColor.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _typeColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(_typeIcon, color: _typeColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _titleController.text.isEmpty
                              ? 'Notification Title'
                              : _titleController.text,
                          style: TextStyle(
                            color: _titleController.text.isEmpty
                                ? AppColors.textHint
                                : AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _typeColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _type.toUpperCase(),
                          style: TextStyle(
                            color: _typeColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _messageController.text.isEmpty
                        ? 'Your message will appear here...'
                        : _messageController.text,
                    style: TextStyle(
                      color: _messageController.text.isEmpty
                          ? AppColors.textHint
                          : AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Send Button
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _sendNotification,
                icon: const Icon(Icons.send),
                label: Text(
                  _isSubmitting ? 'Sending...' : 'Send Notification',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _typeColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetChip(String label, String value, IconData icon) {
    final isSelected = _target == value;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _target = value);
      },
      backgroundColor: AppColors.bgCard,
      selectedColor: const Color(0xFF1565C0),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildTypeChip(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final isSelected = _type == value;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: isSelected ? Colors.white : color),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _type = value);
      },
      backgroundColor: AppColors.bgCard,
      selectedColor: color,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
