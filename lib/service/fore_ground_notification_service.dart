// File: services/foreground_notification_service.dart
import 'dart:async';
import 'dart:isolate';
import 'package:flutter/services.dart';
import 'package:event_management/service/notification_manager.dart';

class ForegroundNotificationService {
  static const MethodChannel _channel = MethodChannel('foreground_service');
  static bool _isRunning = false;
  static Timer? _keepAliveTimer;

  // Start foreground service to keep app alive
  static Future<bool> startForegroundService() async {
    if (_isRunning) return true;

    try {
      // Start Android foreground service
      final bool started = await _channel.invokeMethod('startForegroundService', {
        'title': 'Event Management',
        'content': 'Monitoring for task notifications',
        'importance': 'high',
      });

      if (started) {
        _isRunning = true;
        _startKeepAliveMonitoring();
        print('Foreground service started successfully');
        return true;
      }
    } catch (e) {
      print('Error starting foreground service: $e');
    }
    return false;
  }

  // Stop foreground service
  static Future<void> stopForegroundService() async {
    try {
      await _channel.invokeMethod('stopForegroundService');
      _isRunning = false;
      _keepAliveTimer?.cancel();
      print('Foreground service stopped');
    } catch (e) {
      print('Error stopping foreground service: $e');
    }
  }

  // Keep monitoring and restart listeners if needed
  static void _startKeepAliveMonitoring() {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = Timer.periodic(Duration(minutes: 2), (timer) {
      if (_isRunning) {
        // Ensure notification manager is always active
        NotificationManager().ensureListenersActive();
        print('Keep-alive check: Ensuring listeners are active');
      }
    });
  }

  // Check if service is running
  static bool get isRunning => _isRunning;
}

