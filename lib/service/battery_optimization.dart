// File: services/battery_optimization_service.dart
import 'package:flutter/services.dart';

class BatteryOptimizationService {
  static const MethodChannel _channel = MethodChannel('battery_optimization');

  // Request to disable battery optimization for your app
  static Future<bool> requestIgnoreBatteryOptimizations() async {
    try {
      // First check if already whitelisted
      final bool isIgnoring = await _channel.invokeMethod('isIgnoringBatteryOptimizations');
      
      if (isIgnoring) {
        print('App is already whitelisted from battery optimization');
        return true;
      }

      // Request to be whitelisted
      final bool granted = await _channel.invokeMethod('requestIgnoreBatteryOptimizations');
      print('Battery optimization whitelist result: $granted');
      
      return granted;
    } catch (e) {
      print('Error requesting battery optimization whitelist: $e');
      return false;
    }
  }

  // Check if app is whitelisted from battery optimization
  static Future<bool> isIgnoringBatteryOptimizations() async {
    try {
      return await _channel.invokeMethod('isIgnoringBatteryOptimizations');
    } catch (e) {
      print('Error checking battery optimization status: $e');
      return false;
    }
  }

  // Open battery optimization settings for manual configuration
  static Future<void> openBatteryOptimizationSettings() async {
    try {
      await _channel.invokeMethod('openBatteryOptimizationSettings');
    } catch (e) {
      print('Error opening battery optimization settings: $e');
    }
  }
}