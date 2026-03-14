import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/app_config.dart';

class BackendSettingsScreen extends StatefulWidget {
  const BackendSettingsScreen({super.key});

  @override
  State<BackendSettingsScreen> createState() => _BackendSettingsScreenState();
}

class _BackendSettingsScreenState extends State<BackendSettingsScreen> {
  final _customUrlController = TextEditingController();
  String _currentUrl = '';
  bool _isTestingConnection = false;
  String? _connectionStatus;

  @override
  void initState() {
    super.initState();
    _currentUrl = AppConfig.backendUrl;
    _customUrlController.text = _currentUrl; // Show full URL in custom field
  }

  @override
  void dispose() {
    _customUrlController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTestingConnection = true;
      _connectionStatus = null;
    });

    try {
      final response = await http
          .get(Uri.parse('$_currentUrl/'))
          .timeout(const Duration(seconds: 5));

      setState(() {
        _isTestingConnection = false;
        _connectionStatus = response.statusCode == 200
            ? 'Connected successfully! ✅'
            : 'Server responded with error';
      });
    } catch (e) {
      setState(() {
        _isTestingConnection = false;
        _connectionStatus = 'Cannot connect to server ❌';
      });
    }
  }

  Future<void> _saveAndApply() async {
    // Save current URL
    await AppConfig.setBackendUrl(_currentUrl);

    // Test connection
    await _testConnection();

    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Backend URL updated successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _resetToDefault() async {
    await AppConfig.reset();
    setState(() {
      _currentUrl = AppConfig.backendUrl;
      _customUrlController.text = _currentUrl;
      _connectionStatus = null;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reset to default (Emulator)'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _setPreset(String preset) {
    setState(() {
      if (preset == 'emulator') {
        _currentUrl = AppConfig.urlEmulator;
      } else if (preset == 'localhost') {
        _currentUrl = AppConfig.urlLocalhost;
      }
      _customUrlController.text = _currentUrl; // Update custom field too
      _connectionStatus = null;
    });
  }

  void _updateCustomUrl() {
    final url = _customUrlController.text.trim();
    setState(() {
      _currentUrl = url;
      _connectionStatus = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1628),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'BACKEND SETTINGS',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: false,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Backend Display
            _buildSectionTitle('CURRENT BACKEND'),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2942),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2DD4BF), width: 1.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.wifi, color: Color(0xFF2DD4BF), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _currentUrl,
                      style: const TextStyle(
                        color: Color(0xFF2DD4BF),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Quick Presets
            _buildSectionTitle('QUICK PRESETS'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildPresetButton(
                    'Emulator',
                    _currentUrl == AppConfig.urlEmulator,
                    () => _setPreset('emulator'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPresetButton(
                    'Localhost',
                    _currentUrl == AppConfig.urlLocalhost,
                    () => _setPreset('localhost'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Custom URL - FULL URL INPUT LIKE YOUR IMAGE
            _buildSectionTitle('CUSTOM URL'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2942),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.link, color: Colors.white54, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _customUrlController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'http://192.168.1.100:8000',
                        hintStyle: TextStyle(color: Colors.white38),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      onChanged: (_) => _updateCustomUrl(),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Warning Message
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF854D0E).withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFCD34D), width: 1),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_amber,
                    color: Color(0xFFFCD34D),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'On real device: Use operating OS = use IPv4 WiFi address.',
                          style: TextStyle(
                            color: Color(0xFFFCD34D),
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'PC and phone must be on same WiFi.',
                          style: TextStyle(
                            color: Color(0xFFFCD34D),
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Connection Status
            if (_connectionStatus != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: _connectionStatus!.contains('✅')
                      ? Colors.green.withOpacity(0.2)
                      : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _connectionStatus!.contains('✅')
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
                child: Text(
                  _connectionStatus!,
                  style: TextStyle(
                    color: _connectionStatus!.contains('✅')
                        ? Colors.green
                        : Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            // Save & Apply Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isTestingConnection ? null : _saveAndApply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2DD4BF),
                  foregroundColor: const Color(0xFF0A1628),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isTestingConnection
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF0A1628),
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.save, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'SAVE & APPLY',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Reset Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: TextButton(
                onPressed: _resetToDefault,
                style: TextButton.styleFrom(foregroundColor: Colors.white54),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.refresh, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'RESET TO DEFAULT',
                      style: TextStyle(fontSize: 14, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildPresetButton(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2DD4BF).withOpacity(0.2)
              : const Color(0xFF1A2942),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF2DD4BF) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF2DD4BF) : Colors.white70,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
