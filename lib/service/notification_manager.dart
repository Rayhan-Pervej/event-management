// File: services/notification_manager.dart
import 'dart:async';
import 'dart:isolate';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_management/models/task_model.dart';
import 'package:event_management/models/event_model.dart';
import 'package:event_management/service/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  final NotificationService _notificationService = NotificationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _currentUserId;
  List<StreamSubscription> _subscriptions = [];
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  Timer? _eventRefreshTimer; // NEW: Timer to refresh events periodically
  bool _isInBackground = false;
  bool _isInitialized = false;
  int _connectionAttempts = 0;
  List<String> _lastKnownEventIds = []; // NEW: Track known event IDs

  // Initialize notification manager with user ID
  Future<void> initialize(String userId) async {
    print('NotificationManager: Initializing for user $userId');

    _currentUserId = userId;
    await _notificationService.initialize();

    // Save user ID for background processing
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user_id', userId);

    await _startListening();
    _startHeartbeat();
    _startReconnectMonitoring();
    _startEventRefreshMonitoring(); // NEW: Start monitoring for new events

    _isInitialized = true;
    print('NotificationManager: Initialization complete with enhanced reliability');
  }

  // NEW: Monitor for new events every 30 seconds
  void _startEventRefreshMonitoring() {
    _eventRefreshTimer?.cancel();
    _eventRefreshTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      _checkForNewEvents();
    });
  }

  // NEW: Check if user has joined new events
  Future<void> _checkForNewEvents() async {
    if (_currentUserId == null) return;

    try {
      final currentEvents = await _getUserEvents();
      final currentEventIds = currentEvents.map((e) => e.id).toList();
      
      // Check if event list has changed
      if (!_listEquals(_lastKnownEventIds, currentEventIds)) {
        print('NotificationManager: New events detected, refreshing listeners...');
        print('Previous events: ${_lastKnownEventIds.length}');
        print('Current events: ${currentEventIds.length}');
        
        _lastKnownEventIds = currentEventIds;
        
        // Restart listeners with new events
        await _forceReconnect();
      }
    } catch (e) {
      print('Error checking for new events: $e');
    }
  }

  // NEW: Helper to compare lists
  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (!b.contains(a[i])) return false;
    }
    return true;
  }

  // Start heartbeat to detect connection issues
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      _checkConnectionHealth();
    });
  }

  // Monitor and auto-reconnect listeners
  void _startReconnectMonitoring() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer.periodic(Duration(minutes: 2), (timer) {
      if (_subscriptions.length < 3 && _currentUserId != null) {
        print('NotificationManager: Detected missing listeners, reconnecting...');
        _forceReconnect();
      }
    });
  }

  void _checkConnectionHealth() {
    if (_subscriptions.isEmpty && _currentUserId != null && _isInitialized) {
      print('NotificationManager: No active listeners detected, reconnecting...');
      _forceReconnect();
    }
  }

  Future<void> _forceReconnect() async {
    _connectionAttempts++;
    print('NotificationManager: Force reconnecting (attempt $_connectionAttempts)');
    
    try {
      await stopListening();
      await Future.delayed(Duration(seconds: 2)); // Brief pause
      await _startListening();
      _connectionAttempts = 0; // Reset on success
    } catch (e) {
      print('NotificationManager: Reconnection failed: $e');
      
      // Exponential backoff for failed attempts
      if (_connectionAttempts < 5) {
        int delay = _connectionAttempts * 5;
        print('NotificationManager: Retrying in $delay seconds...');
        Timer(Duration(seconds: delay), () => _forceReconnect());
      }
    }
  }

  // Enhanced listening with multiple fallback strategies
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
      
      // Update known event IDs
      _lastKnownEventIds = userEventIds;

      print('NotificationManager: User events: ${userEventIds.length}');

      if (userEventIds.isNotEmpty) {
        // Strategy 1: Listen to ALL tasks with enhanced error handling
        final allTasksSubscription = _firestore
            .collection('tasks')
            .where('eventId', whereIn: userEventIds)
            .snapshots(includeMetadataChanges: false) // Reduce noise
            .handleError((error) {
              print('All tasks stream error: $error');
              _scheduleReconnect();
            })
            .listen(
              _handleAllTaskChanges,
              onError: (error) {
                print('All tasks listener error: $error');
                _scheduleReconnect();
              },
              cancelOnError: false, // Keep trying
            );

        // Strategy 2: Listen to assigned tasks with enhanced error handling
        final assignedTasksSubscription = _firestore
            .collection('tasks')
            .where('assignedToUsers', arrayContains: _currentUserId)
            .snapshots(includeMetadataChanges: false)
            .handleError((error) {
              print('Assigned tasks stream error: $error');
              _scheduleReconnect();
            })
            .listen(
              _handleAssignedTaskChanges,
              onError: (error) {
                print('Assigned tasks listener error: $error');
                _scheduleReconnect();
              },
              cancelOnError: false,
            );

        // Strategy 3: Listen to events with enhanced error handling
        final eventSubscription = _firestore
            .collection('events')
            .snapshots(includeMetadataChanges: false)
            .handleError((error) {
              print('Events stream error: $error');
              _scheduleReconnect();
            })
            .listen(
              _handleEventChanges,
              onError: (error) {
                print('Events listener error: $error');
                _scheduleReconnect();
              },
              cancelOnError: false,
            );

        _subscriptions = [
          allTasksSubscription,
          assignedTasksSubscription,
          eventSubscription,
        ];

        print('NotificationManager: Started ${_subscriptions.length} enhanced listeners for ${userEventIds.length} events');
        
        // Strategy 4: Start local cache fallback
        _startLocalCacheFallback();
      }
    } catch (e) {
      print('Error starting enhanced listeners: $e');
      _scheduleReconnect();
    }
  }

  // NEW: Public method to refresh listeners when new events are created
  Future<void> refreshListeners() async {
    if (_currentUserId != null && _isInitialized) {
      print('NotificationManager: Manually refreshing listeners for new events');
      await _forceReconnect();
    }
  }

  void _scheduleReconnect() {
    Timer(Duration(seconds: 5), () {
      if (_currentUserId != null) {
        _forceReconnect();
      }
    });
  }

  // Local cache fallback for emulators
  void _startLocalCacheFallback() {
    Timer.periodic(Duration(minutes: 1), (timer) {
      if (_subscriptions.isEmpty) {
        print('NotificationManager: Using local cache fallback');
        _checkTasksDirectly();
      }
    });
  }

  // Direct Firebase queries as fallback
  Future<void> _checkTasksDirectly() async {
    if (_currentUserId == null) return;

    try {
      // Direct query for new tasks (fallback strategy)
      final recentTasks = await _firestore
          .collection('tasks')
          .where('assignedToUsers', arrayContains: _currentUserId)
          .where('createdAt', isGreaterThan: Timestamp.fromDate(
              DateTime.now().subtract(Duration(minutes: 2))))
          .get();

      for (var doc in recentTasks.docs) {
        final task = TaskModel.fromFirestore(doc);
        await _handleNewTaskAssignment(task);
      }
    } catch (e) {
      print('Direct task check failed: $e');
    }
  }

  // Mark app as background/foreground with enhanced handling
  void setBackgroundState(bool isBackground) {
    _isInBackground = isBackground;
    
    if (isBackground) {
      print('App went to background - enabling enhanced background mode');
      _enableBackgroundMode();
    } else {
      print('App returned to foreground - refreshing connections');
      _enableForegroundMode();
    }
  }

  void _enableBackgroundMode() {
    // Save current state
    _saveAppState();
    
    // Increase heartbeat frequency in background
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(Duration(seconds: 15), (timer) {
      _checkConnectionHealth();
    });
    
    // Increase event refresh frequency in background
    _eventRefreshTimer?.cancel();
    _eventRefreshTimer = Timer.periodic(Duration(seconds: 15), (timer) {
      _checkForNewEvents();
    });
  }

  void _enableForegroundMode() {
    // Restore normal heartbeat
    _startHeartbeat();
    
    // Restore normal event monitoring
    _startEventRefreshMonitoring();
    
    // Force refresh connections
    if (_subscriptions.isEmpty) {
      _forceReconnect();
    }
    
    // Restore app state
    _restoreAppState();
  }

  Future<void> _saveAppState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_background_time', DateTime.now().toIso8601String());
      await prefs.setBool('was_backgrounded', true);
    } catch (e) {
      print('Error saving app state: $e');
    }
  }

  Future<void> _restoreAppState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final wasBackgrounded = prefs.getBool('was_backgrounded') ?? false;
      
      if (wasBackgrounded) {
        final lastBackgroundTime = prefs.getString('last_background_time');
        if (lastBackgroundTime != null) {
          final backgroundTime = DateTime.parse(lastBackgroundTime);
          final timeDiff = DateTime.now().difference(backgroundTime);
          
          if (timeDiff.inMinutes > 5) {
            print('App was backgrounded for ${timeDiff.inMinutes} minutes, refreshing data');
            await _refreshAllData();
          }
        }
        
        await prefs.setBool('was_backgrounded', false);
      }
    } catch (e) {
      print('Error restoring app state: $e');
    }
  }

  Future<void> _refreshAllData() async {
    // Force refresh when returning from long background
    await _forceReconnect();
    await checkTaskReminders();
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

  // Handle ALL task changes in user's events (for completion detection)
  void _handleAllTaskChanges(QuerySnapshot snapshot) async {
    if (!await _notificationService.areNotificationsEnabled()) return;

    print('All tasks change detected: ${snapshot.docChanges.length} changes');

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

    print('Assigned tasks change detected: ${snapshot.docChanges.length} changes');

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

  // Handle new task assignment - ONCE ONLY
  Future<void> _handleNewTaskAssignment(TaskModel task) async {
    if (_currentUserId == null) return;

    print('Checking new task assignment: ${task.title}');

    // Send notification only once when assigned to a task
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

          await _notificationService.showTaskAssignedNotification(
            taskTitle: task.title,
            eventTitle: event.title,
            taskId: task.id,
          );
        }
      } catch (e) {
        print('Error sending task assignment notification: $e');
      }
    }
  }

  // Handle task completion - Show first name instead of user ID
  Future<void> _handleTaskCompletion(TaskModel task) async {
    if (_currentUserId == null) return;

    print('Checking task completion: ${task.title}');

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

          // Check if current user should be notified (admin only for task completion)
          final isAdmin = event.isUserAdmin(_currentUserId!);

          if (isAdmin) {
            print('Sending completion notification to admin');

            // Get the first name of the person who completed the task
            String completedByFirstName = await _getFirstName(lastCompletedBy.userId);

            await _notificationService.showTaskCompletedNotification(
              taskTitle: task.title,
              completedByFirstName: completedByFirstName,
              eventTitle: event.title,
              taskId: task.id,
            );
          }
        }
      } catch (e) {
        print('Error sending task completion notification: $e');
      }
    }
  }

  // Get first name from user ID
  Future<String> _getFirstName(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        return userData['firstName'] ?? userData['name'] ?? 'Someone';
      }
    } catch (e) {
      print('Error getting user first name: $e');
    }
    return 'Someone';
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

  // Handle event modifications (new members added) - ONCE ONLY
  Future<void> _handleEventModification(DocumentSnapshot doc) async {
    if (_currentUserId == null) return;

    try {
      final event = EventModel.fromFirestore(doc);

      // Check if current user is in this event
      final isUserInEvent = event.isUserParticipant(_currentUserId!);

      if (isUserInEvent) {
        final isAdmin = event.isUserAdmin(_currentUserId!);

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

  // Enhanced task reminders - Called every 1 minute from main.dart
  Future<void> checkTaskReminders() async {
    if (_currentUserId == null) return;

    try {
      // Get user's events
      final userEvents = await _getUserEvents();
      final userEventIds = userEvents.map((e) => e.id).toList();

      if (userEventIds.isEmpty) return;

      // Get all incomplete tasks in user's events
      final tasksSnapshot = await _firestore
          .collection('tasks')
          .where('eventId', whereIn: userEventIds)
          .where('status', whereIn: ['pending', 'in_progress'])
          .get();

      final now = DateTime.now();

      for (var doc in tasksSnapshot.docs) {
        final task = TaskModel.fromFirestore(doc);
        final timeToDue = task.deadline.difference(now);
        final event = userEvents.firstWhere((e) => e.id == task.eventId);

        // Check if user is assigned to this task
        final isAssigned = task.isAssignedToUser(_currentUserId!);
        final isAdmin = event.isUserAdmin(_currentUserId!);

        // MEMBER NOTIFICATIONS
        if (isAssigned) {
          // Due soon notification (within 1 hour) - EVERY 1 MINUTE
          if (timeToDue.inHours <= 1 && timeToDue.inMinutes > 0) {
            await _notificationService.showTaskDueSoonNotification(
              taskTitle: task.title,
              eventTitle: event.title,
              taskId: task.id,
              minutesLeft: timeToDue.inMinutes,
            );
          }

          // Overdue notification - EVERY 1 MINUTE
          if (timeToDue.isNegative) {
            await _notificationService.showTaskOverdueNotification(
              taskTitle: task.title,
              eventTitle: event.title,
              taskId: task.id,
              hoursOverdue: (-timeToDue.inHours),
            );
          }
        }

        // ADMIN NOTIFICATIONS
        if (isAdmin) {
          // Admin due soon notification (within 1 hour) - EVERY 1 MINUTE
          if (timeToDue.inHours <= 1 && timeToDue.inMinutes > 0) {
            await _notificationService.showAdminTaskDueSoonNotification(
              taskTitle: task.title,
              eventTitle: event.title,
              taskId: task.id,
              assignedToCount: task.assignedToUsers.length,
              minutesLeft: timeToDue.inMinutes,
            );
          }

          // Admin overdue notification - EVERY 1 MINUTE
          if (timeToDue.isNegative) {
            await _notificationService.showAdminTaskOverdueNotification(
              taskTitle: task.title,
              eventTitle: event.title,
              taskId: task.id,
              assignedToCount: task.assignedToUsers.length,
              hoursOverdue: (-timeToDue.inHours),
            );
          }
        }
      }
    } catch (e) {
      print('Error checking task reminders: $e');
    }
  }

  // Public method to manually check connection health
  Future<void> ensureConnectionHealth() async {
    if (_currentUserId != null) {
      if (_subscriptions.isEmpty) {
        print('NotificationManager: Manual connection check - restarting listeners');
        await _forceReconnect();
      } else {
        print('NotificationManager: Connection health good (${_subscriptions.length} listeners)');
      }
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

  // Enhanced dispose with cleanup
  Future<void> dispose() async {
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    _eventRefreshTimer?.cancel(); // NEW: Cancel event refresh timer
    await stopListening();
    _currentUserId = null;
    _isInitialized = false;
    _connectionAttempts = 0;
    _lastKnownEventIds.clear(); // NEW: Clear known events
    print('NotificationManager disposed with enhanced cleanup');
  }
}