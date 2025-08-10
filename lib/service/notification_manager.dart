// File: services/notification_manager.dart
import 'dart:async';
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
  bool _isInBackground = false;
  bool _isInitialized = false;

  // Initialize notification manager with user ID
  Future<void> initialize(String userId) async {
    print('NotificationManager: Initializing for user $userId');

    _currentUserId = userId;
    await _notificationService.initialize();

    // Save user ID for background processing
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user_id', userId);

    await _startListening();

    _isInitialized = true;
    print('NotificationManager: Initialization complete');
  }

  // Start listening to Firebase changes
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
        // Listen to ALL tasks in user's events for completion detection
        final allTasksSubscription = _firestore
            .collection('tasks')
            .where('eventId', whereIn: userEventIds)
            .snapshots()
            .listen(_handleAllTaskChanges);

        // Listen to new tasks assigned to user
        final assignedTasksSubscription = _firestore
            .collection('tasks')
            .where('assignedToUsers', arrayContains: _currentUserId)
            .snapshots()
            .listen(_handleAssignedTaskChanges);

        // Listen to events for member additions
        final eventSubscription = _firestore
            .collection('events')
            .snapshots()
            .listen(_handleEventChanges);

        _subscriptions = [
          allTasksSubscription,
          assignedTasksSubscription,
          eventSubscription,
        ];

        print('NotificationManager: Started listening to ${_subscriptions.length} streams');
      }
    } catch (e) {
      print('Error starting listeners: $e');
    }
  }

  // Mark app as background/foreground
  void setBackgroundState(bool isBackground) {
    _isInBackground = isBackground;
    if (isBackground) {
      print('App went to background - notifications will continue');
    } else {
      print('App returned to foreground');
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

  // Check task reminders - Called every 1 minute from main.dart
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
    await stopListening();
    _currentUserId = null;
    _isInitialized = false;
    print('NotificationManager disposed');
  }
}