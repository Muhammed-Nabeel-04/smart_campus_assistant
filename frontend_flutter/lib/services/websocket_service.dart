import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../core/app_config.dart';
import '../core/session.dart';
import '../core/notification_service.dart';

class WebSocketService {
  static WebSocketChannel? _channel;
  static bool _isConnected = false;
  static final _eventController = StreamController<Map<String, dynamic>>.broadcast();

  static Stream<Map<String, dynamic>> get events => _eventController.stream;

  static String get _wsUrl {
    final base = AppConfig.backendUrl;
    if (base.startsWith('https://')) {
      return base.replaceFirst('https://', 'wss://') + '/ws/notifications';
    } else {
      return base.replaceFirst('http://', 'ws://') + '/ws/notifications';
    }
  }

  static Future<void> connect() async {
    if (_isConnected) return;

    final token = SessionManager.token;
    if (token == null) return;

    try {
      final uri = Uri.parse('$_wsUrl?token=$token');
      _channel = WebSocketChannel.connect(uri);
      _isConnected = true;
      debugPrint('🔌 WebSocket Connecting to $uri');

      _channel!.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message);
            _handleMessage(data);
          } catch (e) {
            debugPrint('❌ WS Message Error: $e');
          }
        },
        onDone: () {
          debugPrint('🔌 WebSocket Disconnected');
          _isConnected = false;
          _reconnect();
        },
        onError: (error) {
          debugPrint('❌ WebSocket Error: $error');
          _isConnected = false;
          _reconnect();
        },
      );
    } catch (e) {
      debugPrint('❌ WebSocket Connection Failed: $e');
      _isConnected = false;
      _reconnect();
    }
  }

  static void _handleMessage(Map<String, dynamic> data) {
    debugPrint('📩 WS Received: $data');
    _eventController.add(data);

    final type = data['type'];
    final message = data['message'] ?? 'New notification';

    if (type == 'attendance_started') {
      NotificationService.showNotification(
        id: DateTime.now().millisecond,
        title: 'Attendance Started',
        body: message,
      );
    }
    // Add more types here (e.g., new notice, complaint response)
  }

  static void _reconnect() {
    Future.delayed(const Duration(seconds: 5), () {
      if (!_isConnected && SessionManager.token != null) {
        connect();
      }
    });
  }

  static void disconnect() {
    _channel?.sink.close();
    _isConnected = false;
  }
}
