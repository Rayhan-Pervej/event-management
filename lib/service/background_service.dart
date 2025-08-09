// File: services/background_notification_service.dart
import 'package:workmanager/workmanager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:event_management/models/task_model.dart';
import 'package:event_management/models/event_model.dart';
import 'package:event_management/service/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:event_management/firebase_options.dart';

const String taskNotificationCheck = "taskNotificationCheck";
const String overdueCheck = "overdueCheck";
const String frequentCheck = "frequentCheck"; // NEW: More frequent checks

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print('Background task started: $task'); // Debug

    try {
      // Initialize Firebase
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      
      // Initialize notification service
      final notificationService = NotificationService();
      await notificationService.initialize();
      
      // Get user ID from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('current_user_id');
      
      if (userId != null) {
        print('Checking notifications for user: $userId'); // Debug
        
        if (task == taskNotificationCheck || task == frequentCheck) {
          await _checkForNewNotifications(userId, notificationService);
        } else if (task == overdueCheck) {
          await _checkOverdueTasks(userId, notificationService);
        }
      } else {
        print('No user ID found in SharedPreferences'); // Debug
      }
      
      return Future.value(true);
    } catch (e) {
      print('Background task error: $e');
      return Future.value(false);
    }
  });
}

Future<void> _checkForNewNotifications(String userId, NotificationService notificationService) async {
  final firestore = FirebaseFirestore.instance;
  final prefs = await SharedPreferences.getInstance();
  
  // REDUCED check interval - now checking from last 10 minutes instead of 1 hour
  final lastCheck = prefs.getInt('last_background_check') ?? DateTime.now().subtract(Duration(minutes: 10)).millisecondsSinceEpoch;
  final now = DateTime.now().millisecondsSinceEpoch;
  
  print('Last check: ${DateTime.fromMillisecondsSinceEpoch(lastCheck)}'); // Debug
  
  try {
    // Get user's events (both as admin and member)
    final userEvents = await _getUserEvents(userId, firestore);
    final userEventIds = userEvents.map((e) => e.id).toList();
    final adminEventIds = userEvents.where((e) => e.isUserAdmin(userId)).map((e) => e.id).toList();
    
    print('User has ${userEvents.length} events (${adminEventIds.length} as admin)'); // Debug
    
    if (userEventIds.isNotEmpty) {
      // Check for new task assignments (for members) - NO DEDUPLICATION
      await _checkNewTaskAssignments(userId, firestore, userEvents, lastCheck, notificationService);
      
      // Check for task completions (for admins and assigned members) - NO DEDUPLICATION
      await _checkTaskCompletions(userId, firestore, userEvents, lastCheck, notificationService);
      
      // Check for new event invitations - NO DEDUPLICATION
      await _checkEventInvitations(userId, firestore, lastCheck, notificationService);
    }

    // Update last check time
    await prefs.setInt('last_background_check', now);
    print('Background check completed'); // Debug
    
  } catch (e) {
    print('Error in background notification check: $e');
  }
}

Future<void> _checkNewTaskAssignments(String userId, FirebaseFirestore firestore, 
    List<EventModel> userEvents, int lastCheck, NotificationService notificationService) async {
  
  // SHORTENED time window - check last 10 minutes instead of longer periods
  final checkTime = DateTime.now().subtract(Duration(minutes: 10));
  
  final assignedTasksSnapshot = await firestore
      .collection('tasks')
      .where('assignedToUsers', arrayContains: userId)
      .where('createdAt', isGreaterThan: Timestamp.fromDate(checkTime))
      .get();

  print('Found ${assignedTasksSnapshot.docs.length} new assigned tasks'); // Debug

  for (var doc in assignedTasksSnapshot.docs) {
    final task = TaskModel.fromFirestore(doc);
    if (task.createdBy != userId) {
      final event = userEvents.firstWhere((e) => e.id == task.eventId);
      
      // SEND EVERY TIME - NO CHECKS FOR PREVIOUS NOTIFICATIONS
      await notificationService.showTaskAssignedNotification(
        taskTitle: task.title,
        eventTitle: event.title,
        taskId: task.id,
      );
      
      print('Sent assignment notification for: ${task.title}'); // Debug
    }
  }
}

