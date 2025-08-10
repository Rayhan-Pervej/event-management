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
        
        // Create notification channels for better compatibility on ALL Android phones
        await _createNotificationChannels();
        
        _isInitialized = true;
        print('Notifications initialized successfully');
      } else {
        print('Failed to initialize notifications');
      }
    } catch (e) {
      print('Error initializing notifications: $e');
      _isInitialized = false;
    }
  }

  // Create notification channels with proper configuration for ALL Android devices
  Future<void> _createNotificationChannels() async {
    final androidImplementation = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      // High importance channels for critical notifications
      const highImportanceChannel = AndroidNotificationChannel(
        'high_importance_channel',
        'Critical Notifications',
        description: 'High importance notifications that must be shown',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        ledColor: Color(0xFF2196F3),
        showBadge: true,
      );

      const taskAssignmentChannel = AndroidNotificationChannel(
        'task_assignments',
        'Task Assignments',
        description: 'Immediate notifications when you are assigned to tasks',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        ledColor: Color(0xFF2196F3),
        showBadge: true,
      );

      const taskDueSoonChannel = AndroidNotificationChannel(
        'task_due_soon',
        'Task Due Soon',
        description: 'Critical notifications for tasks due within an hour',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        ledColor: Color(0xFFFF9800),
        showBadge: true,
      );

      const taskOverdueChannel = AndroidNotificationChannel(
        'task_overdue',
        'Tasks Overdue',
        description: 'Critical notifications for overdue tasks',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        ledColor: Color(0xFFF44336),
        showBadge: true,
      );

      const taskCompletionChannel = AndroidNotificationChannel(
        'task_completions',
        'Task Completions',
        description: 'Notifications when tasks are completed',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        ledColor: Color(0xFF4CAF50),
        showBadge: true,
      );

      const eventInvitationChannel = AndroidNotificationChannel(
        'event_invitations',
        'Event Invitations',
        description: 'Notifications for event invitations',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        ledColor: Color(0xFF9C27B0),
        showBadge: true,
      );

      const adminOverdueChannel = AndroidNotificationChannel(
        'admin_overdue',
        'Admin: Overdue Tasks',
        description: 'Critical notifications for admins about overdue tasks',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        ledColor: Color(0xFFF44336),
        showBadge: true,
      );

      const adminDueSoonChannel = AndroidNotificationChannel(
        'admin_due_soon',
        'Admin: Tasks Due Soon',
        description: 'Notifications for admins about tasks due soon',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        ledColor: Color(0xFFFF9800),
        showBadge: true,
      );

      // Create all channels
      await androidImplementation.createNotificationChannel(highImportanceChannel);
      await androidImplementation.createNotificationChannel(taskAssignmentChannel);
      await androidImplementation.createNotificationChannel(taskDueSoonChannel);
      await androidImplementation.createNotificationChannel(taskOverdueChannel);
      await androidImplementation.createNotificationChannel(taskCompletionChannel);
      await androidImplementation.createNotificationChannel(eventInvitationChannel);
      await androidImplementation.createNotificationChannel(adminOverdueChannel);
      await androidImplementation.createNotificationChannel(adminDueSoonChannel);

      print('All notification channels created successfully');
    }
  }

  // Request notification permissions
  Future<void> _requestPermissions() async {
    try {
      final androidImplementation = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        final granted = await androidImplementation.requestNotificationsPermission();
        print('Android notification permission granted: $granted');
      }

      final iosImplementation = _notifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      if (iosImplementation != null) {
        final granted = await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
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

  // MEMBER NOTIFICATIONS

  // Show event invitation notification - ONCE ONLY (UNIVERSAL FOR ALL ANDROID PHONES)
  Future<void> showEventInvitationNotification({
    required String eventTitle,
    required String invitedBy,
    required String eventId,
    required bool isAdmin,
  }) async {
    if (!_isInitialized) return;

    // Check if already notified for this event
    if (await _wasAlreadyNotified('event_invitation', eventId)) {
      print('Already notified for event invitation: $eventId');
      return;
    }

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
      when: null,
      usesChronometer: false,
      fullScreenIntent: false,
      // UNIVERSAL FIX: Force show custom content on ALL Android phones
      styleInformation: BigTextStyleInformation(
        '',
        contentTitle: '🎉 Event Invitation',
        summaryText: 'Event Management App',
        htmlFormatContent: false,
        htmlFormatContentTitle: false,
        htmlFormatSummaryText: false,
      ),
      enableLights: true,
      ledColor: Color(0xFF9C27B0),
      ledOnMs: 1000,
      ledOffMs: 500,
      ticker: 'New event invitation received',
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
    final body = '$invitedBy added you as $role to "$eventTitle"';
    
    try {
      final uniqueId = DateTime.now().millisecondsSinceEpoch.remainder(2147483647);
      
      await _notifications.show(
        uniqueId,
        '🎉 Event Invitation', // This will show on ALL Android phones
        body, // This will show on ALL Android phones
        notificationDetails,
        payload: 'event:$eventId',
      );
      
      // Mark as notified
      await _markAsNotified('event_invitation', eventId);
      await _logNotification('Event Invitation', eventTitle, 'N/A');
      print('Event invitation notification sent: $eventTitle (ID: $uniqueId)');
    } catch (e) {
      print('Error sending event invitation notification: $e');
    }
  }

  // Show task assignment notification - ONCE ONLY (UNIVERSAL FOR ALL ANDROID PHONES)
  Future<void> showTaskAssignedNotification({
    required String taskTitle,
    required String eventTitle,
    required String taskId,
  }) async {
    if (!_isInitialized) return;

    // Check if already notified for this task assignment
    if (await _wasAlreadyNotified('task_assignment', taskId)) {
      print('Already notified for task assignment: $taskId');
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'task_assignments',
      'Task Assignments',
      channelDescription: 'Immediate notifications when you are assigned to tasks',
      importance: Importance.max,
      priority: Priority.max,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
      color: Color(0xFF2196F3),
      autoCancel: false,
      ongoing: false,
      channelShowBadge: true,
      showWhen: true,
      when: null,
      usesChronometer: false,
      fullScreenIntent: false,
      // UNIVERSAL FIX: Force show custom content on ALL Android phones
      styleInformation: BigTextStyleInformation(
        '',
        contentTitle: '📋 New Task Assigned',
        summaryText: 'Event Management App',
        htmlFormatContent: false,
        htmlFormatContentTitle: false,
        htmlFormatSummaryText: false,
      ),
      enableLights: true,
      ledColor: Color(0xFF2196F3),
      ledOnMs: 1000,
      ledOffMs: 500,
      ticker: 'New task assignment received',
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

    final body = 'You have been assigned to "$taskTitle" in $eventTitle';

    try {
      final uniqueId = DateTime.now().millisecondsSinceEpoch.remainder(2147483647);
      
      await _notifications.show(
        uniqueId,
        '📋 New Task Assigned', // This will show on ALL Android phones
        body, // This will show on ALL Android phones
        notificationDetails,
        payload: 'task:$taskId',
      );
      
      // Mark as notified
      await _markAsNotified('task_assignment', taskId);
      await _logNotification('Task Assignment', taskTitle, eventTitle);
      print('Task assignment notification sent: $taskTitle (ID: $uniqueId)');
    } catch (e) {
      print('Error sending task assignment notification: $e');
    }
  }

  // Show task due soon notification - EVERY 1 MINUTE (UNIVERSAL FOR ALL ANDROID PHONES)
  Future<void> showTaskDueSoonNotification({
    required String taskTitle,
    required String eventTitle,
    required String taskId,
    required int minutesLeft,
  }) async {
    if (!_isInitialized) return;

    // TODO: Change time interval here - currently within 1 hour (60 minutes)
    if (minutesLeft > 60) return; // Only notify if within 1 hour

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
      when: null,
      usesChronometer: false,
      fullScreenIntent: false,
      // UNIVERSAL FIX: Force show custom content on ALL Android phones
      styleInformation: BigTextStyleInformation(
        '',
        contentTitle: '⏰ Task Due Soon!',
        summaryText: 'Event Management App',
        htmlFormatContent: false,
        htmlFormatContentTitle: false,
        htmlFormatSummaryText: false,
      ),
      enableLights: true,
      ledColor: Color(0xFFFF9800),
      ledOnMs: 1000,
      ledOffMs: 500,
      ticker: 'Task due soon notification',
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

    final body = '"$taskTitle" in $eventTitle is due in $minutesLeft minutes';

    try {
      final uniqueId = DateTime.now().millisecondsSinceEpoch.remainder(2147483647);
      
      await _notifications.show(
        uniqueId,
        '⏰ Task Due Soon!', // This will show on ALL Android phones
        body, // This will show on ALL Android phones
        notificationDetails,
        payload: 'task:$taskId',
      );
      
      await _logNotification('Task Due Soon', taskTitle, eventTitle);
      print('Task due soon notification sent: $taskTitle (ID: $uniqueId)');
    } catch (e) {
      print('Error sending task due soon notification: $e');
    }
  }

  // Show task overdue notification - EVERY 1 MINUTE (UNIVERSAL FOR ALL ANDROID PHONES)
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
      when: null,
      usesChronometer: false,
      fullScreenIntent: false,
      // UNIVERSAL FIX: Force show custom content on ALL Android phones
      styleInformation: BigTextStyleInformation(
        '',
        contentTitle: '🚨 Task Overdue!',
        summaryText: 'Event Management App',
        htmlFormatContent: false,
        htmlFormatContentTitle: false,
        htmlFormatSummaryText: false,
      ),
      enableLights: true,
      ledColor: Color(0xFFF44336),
      ledOnMs: 1000,
      ledOffMs: 500,
      ticker: 'Task overdue notification',
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

    final body = '"$taskTitle" in $eventTitle is $overdueText';

    try {
      final uniqueId = DateTime.now().millisecondsSinceEpoch.remainder(2147483647);
      
      await _notifications.show(
        uniqueId,
        '🚨 Task Overdue!', // This will show on ALL Android phones
        body, // This will show on ALL Android phones
        notificationDetails,
        payload: 'task:$taskId',
      );
      
      await _logNotification('Task Overdue', taskTitle, eventTitle);
      print('Task overdue notification sent: $taskTitle (ID: $uniqueId)');
    } catch (e) {
      print('Error sending task overdue notification: $e');
    }
  }

  // ADMIN NOTIFICATIONS

  // Show task completion notification - SHOW FIRST NAME (UNIVERSAL FOR ALL ANDROID PHONES)
  Future<void> showTaskCompletedNotification({
    required String taskTitle,
    required String completedByFirstName, // Changed to first name
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
      when: null,
      usesChronometer: false,
      fullScreenIntent: false,
      // UNIVERSAL FIX: Force show custom content on ALL Android phones
      styleInformation: BigTextStyleInformation(
        '',
        contentTitle: '✅ Task Completed',
        summaryText: 'Event Management App',
        htmlFormatContent: false,
        htmlFormatContentTitle: false,
        htmlFormatSummaryText: false,
      ),
      enableLights: true,
      ledColor: Color(0xFF4CAF50),
      ledOnMs: 1000,
      ledOffMs: 500,
      ticker: 'Task completed notification',
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

    final body = '$completedByFirstName completed "$taskTitle" in $eventTitle';

    try {
      final uniqueId = DateTime.now().millisecondsSinceEpoch.remainder(2147483647);
      
      await _notifications.show(
        uniqueId,
        '✅ Task Completed', // This will show on ALL Android phones
        body, // This will show on ALL Android phones
        notificationDetails,
        payload: 'task:$taskId',
      );
      
      await _logNotification('Task Completion', taskTitle, eventTitle);
      print('Task completion notification sent: $taskTitle (ID: $uniqueId)');
    } catch (e) {
      print('Error sending task completion notification: $e');
    }
  }

  // Show admin overdue notification - EVERY 1 MINUTE (UNIVERSAL FOR ALL ANDROID PHONES)
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
      when: null,
      usesChronometer: false,
      fullScreenIntent: false,
      // UNIVERSAL FIX: Force show custom content on ALL Android phones
      styleInformation: BigTextStyleInformation(
        '',
        contentTitle: '🚨 Admin Alert: Task Overdue',
        summaryText: 'Event Management App',
        htmlFormatContent: false,
        htmlFormatContentTitle: false,
        htmlFormatSummaryText: false,
      ),
      enableLights: true,
      ledColor: Color(0xFFF44336),
      ledOnMs: 1000,
      ledOffMs: 500,
      ticker: 'Admin overdue task notification',
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

    final body = '"$taskTitle" in $eventTitle ($assignedText) is $overdueText';

    try {
      final uniqueId = DateTime.now().millisecondsSinceEpoch.remainder(2147483647);
      
      await _notifications.show(
        uniqueId,
        '🚨 Admin Alert: Task Overdue', // This will show on ALL Android phones
        body, // This will show on ALL Android phones
        notificationDetails,
        payload: 'admin_task:$taskId',
      );
      
      await _logNotification('Admin Overdue Alert', taskTitle, eventTitle);
      print('Admin overdue notification sent: $taskTitle (ID: $uniqueId)');
    } catch (e) {
      print('Error sending admin overdue notification: $e');
    }
  }

  // Show admin due soon notification - EVERY 1 MINUTE (UNIVERSAL FOR ALL ANDROID PHONES)
  Future<void> showAdminTaskDueSoonNotification({
    required String taskTitle,
    required String eventTitle,
    required String taskId,
    required int assignedToCount,
    required int minutesLeft,
  }) async {
    if (!_isInitialized) return;

    // TODO: Change time interval here - currently within 1 hour (60 minutes)
    if (minutesLeft > 60) return; // Only notify if within 1 hour

    const androidDetails = AndroidNotificationDetails(
      'admin_due_soon',
      'Admin: Tasks Due Soon',
      channelDescription: 'Notifications for admins about tasks due soon',
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
      when: null,
      usesChronometer: false,
      fullScreenIntent: false,
      // UNIVERSAL FIX: Force show custom content on ALL Android phones
      styleInformation: BigTextStyleInformation(
        '',
        contentTitle: '⏰ Admin Alert: Task Due Soon',
        summaryText: 'Event Management App',
        htmlFormatContent: false,
        htmlFormatContentTitle: false,
        htmlFormatSummaryText: false,
      ),
      enableLights: true,
      ledColor: Color(0xFFFF9800),
      ledOnMs: 1000,
      ledOffMs: 500,
      ticker: 'Admin due soon task notification',
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

    String assignedText = assignedToCount > 1 
        ? 'assigned to $assignedToCount people' 
        : 'assigned to 1 person';

    final body = '"$taskTitle" in $eventTitle ($assignedText) is due in $minutesLeft minutes';

    try {
      final uniqueId = DateTime.now().millisecondsSinceEpoch.remainder(2147483647);
      
      await _notifications.show(
        uniqueId,
        '⏰ Admin Alert: Task Due Soon', // This will show on ALL Android phones
        body, // This will show on ALL Android phones
        notificationDetails,
        payload: 'admin_task:$taskId',
      );
      
      await _logNotification('Admin Due Soon Alert', taskTitle, eventTitle);
      print('Admin due soon notification sent: $taskTitle (ID: $uniqueId)');
    } catch (e) {
      print('Error sending admin due soon notification: $e');
    }
  }

  // Helper methods for tracking "once only" notifications
  Future<bool> _wasAlreadyNotified(String type, String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'notified_${type}_$id';
      return prefs.getBool(key) ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<void> _markAsNotified(String type, String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'notified_${type}_$id';
      await prefs.setBool(key, true);
    } catch (e) {
      print('Error marking as notified: $e');
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
        'Your notification system is working correctly',
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