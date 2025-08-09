// File: services/notification_manager.dart
import 'dart:async';
import 'dart:isolate';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_management/models/task_model.dart';
import 'package:event_management/models/event_model.dart';
import 'package:event_management/service/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  final NotificationService _notificationService = NotificationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _currentUserId;
  List<StreamSubscription> _subscriptions = [];
  Timer? _heartbeatTimer;
  Timer? _restartTimer;
  bool _isInBackground = false;
  bool _isInitialized = false;

  // Initialize notification manager with user ID
  Future<void> initialize(String userId) async {
    print('NotificationManager: Initializing for user $userId');

    _currentUserId = userId;
    await _notificationService.initialize();

    // Save user ID for background service
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user_id', userId);

    // Request battery optimization exemption immediately
    await _requestBatteryOptimizationExemption();

    await _startListening();

    // Start heartbeat to keep connections alive
    _startHeartbeat();

    // Start restart timer to periodically check and restart listeners
    _startRestartTimer();

    _isInitialized = true;
    print('NotificationManager: Initialization complete');
  }

  // Request battery optimization exemption
  Future<void> _requestBatteryOptimizationExemption() async {
    try {
      const MethodChannel channel = MethodChannel('battery_optimization');

      // Check if already whitelisted
      final bool isIgnoring = await channel.invokeMethod(
        'isIgnoringBatteryOptimizations',
      );

      if (!isIgnoring) {
        print('Requesting battery optimization exemption...');
        await channel.invokeMethod('requestIgnoreBatteryOptimizations');
      } else {
        print('App already whitelisted from battery optimization');
      }
    } catch (e) {
      print('Error with battery optimization: $e');
    }
  }

  // Start heartbeat to keep connections alive
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      _checkConnectionHealth();
    });
  }

  // Start restart timer to force restart listeners every 5 minutes
  void _startRestartTimer() {
    _restartTimer?.cancel();
    _restartTimer = Timer.periodic(Duration(minutes: 5), (timer) {
      print('NotificationManager: Periodic restart check');
      if (_currentUserId != null) {
        _forceRestartListeners();
      }
    });
  }

  void _checkConnectionHealth() {
    // Only restart if listeners are actually dead AND we have a user ID
    if (_subscriptions.isEmpty && _currentUserId != null && _isInitialized) {
      print('Detected dead connections, restarting listeners...');
      _startListening();
    } else {
      // Listeners are healthy - no need to restart
      print(
        'Connection health check: ${_subscriptions.length} listeners active',
      );
    }
  }

  // Force restart all listeners (called periodically and on app resume)
  Future<void> _forceRestartListeners() async {
    print('NotificationManager: Force restarting all listeners');
    await stopListening();
    await _startListening();
  }

  // Enhanced listening with better error handling
  Future<void> _startListening() async {
    if (_currentUserId == null) {
      print('NotificationManager: Cannot start listening - no user ID');
      return;
    }

    await stopListening();

    try {
      // Get user's events first
      final userEvents = await _getUserEvents();
      final userEventIds = userEvents.map((e) => e.id).toList();

      print('NotificationManager: User events: ${userEventIds.length}');

      if (userEventIds.isNotEmpty) {
        // Listen to ALL tasks in user's events with enhanced error handling
        final allTasksSubscription = _firestore
            .collection('tasks')
            .where('eventId', whereIn: userEventIds)
            .snapshots()
            .handleError((error) {
              print('All tasks stream error: $error');
              // Aggressive restart after error
              Future.delayed(
                Duration(seconds: 3),
                () => _forceRestartListeners(),
              );
            })
            .listen(
              _handleAllTaskChanges,
              onError: (error) {
                print('All tasks listener error: $error');
                Future.delayed(
                  Duration(seconds: 3),
                  () => _forceRestartListeners(),
                );
              },
            );

        // Listen to new tasks assigned to user with enhanced error handling
        final assignedTasksSubscription = _firestore
            .collection('tasks')
            .where('assignedToUsers', arrayContains: _currentUserId)
            .snapshots()
            .handleError((error) {
              print('Assigned tasks stream error: $error');
              Future.delayed(
                Duration(seconds: 3),
                () => _forceRestartListeners(),
              );
            })
            .listen(
              _handleAssignedTaskChanges,
              onError: (error) {
                print('Assigned tasks listener error: $error');
                Future.delayed(
                  Duration(seconds: 3),
                  () => _forceRestartListeners(),
                );
              },
            );

        // Listen to events for member additions with enhanced error handling
        final eventSubscription = _firestore
            .collection('events')
            .snapshots()
            .handleError((error) {
              print('Events stream error: $error');
              Future.delayed(
                Duration(seconds: 3),
                () => _forceRestartListeners(),
              );
            })
            .listen(
              _handleEventChanges,
              onError: (error) {
                print('Events listener error: $error');
                Future.delayed(
                  Duration(seconds: 3),
                  () => _forceRestartListeners(),
                );
              },
            );

        _subscriptions = [
          allTasksSubscription,
          assignedTasksSubscription,
          eventSubscription,
        ];

        print(
          'NotificationManager: Started listening to ${_subscriptions.length} streams with enhanced error handling',
        );
      }
    } catch (e) {
      print('Error starting listeners: $e');
      // Aggressive retry after delay
      Future.delayed(Duration(seconds: 5), () => _forceRestartListeners());
    }
  }

  // Mark app as background/foreground
  void setBackgroundState(bool isBackground) {
    _isInBackground = isBackground;
    if (isBackground) {
      print('App went to background - maintaining listeners');
    } else {
      print('App returned to foreground - checking listener health');
      // Only check health, don't force restart
      _checkConnectionHealth();
      // Remove the aggressive restart that was causing issues
    }
  }

  // Get all events where user is admin or member
  Future<List<EventModel>> _getUserEvents() async {
    final allEventsSnapshot = await _firestore.collection('events').get();
    final userEvents = <EventModel>[];

    for (var doc in allEventsSnapshot.docs) {
      try {
        final event = EventModel.fromFirestore(doc);
        if (event.isUserAdmin(_currentUserId!) ||
            event.isUserMember(_currentUserId!)) {
          userEvents.add(event);
        }
      } catch (e) {
        print('Error parsing event ${doc.id}: $e');
      }
    }

    return userEvents;
  }

  // Handle ALL task changes in user's events
  void _handleAllTaskChanges(QuerySnapshot snapshot) async {
    if (!await _notificationService.areNotificationsEnabled()) return;

    print(
      'All tasks change detected: ${snapshot.docChanges.length} changes (Background: $_isInBackground)',
    );

    for (var change in snapshot.docChanges) {
      final task = TaskModel.fromFirestore(change.doc);

      switch (change.type) {
        case DocumentChangeType.modified:
          await _handleTaskCompletion(task);
          break;
        default:
          break;
      }
    }
  }

  // Handle assigned task changes (for new assignments)
  void _handleAssignedTaskChanges(QuerySnapshot snapshot) async {
    if (!await _notificationService.areNotificationsEnabled()) return;

    print(
      'Assigned tasks change detected: ${snapshot.docChanges.length} changes (Background: $_isInBackground)',
    );

    for (var change in snapshot.docChanges) {
      final task = TaskModel.fromFirestore(change.doc);

      switch (change.type) {
        case DocumentChangeType.added:
          await _handleNewTaskAssignment(task);
          break;
        default:
          break;
      }
    }
  }

  // Handle new task assignment - AGGRESSIVE NOTIFICATION
  Future<void> _handleNewTaskAssignment(TaskModel task) async {
    if (_currentUserId == null) return;

    print(
      'Checking new task assignment: ${task.title} (Background: $_isInBackground)',
    );

    // SEND NOTIFICATION FOR ALL ASSIGNED TASKS - NO RESTRICTIONS
    if (task.isAssignedToUser(_currentUserId!) &&
        task.createdBy != _currentUserId) {
      print('Sending assignment notification for: ${task.title}');

      try {
        final eventDoc = await _firestore
            .collection('events')
            .doc(task.eventId)
            .get();
        if (eventDoc.exists) {
          final event = EventModel.fromFirestore(eventDoc);

          // AGGRESSIVE: Send notification regardless of background state
          await _notificationService.showTaskAssignedNotification(
            taskTitle: task.title,
            eventTitle: event.title,
            taskId: task.id,
          );

          // Also save to pending notifications for backup
          await _savePendingNotification('task_assignment', {
            'taskTitle': task.title,
            'eventTitle': event.title,
            'taskId': task.id,
            'timestamp': DateTime.now().toIso8601String(),
          });
        }
      } catch (e) {
        print('Error sending task assignment notification: $e');
      }
    }
  }

  // Handle task completion - AGGRESSIVE NOTIFICATION
  Future<void> _handleTaskCompletion(TaskModel task) async {
    if (_currentUserId == null) return;

    print(
      'Checking task completion: ${task.title} (Background: $_isInBackground)',
    );

    // Check if task was completed by someone else
    final lastCompletedBy = task.completedBy.isNotEmpty
        ? task.completedBy.last
        : null;

    if (lastCompletedBy != null && lastCompletedBy.userId != _currentUserId) {
      print('Task completed by: ${lastCompletedBy.userId}');

      try {
        final eventDoc = await _firestore
            .collection('events')
            .doc(task.eventId)
            .get();
        if (eventDoc.exists) {
          final event = EventModel.fromFirestore(eventDoc);

          // Check if current user should be notified
          final isAssigned = task.isAssignedToUser(_currentUserId!);
          final isAdmin = event.isUserAdmin(_currentUserId!);

          print('User is assigned: $isAssigned, User is admin: $isAdmin');

          if (isAssigned || isAdmin) {
            print('Sending completion notification');

            // AGGRESSIVE: Send notification regardless of background state
            await _notificationService.showTaskCompletedNotification(
              taskTitle: task.title,
              completedBy: lastCompletedBy.userId,
              eventTitle: event.title,
              taskId: task.id,
            );

            // Also save to pending notifications for backup
            await _savePendingNotification('task_completion', {
              'taskTitle': task.title,
              'completedBy': lastCompletedBy.userId,
              'eventTitle': event.title,
              'taskId': task.id,
              'timestamp': DateTime.now().toIso8601String(),
            });
          }
        }
      } catch (e) {
        print('Error sending task completion notification: $e');
      }
    }
  }

  // Handle event changes (member additions)
  void _handleEventChanges(QuerySnapshot snapshot) async {
    if (!await _notificationService.areNotificationsEnabled()) return;

    for (var change in snapshot.docChanges) {
      if (change.type == DocumentChangeType.modified) {
        await _handleEventModification(change.doc);
      }
    }
  }

  // Handle event modifications (new members added)
  Future<void> _handleEventModification(DocumentSnapshot doc) async {
    if (_currentUserId == null) return;

    try {
      final event = EventModel.fromFirestore(doc);

      // Check if current user is in this event
      final isUserInEvent = event.isUserParticipant(_currentUserId!);

      if (isUserInEvent) {
        final isAdmin = event.isUserAdmin(_currentUserId!);

        // AGGRESSIVE: Send notification regardless of background state
        await _notificationService.showEventInvitationNotification(
          eventTitle: event.title,
          invitedBy: event.createdBy,
          eventId: event.id,
          isAdmin: isAdmin,
        );
      }
    } catch (e) {
      print('Error handling event modification: $e');
    }
  }

  // Save pending notifications for backup delivery
  Future<void> _savePendingNotification(
    String type,
    Map<String, dynamic> data,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingKey = 'pending_notifications_${_currentUserId}';
      final pending = prefs.getStringList(pendingKey) ?? [];

      final notification = {
        'type': type,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      };

      pending.add(notification.toString());

      // Keep only last 50 pending notifications
      if (pending.length > 50) {
        pending.removeRange(0, pending.length - 50);
      }

      await prefs.setStringList(pendingKey, pending);
    } catch (e) {
      print('Error saving pending notification: $e');
    }
  }

  // Schedule task due date reminders - UNLIMITED
  Future<void> scheduleTaskReminders() async {
    if (_currentUserId == null) return;

    try {
      final tasksSnapshot = await _firestore
          .collection('tasks')
          .where('assignedToUsers', arrayContains: _currentUserId)
          .where('status', whereIn: ['pending', 'in_progress'])
          .get();

      final now = DateTime.now();

      for (var doc in tasksSnapshot.docs) {
        final task = TaskModel.fromFirestore(doc);
        final timeToDue = task.deadline.difference(now);

        // Get event details
        final eventDoc = await _firestore
            .collection('events')
            .doc(task.eventId)
            .get();
        if (!eventDoc.exists) continue;

        final event = EventModel.fromFirestore(eventDoc);

        // Send due soon notifications (within 1 hour) - ALWAYS SEND
        if (timeToDue.inHours <= 1 && timeToDue.inMinutes > 0) {
          print('Sending due soon notification for: ${task.title}');

          await _notificationService.showTaskDueSoonNotification(
            taskTitle: task.title,
            eventTitle: event.title,
            taskId: task.id,
            minutesLeft: timeToDue.inMinutes,
          );
        }

        // Send overdue notifications - ALWAYS SEND
        if (timeToDue.isNegative) {
          print('Sending overdue notification for: ${task.title}');

          await _notificationService.showTaskOverdueNotification(
            taskTitle: task.title,
            eventTitle: event.title,
            taskId: task.id,
            hoursOverdue: (-timeToDue.inHours),
          );
        }
      }

      // ALSO CHECK ADMIN TASKS FOR OVERDUE NOTIFICATIONS
      await _checkAdminOverdueTasks();
    } catch (e) {
      print('Error scheduling task reminders: $e');
    }
  }

  // Check overdue tasks in admin events - UNLIMITED
  Future<void> _checkAdminOverdueTasks() async {
    if (_currentUserId == null) return;

    try {
      // Get user's admin events
      final userEvents = await _getUserEvents();
      final adminEventIds = userEvents
          .where((e) => e.isUserAdmin(_currentUserId!))
          .map((e) => e.id)
          .toList();

      if (adminEventIds.isEmpty) return;

      final tasksSnapshot = await _firestore
          .collection('tasks')
          .where('eventId', whereIn: adminEventIds)
          .where('status', whereIn: ['pending', 'in_progress'])
          .get();

      final now = DateTime.now();

      for (var doc in tasksSnapshot.docs) {
        final task = TaskModel.fromFirestore(doc);
        final timeToDue = task.deadline.difference(now);

        // Only notify admin if task is overdue (not for "due soon")
        if (timeToDue.isNegative) {
          final event = userEvents.firstWhere((e) => e.id == task.eventId);

          print('Sending admin overdue notification for: ${task.title}');

          // ALWAYS SEND - NO RESTRICTIONS
          await _notificationService.showAdminTaskOverdueNotification(
            taskTitle: task.title,
            eventTitle: event.title,
            taskId: task.id,
            assignedToCount: task.assignedToUsers.length,
            hoursOverdue: (-timeToDue.inHours),
          );
        }
      }
    } catch (e) {
      print('Error checking admin overdue tasks: $e');
    }
  }

  // Public method to manually restart listeners (call this when app resumes)
  Future<void> restartListeners() async {
    if (_currentUserId != null && _subscriptions.isEmpty) {
      print('NotificationManager: Restarting dead listeners');
      await _forceRestartListeners();
    } else {
      print(
        'NotificationManager: Listeners already active (${_subscriptions.length}), skipping restart',
      );
    }
  }

  // Stop listening to changes
  Future<void> stopListening() async {
    for (var subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    print('Stopped all notification listeners');
  }

  // Dispose resources
  Future<void> dispose() async {
    _heartbeatTimer?.cancel();
    _restartTimer?.cancel();
    await stopListening();
    _currentUserId = null;
    _isInitialized = false;
  }
}

extension NotificationManagerKeepAlive on NotificationManager {
  // Method to ensure listeners are always active
  Future<void> ensureListenersActive() async {
    if (_currentUserId != null && _subscriptions.isEmpty) {
      print('Keep-alive: Restarting dead listeners');
      await _forceRestartListeners();
    }
  }
}