Future<void> _checkTaskCompletions(String userId, FirebaseFirestore firestore, 
    List<EventModel> userEvents, int lastCheck, NotificationService notificationService) async {
  
  final userEventIds = userEvents.map((e) => e.id).toList();
  
  final allTasksSnapshot = await firestore
      .collection('tasks')
      .where('eventId', whereIn: userEventIds)
      .get();

  print('Checking ${allTasksSnapshot.docs.length} tasks for completions'); // Debug

  final checkTime = DateTime.now().subtract(Duration(minutes: 10));

  for (var doc in allTasksSnapshot.docs) {
    final task = TaskModel.fromFirestore(doc);
    
    if (task.completedBy.isNotEmpty) {
      final lastCompletion = task.completedBy.last;
      
      // Check if task was completed recently by someone else
      if (lastCompletion.userId != userId &&
          lastCompletion.completedAt.isAfter(checkTime)) {
        
        final event = userEvents.firstWhere((e) => e.id == task.eventId);
        final isAdmin = event.isUserAdmin(userId);
        final isAssigned = task.isAssignedToUser(userId);
        
        if (isAdmin || isAssigned) {
          // SEND EVERY TIME - NO CHECKS FOR PREVIOUS NOTIFICATIONS
          await notificationService.showTaskCompletedNotification(
            taskTitle: task.title,
            completedBy: lastCompletion.userId,
            eventTitle: event.title,
            taskId: task.id,
          );
          
          print('Sent completion notification for: ${task.title}'); // Debug
        }
      }
    }
  }
}

Future<void> _checkEventInvitations(String userId, FirebaseFirestore firestore, 
    int lastCheck, NotificationService notificationService) async {
  
  // For event invitations, we'll check all events the user is part of
  final userEvents = await _getUserEvents(userId, firestore);
  
  for (var event in userEvents) {
    final isAdmin = event.isUserAdmin(userId);
    
    // SEND EVERY TIME - NO DEDUPLICATION TRACKING
    // Note: You might want to add timestamp tracking to events to make this more precise
    await notificationService.showEventInvitationNotification(
      eventTitle: event.title,
      invitedBy: event.createdBy,
      eventId: event.id,
      isAdmin: isAdmin,
    );
  }
}

// ENHANCED: Check for overdue tasks and upcoming due dates - NO LIMITS
Future<void> _checkOverdueTasks(String userId, NotificationService notificationService) async {
  final firestore = FirebaseFirestore.instance;
  final now = DateTime.now();
  
  try {
    // Get user's events
    final userEvents = await _getUserEvents(userId, firestore);
    final userEventIds = userEvents.map((e) => e.id).toList();
    final adminEventIds = userEvents.where((e) => e.isUserAdmin(userId)).map((e) => e.id).toList();
    
    if (userEventIds.isNotEmpty) {
      // Check tasks assigned to user (for overdue/due soon notifications) - NO LIMITS
      await _checkUserAssignedTasks(userId, firestore, userEvents, notificationService, now);
      
      // Check tasks in admin events (for admin overdue notifications) - NO LIMITS
      if (adminEventIds.isNotEmpty) {
        await _checkAdminEventTasks(userId, firestore, userEvents, notificationService, now);
      }
    }
    
  } catch (e) {
    print('Error checking overdue tasks: $e');
  }
}

Future<void> _checkUserAssignedTasks(String userId, FirebaseFirestore firestore, 
    List<EventModel> userEvents, NotificationService notificationService, DateTime now) async {
  
  final tasksSnapshot = await firestore
      .collection('tasks')
      .where('assignedToUsers', arrayContains: userId)
      .where('status', whereIn: ['pending', 'in_progress'])
      .get();

  for (var doc in tasksSnapshot.docs) {
    final task = TaskModel.fromFirestore(doc);
    final event = userEvents.firstWhere((e) => e.id == task.eventId);
    final timeToDue = task.deadline.difference(now);
    
    // Check if task is due within 1 hour - SEND EVERY TIME
    if (timeToDue.inHours <= 1 && timeToDue.inMinutes > 0) {
      await notificationService.showTaskDueSoonNotification(
        taskTitle: task.title,
        eventTitle: event.title,
        taskId: task.id,
        minutesLeft: timeToDue.inMinutes,
      );
      print('Sent due soon notification for: ${task.title}');
    }
    
    // Check if task is overdue - SEND EVERY TIME
    if (timeToDue.isNegative) {
      await notificationService.showTaskOverdueNotification(
        taskTitle: task.title,
        eventTitle: event.title,
        taskId: task.id,
        hoursOverdue: (-timeToDue.inHours),
      );
      print('Sent overdue notification for: ${task.title}');
    }
  }
}

