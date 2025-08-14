import 'package:event_management/models/activity_item.dart';
import 'package:event_management/models/member_performance.dart';
import 'package:event_management/models/user.dart';
import 'package:event_management/repository/event_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_management/models/task_model.dart';
import 'package:event_management/models/event_model.dart';
import 'package:event_management/repository/task_repository.dart';

class HomeProvider with ChangeNotifier {
  final TasksRepository _tasksRepository = TasksRepository();
  final EventsRepository _eventsRepository = EventsRepository();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Core data
  List<EventModel> _userEvents = [];
  List<TaskModel> _allTasks = [];
  Map<String, UserModel> _usersMap = {};
  bool _isLoading = false;
  String? _error;
  String? _currentUserId;

  // Getters
  List<EventModel> get userEvents => _userEvents;
  List<TaskModel> get allTasks => _allTasks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // FIXED: Separate single and recurring tasks
  List<TaskModel> get singleTasks => _allTasks.where((task) => !task.isRecurring).toList();
  List<TaskModel> get recurringTasks => _allTasks.where((task) => task.isRecurring).toList();

  // Performance tracking for team members
  List<MemberPerformance> _topPerformers = [];
  List<MemberPerformance> _laggingMembers = [];
  double _teamCompletionRate = 0.0;

  // Getters for performance data
  List<MemberPerformance> get topPerformers => _topPerformers;
  List<MemberPerformance> get laggingMembers => _laggingMembers;
  double get teamCompletionRate => _teamCompletionRate;

  // FIXED: Admin overview stats (only count single tasks for completion status)
  int get totalActiveEvents => _userEvents.where((e) => !e.isCompleted).length;
  int get totalActiveTasks => singleTasks.where((t) => !t.isCompleted).length;
  int get totalOverdueTasks => singleTasks.where((t) => t.isOverdue && !t.isCompleted).length;
  
  // NEW: Recurring task stats
  int get totalRecurringTasks => recurringTasks.length;
  int get recurringTasksCompletedToday {
    if (_currentUserId == null) return 0;
    return recurringTasks.where((task) => 
      task.isAssignedToUser(_currentUserId!) && 
      task.isCompletedToday(_currentUserId!)
    ).length;
  }
  int get recurringTasksPendingToday {
    if (_currentUserId == null) return 0;
    return recurringTasks.where((task) => 
      task.isAssignedToUser(_currentUserId!) && 
      !task.isCompletedToday(_currentUserId!)
    ).length;
  }

  // FIXED: Member personal stats
  int get myCompletedTasksThisWeek {
    if (_currentUserId == null) return 0;
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    
    int singleTasksCompleted = singleTasks
        .where((task) =>
            task.isCompletedByUser(_currentUserId!) &&
            task.completedBy.any((completion) =>
                completion.userId == _currentUserId! &&
                completion.completedAt.isAfter(weekAgo)))
        .length;

    // For recurring tasks, count completions in the last week
    int recurringTasksCompleted = 0;
    for (var task in recurringTasks.where((t) => t.isAssignedToUser(_currentUserId!))) {
      final userCompletions = task.getCompletionDatesForUser(_currentUserId!);
      for (var dateStr in userCompletions) {
        try {
          final date = DateTime.parse(dateStr);
          if (date.isAfter(weekAgo)) {
            recurringTasksCompleted++;
          }
        } catch (e) {
          // Skip invalid date strings
          continue;
        }
      }
    }

    return singleTasksCompleted + recurringTasksCompleted;
  }

  int get myActiveEvents => _userEvents.where((e) => !e.isCompleted).length;

