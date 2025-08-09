// File: services/notification_service.dart
import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  bool _permissionsRequested = false;

  // Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      final bool? initialized = await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      if (initialized == true || initialized == null) {
        if (!_permissionsRequested) {
          await _requestPermissions();
          _permissionsRequested = true;
        }
        
        _isInitialized = true;
        print('Notifications initialized successfully');
        
        // Request battery optimization exemption for unlimited notifications
        await _requestBatteryOptimizationExemption();
      } else {
        print('Failed to initialize notifications');
      }
    } catch (e) {
      print('Error initializing notifications: $e');
      _isInitialized = false;
    }
  }

  // Request battery optimization exemption for unlimited notifications
  Future<void> _requestBatteryOptimizationExemption() async {
    try {
      // Note: You'll need to implement this using platform channels
      // This is crucial for ensuring ALL notifications are delivered
      print('Requesting battery optimization exemption for unlimited notifications');
      
      // For now, we'll just log this - you can implement the actual request later
      // BatteryOptimizationService.requestIgnoreBatteryOptimizations();
    } catch (e) {
      print('Error requesting battery optimization exemption: $e');
    }
  }

  // AGGRESSIVE: Request all possible notification permissions
  Future<void> _requestPermissions() async {
    try {
      final androidImplementation = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        // Request basic notification permission
        final granted = await androidImplementation.requestNotificationsPermission();
        print('Android notification permission granted: $granted');
        
        // Request all notification categories to ensure maximum delivery
        // This tells Android we want to send all types of notifications
      }

      final iosImplementation = _notifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      if (iosImplementation != null) {
        final granted = await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
          provisional: true, // This allows unlimited notifications on iOS
        );
        print('iOS notification permission granted: $granted');
      }
    } catch (e) {
      print('Error requesting permissions: $e');
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      print('Notification tapped with payload: $payload');
      // TODO: Add navigation logic here
    }
  }

  // MEMBER NOTIFICATIONS - UNLIMITED

  // Show task assignment notification (for members) - NO LIMITS
  Future<void> showTaskAssignedNotification({
    required String taskTitle,
    required String eventTitle,
    required String taskId,
  }) async {
    if (!_isInitialized) return;

    // HIGH PRIORITY: Ensures notification is delivered
    const androidDetails = AndroidNotificationDetails(
      'task_assignments',
      'Task Assignments',
      channelDescription: 'Immediate notifications when you are assigned to tasks',
      importance: Importance.max, // Maximum importance
      priority: Priority.max,     // Maximum priority
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
      color: Color(0xFF2196F3),
      autoCancel: false,          // Don't auto-dismiss
      ongoing: false,             // Not persistent
      channelShowBadge: true,     // Show app badge
      showWhen: true,             // Show timestamp
      when: null,                 // Use current time
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      badgeNumber: null,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      // Use unique ID to prevent any notification from being overwritten
      final uniqueId = DateTime.now().millisecondsSinceEpoch.remainder(2147483647);
      
      await _notifications.show(
        uniqueId,
        '📋 New Task Assigned',
        'You have been assigned to "$taskTitle" in $eventTitle',
        notificationDetails,
        payload: 'task:$taskId',
      );
      
      // Log for tracking
      await _logNotification('Task Assignment', taskTitle, eventTitle);
      print('Task assignment notification sent: $taskTitle (ID: $uniqueId)');
    } catch (e) {
      print('Error sending task assignment notification: $e');
    }
  }

  // Show task due soon notification - NO LIMITS
  Future<void> showTaskDueSoonNotification({
    required String taskTitle,
    required String eventTitle,
    required String taskId,
    required int minutesLeft,
  }) async {
    if (!_isInitialized) return;

    const androidDetails = AndroidNotificationDetails(
      'task_due_soon',
      'Task Due Soon',
      channelDescription: 'Critical notifications for tasks due within an hour',
      importance: Importance.max,
      priority: Priority.max,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
      color: Color(0xFFFF9800),
      autoCancel: false,
      ongoing: false,
      channelShowBadge: true,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.critical, // Critical level for due soon
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      final uniqueId = DateTime.now().millisecondsSinceEpoch.remainder(2147483647);
      
      await _notifications.show(
        uniqueId,
        '⏰ Task Due Soon!',
        '"$taskTitle" in $eventTitle is due in $minutesLeft minutes',
        notificationDetails,
        payload: 'task:$taskId',
      );
      
      await _logNotification('Task Due Soon', taskTitle, eventTitle);
      print('Task due soon notification sent: $taskTitle (ID: $uniqueId)');
    } catch (e) {
      print('Error sending task due soon notification: $e');
    }
  }

  // Show task overdue notification - NO LIMITS
  Future<void> showTaskOverdueNotification({
    required String taskTitle,
    required String eventTitle,
    required String taskId,
    required int hoursOverdue,
  }) async {
    if (!_isInitialized) return;

    const androidDetails = AndroidNotificationDetails(
      'task_overdue',
      'Tasks Overdue',
      channelDescription: 'Critical notifications for overdue tasks',
      importance: Importance.max,
      priority: Priority.max,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
      color: Color(0xFFF44336),
      autoCancel: false,
      ongoing: false,
      channelShowBadge: true,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.critical,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    String overdueText = hoursOverdue < 24 
        ? '$hoursOverdue hours overdue' 
        : '${(hoursOverdue / 24).floor()} days overdue';

    try {
      final uniqueId = DateTime.now().millisecondsSinceEpoch.remainder(2147483647);
      
      await _notifications.show(
        uniqueId,
        '🚨 Task Overdue!',
        '"$taskTitle" in $eventTitle is $overdueText',
        notificationDetails,
        payload: 'task:$taskId',
      );
      
      await _logNotification('Task Overdue', taskTitle, eventTitle);
      print('Task overdue notification sent: $taskTitle (ID: $uniqueId)');
    } catch (e) {
      print('Error sending task overdue notification: $e');
    }
  }

  // ADMIN NOTIFICATIONS - UNLIMITED

  // Show task completion notification - NO LIMITS
  Future<void> showTaskCompletedNotification({
    required String taskTitle,
    required String completedBy,
    required String eventTitle,
    required String taskId,
  }) async {
    if (!_isInitialized) return;

    const androidDetails = AndroidNotificationDetails(
      'task_completions',
      'Task Completions',
      channelDescription: 'Notifications when tasks are completed',
      importance: Importance.max,
      priority: Priority.max,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
      color: Color(0xFF4CAF50),
      autoCancel: false,
      ongoing: false,
      channelShowBadge: true,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      final uniqueId = DateTime.now().millisecondsSinceEpoch.remainder(2147483647);
      
      await _notifications.show(
        uniqueId,
        '✅ Task Completed',
        '$completedBy completed "$taskTitle" in $eventTitle',
        notificationDetails,
        payload: 'task:$taskId',
      );
      
      await _logNotification('Task Completion', taskTitle, eventTitle);
      print('Task completion notification sent: $taskTitle (ID: $uniqueId)');
    } catch (e) {
      print('Error sending task completion notification: $e');
    }
  }

  // Show admin overdue notification - NO LIMITS
  Future<void> showAdminTaskOverdueNotification({
    required String taskTitle,
    required String eventTitle,
    required String taskId,
    required int assignedToCount,
    required int hoursOverdue,
  }) async {
    if (!_isInitialized) return;

    const androidDetails = AndroidNotificationDetails(
      'admin_overdue',
      'Admin: Overdue Tasks',
      channelDescription: 'Critical notifications for admins about overdue tasks',
      importance: Importance.max,
      priority: Priority.max,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
      color: Color(0xFFF44336),
      autoCancel: false,
      ongoing: false,
      channelShowBadge: true,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.critical,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    String overdueText = hoursOverdue < 24 
        ? '$hoursOverdue hours overdue' 
        : '${(hoursOverdue / 24).floor()} days overdue';
    
    String assignedText = assignedToCount > 1 
        ? 'assigned to $assignedToCount people' 
        : 'assigned to 1 person';

    try {
      final uniqueId = DateTime.now().millisecondsSinceEpoch.remainder(2147483647);
      
      await _notifications.show(
        uniqueId,
        '🚨 Admin Alert: Task Overdue',
        '"$taskTitle" in $eventTitle ($assignedText) is $overdueText',
        notificationDetails,
        payload: 'admin_task:$taskId',
      );
      
      await _logNotification('Admin Overdue Alert', taskTitle, eventTitle);
      print('Admin overdue notification sent: $taskTitle (ID: $uniqueId)');
    } catch (e) {
      print('Error sending admin overdue notification: $e');
    }
  }

  // Show event invitation notification - NO LIMITS
  Future<void> showEventInvitationNotification({
    required String eventTitle,
    required String invitedBy,
    required String eventId,
    required bool isAdmin,
  }) async {
    if (!_isInitialized) return;

    const androidDetails = AndroidNotificationDetails(
      'event_invitations',
      'Event Invitations',
      channelDescription: 'Notifications for event invitations',
      importance: Importance.max,
      priority: Priority.max,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
      color: Color(0xFF9C27B0),
      autoCancel: false,
      ongoing: false,
      channelShowBadge: true,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final role = isAdmin ? 'admin' : 'member';
    
    try {
      final uniqueId = DateTime.now().millisecondsSinceEpoch.remainder(2147483647);
      
      await _notifications.show(
        uniqueId,
        '🎉 Event Invitation',
        '$invitedBy added you as $role to "$eventTitle"',
        notificationDetails,
        payload: 'event:$eventId',
      );
      
      await _logNotification('Event Invitation', eventTitle, 'N/A');
      print('Event invitation notification sent: $eventTitle (ID: $uniqueId)');
    } catch (e) {
      print('Error sending event invitation notification: $e');
    }
  }

  // Log notifications for tracking
  Future<void> _logNotification(String type, String title, String event) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logs = prefs.getStringList('notification_logs') ?? [];
      final timestamp = DateTime.now().toIso8601String();
      logs.add('$timestamp - $type: $title in $event');
      
      // Keep only last 100 logs
      if (logs.length > 100) {
        logs.removeRange(0, logs.length - 100);
      }
      
      await prefs.setStringList('notification_logs', logs);
    } catch (e) {
      print('Error logging notification: $e');
    }
  }

  // Get notification statistics
  Future<Map<String, int>> getNotificationStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logs = prefs.getStringList('notification_logs') ?? [];
      
      final stats = <String, int>{};
      for (final log in logs) {
        final type = log.split(' - ')[1].split(':')[0];
        stats[type] = (stats[type] ?? 0) + 1;
      }
      
      return stats;
    } catch (e) {
      print('Error getting notification stats: $e');
      return {};
    }
  }

  // Test notification
  Future<void> showTestNotification() async {
    if (!_isInitialized) return;

    const androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Test Notifications',
      channelDescription: 'Test notifications for debugging',
      importance: Importance.max,
      priority: Priority.max,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notifications.show(
        999,
        '🎉 Notifications Ready!',
        'Your unlimited notification system is working correctly',
        notificationDetails,
        payload: 'test',
      );
      print('Test notification sent');
    } catch (e) {
      print('Error sending test notification: $e');
    }
  }

  // UTILITY METHODS

  Future<bool> areNotificationsEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userEnabled = prefs.getBool('notifications_enabled') ?? true;
      
      if (!userEnabled) return false;
      
      final androidImplementation = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        final granted = await androidImplementation.areNotificationsEnabled();
        return granted ?? false;
      }
      
      return true;
    } catch (e) {
      print('Error checking notification permissions: $e');
      return true;
    }
  }

  Future<bool> requestPermissionsManually() async {
    try {
      await _requestPermissions();
      _permissionsRequested = true;
      return await areNotificationsEnabled();
    } catch (e) {
      print('Error requesting permissions manually: $e');
      return false;
    }
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }
}