Future<void> _checkAdminEventTasks(String userId, FirebaseFirestore firestore, 
    List<EventModel> userEvents, NotificationService notificationService, DateTime now) async {
  
  final adminEventIds = userEvents.where((e) => e.isUserAdmin(userId)).map((e) => e.id).toList();
  
  final tasksSnapshot = await firestore
      .collection('tasks')
      .where('eventId', whereIn: adminEventIds)
      .where('status', whereIn: ['pending', 'in_progress'])
      .get();

  for (var doc in tasksSnapshot.docs) {
    final task = TaskModel.fromFirestore(doc);
    final event = userEvents.firstWhere((e) => e.id == task.eventId);
    final timeToDue = task.deadline.difference(now);
    
    // Only notify admin if task is overdue - SEND EVERY TIME
    if (timeToDue.isNegative) {
      await notificationService.showAdminTaskOverdueNotification(
        taskTitle: task.title,
        eventTitle: event.title,
        taskId: task.id,
        assignedToCount: task.assignedToUsers.length,
        hoursOverdue: (-timeToDue.inHours),
      );
      print('Sent admin overdue notification for: ${task.title}');
    }
  }
}

Future<List<EventModel>> _getUserEvents(String userId, FirebaseFirestore firestore) async {
  final allEventsSnapshot = await firestore.collection('events').get();
  final userEvents = <EventModel>[];

  for (var doc in allEventsSnapshot.docs) {
    try {
      final event = EventModel.fromFirestore(doc);
      if (event.isUserAdmin(userId) || event.isUserMember(userId)) {
        userEvents.add(event);
      }
    } catch (e) {
      print('Error parsing event ${doc.id}: $e');
    }
  }

  return userEvents;
}

class BackgroundNotificationService {
  static Future<void> initialize() async {
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
    print('WorkManager initialized for unlimited notifications'); // Debug
  }

  static Future<void> startBackgroundTask(String userId) async {
    try {
      // Cancel existing tasks first
      await Workmanager().cancelAll();
      
      // FREQUENT CHECKS: Register multiple background tasks for maximum coverage
      
      // 1. General notifications check every 10 minutes (more frequent)
      await Workmanager().registerPeriodicTask(
        taskNotificationCheck,
        taskNotificationCheck,
        frequency: Duration(minutes: 15), // Minimum allowed by Android
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
        backoffPolicy: BackoffPolicy.linear,
        backoffPolicyDelay: Duration(seconds: 30),
      );
      
      // 2. Overdue check every 20 minutes  
      await Workmanager().registerPeriodicTask(
        overdueCheck,
        overdueCheck,
        frequency: Duration(minutes: 20),
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
        backoffPolicy: BackoffPolicy.linear,
        backoffPolicyDelay: Duration(seconds: 30),
      );
      
      // 3. Frequent check every 15 minutes (for critical notifications)
      await Workmanager().registerPeriodicTask(
        frequentCheck,
        frequentCheck,
        frequency: Duration(minutes: 15),
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
        backoffPolicy: BackoffPolicy.linear,
        backoffPolicyDelay: Duration(seconds: 30),
      );
      
      print('Multiple background tasks registered for unlimited notifications: $userId'); // Debug
    } catch (e) {
      print('Error starting background tasks: $e');
    }
  }

  static Future<void> stopBackgroundTask() async {
    try {
      await Workmanager().cancelAll();
      print('All background tasks stopped'); // Debug
    } catch (e) {
      print('Error stopping background tasks: $e');
    }
  }
}