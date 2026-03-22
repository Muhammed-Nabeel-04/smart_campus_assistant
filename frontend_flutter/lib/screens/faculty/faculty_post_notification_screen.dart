// File: lib/screens/faculty/faculty_post_notification_screen.dart
// Post targeted notifications to students

import 'package:flutter/material.dart';
import '../../services/api_service.dart';

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

  // Fixed Status Colors
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color infoBlue = Color(0xFF2196F3);
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color urgentRed = Color(0xFFFF5722);
  static const Color announcementBlue = Color(0xFF1565C0);

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendNotification() async {
    final cs = Theme.of(context).colorScheme;
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
            backgroundColor: successGreen,
          ),
        );
        Navigator.pop(context);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: cs.error),
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
        return infoBlue;
      case 'warning':
        return warningOrange;
      case 'urgent':
        return urgentRed;
      case 'announcement':
        return announcementBlue;
      default:
        return infoBlue;
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
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Post Notification')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Target Selection
            Text(
              'Send To',
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTargetChip('All Students', 'all', Icons.people, cs),
                _buildTargetChip(
                  'My Department',
                  'department',
                  Icons.business,
                  cs,
                ),
                _buildTargetChip('Specific Class', 'class', Icons.class_, cs),
              ],
            ),

            const SizedBox(height: 24),

            // Type Selection
            Text(
              'Notification Type',
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTypeChip('Info', 'info', Icons.info, infoBlue, cs),
                _buildTypeChip(
                  'Warning',
                  'warning',
                  Icons.warning,
                  warningOrange,
                  cs,
                ),
                _buildTypeChip(
                  'Urgent',
                  'urgent',
                  Icons.priority_high,
                  urgentRed,
                  cs,
                ),
                _buildTypeChip(
                  'Announcement',
                  'announcement',
                  Icons.campaign,
                  announcementBlue,
                  cs,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Title Field
            TextFormField(
              controller: _titleController,
              style: TextStyle(color: cs.onSurface),
              decoration: InputDecoration(
                labelText: 'Title',
                prefixIcon: Icon(_typeIcon, color: _typeColor),
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
              style: TextStyle(color: cs.onSurface),
              decoration: InputDecoration(
                labelText: 'Message',
                alignLabelWithHint: true,
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
            Text(
              'Preview',
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surface,
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
                                ? cs.onSurface.withOpacity(0.4)
                                : cs.onSurface,
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
                          ? cs.onSurface.withOpacity(0.4)
                          : cs.onSurface.withOpacity(0.7),
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
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetChip(
    String label,
    String value,
    IconData icon,
    ColorScheme cs,
  ) {
    final isSelected = _target == value;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: isSelected ? cs.onPrimary : cs.onSurface),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) => setState(() => _target = value),
      selectedColor: cs.primary,
      labelStyle: TextStyle(
        color: isSelected ? cs.onPrimary : cs.onSurface,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildTypeChip(
    String label,
    String value,
    IconData icon,
    Color typeColor,
    ColorScheme cs,
  ) {
    final isSelected = _type == value;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: isSelected ? Colors.white : typeColor),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) => setState(() => _type = value),
      selectedColor: typeColor,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : cs.onSurface,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
