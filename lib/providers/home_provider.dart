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

  // Performance tracking for team members
  List<MemberPerformance> _topPerformers = [];
  List<MemberPerformance> _laggingMembers = [];
  double _teamCompletionRate = 0.0;

  // Getters for performance data
  List<MemberPerformance> get topPerformers => _topPerformers;
  List<MemberPerformance> get laggingMembers => _laggingMembers;
  double get teamCompletionRate => _teamCompletionRate;

  // Admin overview stats
  int get totalActiveEvents => _userEvents.where((e) => !e.isCompleted).length;
  int get totalActiveTasks => _allTasks.where((t) => !t.isCompleted).length;
  int get totalOverdueTasks => _allTasks.where((t) => t.isOverdue && !t.isCompleted).length;
  
  // Member personal stats
  int get myCompletedTasksThisWeek {
    if (_currentUserId == null) return 0;
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return _allTasks.where((task) => 
      task.isCompletedByUser(_currentUserId!) &&
      task.completedBy.any((completion) => 
        completion.userId == _currentUserId! &&
        completion.completedAt.isAfter(weekAgo)
      )
    ).length;
  }

  int get myActiveEvents => _userEvents.where((e) => !e.isCompleted).length;

  double get myCompletionRate {
    if (_currentUserId == null) return 0.0;
    final myTasks = _allTasks.where((task) => task.isAssignedToUser(_currentUserId!)).toList();
    if (myTasks.isEmpty) return 0.0;
    final completedTasks = myTasks.where((task) => task.isCompletedByUser(_currentUserId!)).length;
    return (completedTasks / myTasks.length) * 100;
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
        allUserIds.addAll(task.completedBy.map((c) => c.userId));
      }

      // Fetch user data from Firestore
      _usersMap = {};
      for (String userId in allUserIds) {
        try {
          final userDoc = await _firestore.collection('users').doc(userId).get();
          if (userDoc.exists) {
            _usersMap[userId] = UserModel.fromMap(userDoc.data()!);
          }
        } catch (e) {
          print('Error loading user $userId: $e');
        }
      }
    } catch (e) {
      print('Error loading users data: $e');
    }
  }

  // Calculate team performance for admin view
  Future<void> _calculateTeamPerformance(String userId) async {
    try {
      // Only calculate for admins
      final isAdmin = _userEvents.any((event) => event.isUserAdmin(userId));
      if (!isAdmin) return;

      // Get all team members from admin's events
      Set<String> teamMemberIds = {};
      for (var event in _userEvents.where((e) => e.isUserAdmin(userId))) {
        teamMemberIds.addAll(event.members.map((m) => m.id));
        teamMemberIds.addAll(event.admins.map((a) => a.id));
      }

      // Calculate performance for each team member
      List<MemberPerformance> allPerformances = [];
      
      for (String memberId in teamMemberIds) {
        if (memberId == userId) continue; // Skip self
        
        final memberTasks = _allTasks.where((task) => task.isAssignedToUser(memberId)).toList();
        if (memberTasks.isEmpty) continue;

        final completedTasks = memberTasks.where((task) => task.isCompletedByUser(memberId)).length;
        final overdueTasks = memberTasks.where((task) => task.isOverdue && !task.isCompletedByUser(memberId)).length;
        final onTimeTasks = memberTasks.where((task) => 
          task.isCompletedByUser(memberId) && 
          !task.isOverdue
        ).length;

        final completionRate = memberTasks.isNotEmpty ? (completedTasks / memberTasks.length) * 100 : 0.0;
        final onTimeRate = memberTasks.isNotEmpty ? (onTimeTasks / memberTasks.length) * 100 : 0.0;

        final user = _usersMap[memberId];
        if (user != null) {
          allPerformances.add(MemberPerformance(
            userId: memberId,
            firstName: user.firstName,
            lastName: user.lastName,
            completionRate: completionRate,
            onTimeRate: onTimeRate,
            totalTasks: memberTasks.length,
            completedTasks: completedTasks,
            overdueTasks: overdueTasks,
          ));
        }
      }

      // Sort by performance score (combination of completion rate and on-time rate)
      allPerformances.sort((a, b) => b.performanceScore.compareTo(a.performanceScore));

      // Get top 3 performers and bottom 3
      _topPerformers = allPerformances.take(3).toList();
      _laggingMembers = allPerformances.length > 3 
          ? allPerformances.reversed.take(3).toList() 
          : [];

      // Calculate overall team completion rate
      if (allPerformances.isNotEmpty) {
        _teamCompletionRate = allPerformances
            .map((p) => p.completionRate)
            .reduce((a, b) => a + b) / allPerformances.length;
      }

    } catch (e) {
      print('Error calculating team performance: $e');
    }
  }

  // Check if user is admin of any event
  bool isUserAdmin(String userId) {
    return _userEvents.any((event) => event.isUserAdmin(userId));
  }

  // Get urgent tasks for member view
  List<TaskModel> getUrgentTasks(String userId) {
    final myTasks = _allTasks.where((task) => 
      task.isAssignedToUser(userId) && !task.isCompletedByUser(userId)
    ).toList();

    // Sort by urgency (overdue first, then by deadline)
    myTasks.sort((a, b) {
      if (a.isOverdue && !b.isOverdue) return -1;
      if (!a.isOverdue && b.isOverdue) return 1;
      return a.deadline.compareTo(b.deadline);
    });

    return myTasks.take(3).toList(); // Return top 3 most urgent
  }

  // Get recent activity
  List<ActivityItem> getRecentActivity() {
    List<ActivityItem> activities = [];

    // Add recent task completions
    final recentCompletions = _allTasks.where((task) {
      if (task.completedBy.isEmpty) return false;
      final lastCompletion = task.completedBy.last;
      final dayAgo = DateTime.now().subtract(const Duration(days: 1));
      return lastCompletion.completedAt.isAfter(dayAgo);
    }).toList();

    for (var task in recentCompletions.take(5)) {
      final completion = task.completedBy.last;
      final user = _usersMap[completion.userId];
      if (user != null) {
        activities.add(ActivityItem(
          type: 'task_completed',
          message: '${user.firstName} completed "${task.title}"',
          timestamp: completion.completedAt,
        ));
      }
    }

    // Sort by timestamp
    activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    return activities.take(5).toList();
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