  // FIXED: My completion rate (includes both single and recurring tasks)
  double get myCompletionRate {
    if (_currentUserId == null) return 0.0;
    
    final mySingleTasks = singleTasks
        .where((task) => task.isAssignedToUser(_currentUserId!))
        .toList();
    final myRecurringTasks = recurringTasks
        .where((task) => task.isAssignedToUser(_currentUserId!))
        .toList();

    if (mySingleTasks.isEmpty && myRecurringTasks.isEmpty) return 0.0;

    // Count completed single tasks
    final completedSingleTasks = mySingleTasks
        .where((task) => task.isCompletedByUser(_currentUserId!))
        .length;

    // Count recurring tasks completed today
    final completedRecurringTasksToday = myRecurringTasks
        .where((task) => task.isCompletedToday(_currentUserId!))
        .length;

    final totalTasks = mySingleTasks.length + myRecurringTasks.length;
    final totalCompleted = completedSingleTasks + completedRecurringTasksToday;

    return (totalCompleted / totalTasks) * 100;
  }

  // Load home data
  Future<void> loadHomeData(String userId) async {
    try {
      _isLoading = true;
      _error = null;
      _currentUserId = userId;
      notifyListeners();

      // Load user events
      _userEvents = await _eventsRepository.getUserEvents(userId);

      // Load all tasks from user events
      final eventIds = _userEvents.map((e) => e.id).toList();
      _allTasks = [];

      for (String eventId in eventIds) {
        final tasks = await _tasksRepository.getTasksByEventId(eventId);
        _allTasks.addAll(tasks);
      }

      // Load user data for performance tracking
      await _loadUsersData();

      // Calculate team performance (only for admins)
      await _calculateTeamPerformance(userId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load home data: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load users data for performance tracking
  Future<void> _loadUsersData() async {
    try {
      // Get all unique user IDs from events and tasks
      Set<String> allUserIds = {};

      // Add users from events
      for (var event in _userEvents) {
        allUserIds.addAll(event.admins.map((a) => a.id));
        allUserIds.addAll(event.members.map((m) => m.id));
      }

      // Add users from tasks
      for (var task in _allTasks) {
        allUserIds.addAll(task.assignedToUsers);
        allUserIds.add(task.createdBy);
        
        // For single tasks
        if (!task.isRecurring) {
          allUserIds.addAll(task.completedBy.map((c) => c.userId));
        } else {
          // For recurring tasks
          for (var dailyCompletion in task.dailyCompletions) {
            allUserIds.addAll(dailyCompletion.completedBy.map((c) => c.userId));
          }
        }
      }

      // Fetch user data from Firestore
      _usersMap = {};
      for (String userId in allUserIds) {
        try {
          final userDoc = await _firestore
              .collection('users')
              .doc(userId)
              .get();
          if (userDoc.exists) {
            _usersMap[userId] = UserModel.fromMap(userDoc.data()!);
          }
        } catch (e) {
          return;
        }
      }
    } catch (e) {
      return;
    }
  }

  // FIXED: Calculate team performance (handles both single and recurring tasks)
  Future<void> _calculateTeamPerformance(String userId) async {
    try {
      // Get only events where user is admin
      final adminEvents = _userEvents
          .where((event) => event.isUserAdmin(userId))
          .toList();
      if (adminEvents.isEmpty) {
        _topPerformers = [];
        _laggingMembers = [];
        _teamCompletionRate = 0.0;
        return;
      }

      // Get all team members from admin's events including admin themselves
      Set<String> teamMemberIds = {};
      for (var event in adminEvents) {
        teamMemberIds.addAll(event.members.map((m) => m.id));
        teamMemberIds.addAll(event.admins.map((a) => a.id));
      }

      // Get tasks only from admin events
      final adminEventIds = adminEvents.map((e) => e.id).toList();
      final adminTasks = _allTasks
          .where((task) => adminEventIds.contains(task.eventId))
          .toList();

      // Calculate performance for each team member INCLUDING ADMIN
      List<MemberPerformance> allPerformances = [];

      for (String memberId in teamMemberIds) {
        final memberTasks = adminTasks
            .where((task) => task.isAssignedToUser(memberId))
            .toList();
        if (memberTasks.isEmpty) continue;

        // Separate single and recurring tasks
        final singleMemberTasks = memberTasks.where((t) => !t.isRecurring).toList();
        final recurringMemberTasks = memberTasks.where((t) => t.isRecurring).toList();

        // Calculate for single tasks
        final completedSingleTasks = singleMemberTasks
            .where((task) => task.isCompletedByUser(memberId))
            .length;
        final overdueSingleTasks = singleMemberTasks
            .where((task) => task.isOverdue && !task.isCompletedByUser(memberId))
            .length;
        final onTimeSingleTasks = singleMemberTasks
            .where((task) => task.isCompletedByUser(memberId) && !task.isOverdue)
            .length;

        // Calculate for recurring tasks (use today's completion)
        final completedRecurringTasksToday = recurringMemberTasks
            .where((task) => task.isCompletedToday(memberId))
            .length;

        // Total calculations
        final totalTasks = singleMemberTasks.length + recurringMemberTasks.length;
        final totalCompleted = completedSingleTasks + completedRecurringTasksToday;
        final totalOverdue = overdueSingleTasks; // Recurring tasks don't have overdue concept
        final totalOnTime = onTimeSingleTasks + completedRecurringTasksToday;

        final completionRate = totalTasks > 0 ? (totalCompleted / totalTasks) * 100 : 0.0;
        final onTimeRate = totalTasks > 0 ? (totalOnTime / totalTasks) * 100 : 0.0;

        final user = _usersMap[memberId];
        if (user != null) {
          allPerformances.add(
            MemberPerformance(
              userId: memberId,
              firstName: user.firstName,
              lastName: user.lastName,
              completionRate: completionRate,
              onTimeRate: onTimeRate,
              totalTasks: totalTasks,
              completedTasks: totalCompleted,
              overdueTasks: totalOverdue,
            ),
          );
        }
      }

      // Sort by performance score
      allPerformances.sort(
        (a, b) => b.performanceScore.compareTo(a.performanceScore),
      );

      // Get top 3 performers and bottom 3 (now including admin if they qualify)
      _topPerformers = allPerformances.take(3).toList();
      _laggingMembers = allPerformances.length > 3
          ? allPerformances.reversed.take(3).toList()
          : [];

      // Calculate overall team completion rate for admin events only
      if (allPerformances.isNotEmpty) {
        _teamCompletionRate =
            allPerformances
                .map((p) => p.completionRate)
                .reduce((a, b) => a + b) /
            allPerformances.length;
      }
    } catch (e) {
      return;
    }
  }

  bool isUserAdmin(String userId) {
    return _userEvents.any((event) => event.isUserAdmin(userId));
  }

  // Check if user is member of any event
  bool isUserMember(String userId) {
    return _userEvents.any((event) => event.isUserMember(userId));
  }

  // Get events where user is admin
  List<EventModel> getAdminEvents(String userId) {
    return _userEvents.where((event) => event.isUserAdmin(userId)).toList();
  }

  // Get events where user is member
  List<EventModel> getMemberEvents(String userId) {
    return _userEvents.where((event) => event.isUserMember(userId)).toList();
  }

  // FIXED: Get urgent tasks for member view (only single tasks can be urgent)
  List<TaskModel> getUrgentTasks(String userId) {
    final mySingleTasks = singleTasks
        .where((task) =>
            task.isAssignedToUser(userId) && !task.isCompletedByUser(userId))
        .toList();

    // Sort by urgency (overdue first, then by deadline)
    mySingleTasks.sort((a, b) {
      if (a.isOverdue && !b.isOverdue) return -1;
      if (!a.isOverdue && b.isOverdue) return 1;
      if (a.deadline != null && b.deadline != null) {
        return a.deadline!.compareTo(b.deadline!);
      }
      return 0;
    });

    return mySingleTasks.take(3).toList(); // Return top 3 most urgent
  }

  // NEW: Get pending recurring tasks for today
  List<TaskModel> getPendingRecurringTasksToday(String userId) {
    return recurringTasks
        .where((task) => 
            task.isAssignedToUser(userId) && 
            !task.isCompletedToday(userId))
        .take(3)
        .toList();
  }

  // NEW: Get completed recurring tasks for today
  List<TaskModel> getCompletedRecurringTasksToday(String userId) {
    return recurringTasks
        .where((task) => 
            task.isAssignedToUser(userId) && 
            task.isCompletedToday(userId))
        .toList();
  }

  // FIXED: Get recent activity (handles both single and recurring tasks)
  List<ActivityItem> getRecentActivity() {
    List<ActivityItem> activities = [];
    final dayAgo = DateTime.now().subtract(const Duration(days: 1));

    // Add recent single task completions
    final recentSingleCompletions = singleTasks.where((task) {
      if (task.completedBy.isEmpty) return false;
      final lastCompletion = task.completedBy.last;
      return lastCompletion.completedAt.isAfter(dayAgo);
    }).toList();

    for (var task in recentSingleCompletions.take(3)) {
      final completion = task.completedBy.last;
      final user = _usersMap[completion.userId];
      if (user != null) {
        activities.add(
          ActivityItem(
            type: 'task_completed',
            message: '${user.firstName} completed "${task.title}"',
            timestamp: completion.completedAt,
          ),
        );
      }
    }

    // Add recent recurring task completions
    for (var task in recurringTasks.take(10)) { // Limit to avoid too much processing
      for (var dailyCompletion in task.dailyCompletions) {
        for (var completion in dailyCompletion.completedBy) {
          if (completion.completedAt.isAfter(dayAgo)) {
            final user = _usersMap[completion.userId];
            if (user != null) {
              activities.add(
                ActivityItem(
                  type: 'recurring_task_completed',
                  message: '${user.firstName} completed "${task.title}" (${dailyCompletion.date})',
                  timestamp: completion.completedAt,
                ),
              );
            }
          }
        }
      }
    }

    // Sort by timestamp and limit
    activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return activities.take(5).toList();
  }

  // NEW: Get today's completion statistics
  Map<String, int> getTodayCompletionStats(String userId) {
    final today = TaskModel.getTodayDateString();
    
    final myRecurringTasks = recurringTasks
        .where((task) => task.isAssignedToUser(userId))
        .toList();
    
    final completedToday = myRecurringTasks
        .where((task) => task.isCompletedToday(userId))
        .length;
    
    final pendingToday = myRecurringTasks.length - completedToday;
    
    return {
      'completed': completedToday,
      'pending': pendingToday,
      'total': myRecurringTasks.length,
    };
  }

  // NEW: Get weekly completion history for recurring tasks
  Map<String, int> getWeeklyRecurringTaskStats(String userId) {
    final now = DateTime.now();
    Map<String, int> weeklyStats = {};
    
    // Initialize last 7 days
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      weeklyStats[dateStr] = 0;
    }
    
    // Count completions for each day
    for (var task in recurringTasks.where((t) => t.isAssignedToUser(userId))) {
      final userCompletions = task.getCompletionDatesForUser(userId);
      for (var dateStr in userCompletions) {
        if (weeklyStats.containsKey(dateStr)) {
          weeklyStats[dateStr] = weeklyStats[dateStr]! + 1;
        }
      }
    }
    
    return weeklyStats;
  }

  // Refresh data
  Future<void> refreshData() async {
    if (_currentUserId != null) {
      await loadHomeData(_currentUserId!);
    }
  }

  // Clear data
  void clearData() {
    _userEvents.clear();
    _allTasks.clear();
    _usersMap.clear();
    _topPerformers.clear();
    _laggingMembers.clear();
    _teamCompletionRate = 0.0;
    _error = null;
    _isLoading = false;
    _currentUserId = null;
    notifyListeners();
  }
}