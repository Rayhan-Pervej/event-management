// File: providers/user_tasks_provider.dart
import 'package:event_management/repository/event_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:event_management/models/task_model.dart';
import 'package:event_management/models/event_model.dart';
import 'package:event_management/repository/task_repository.dart';


class UserTasksProvider with ChangeNotifier {
  final TasksRepository _tasksRepository = TasksRepository();
  final EventsRepository _eventsRepository = EventsRepository();

  List<TaskModel> _allTasks = [];
  Map<String, EventModel> _eventsMap = {};
  bool _isLoading = false;
  String? _error;

  // Getters
  List<TaskModel> get allTasks => _allTasks;
  Map<String, EventModel> get eventsMap => _eventsMap;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Filtered task lists
  List<TaskModel> get overdueTasks {
    final now = DateTime.now();
    return _allTasks
        .where((task) => 
            !task.isCompleted && 
            task.deadline.isBefore(now))
        .toList();
  }

  List<TaskModel> get dueTodayTasks {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    
    return _allTasks
        .where((task) => 
            !task.isCompleted &&
            task.deadline.isAfter(today) && 
            task.deadline.isBefore(tomorrow))
        .toList();
  }

  List<TaskModel> get upcomingTasks {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final nextWeek = today.add(const Duration(days: 7));
    
    return _allTasks
        .where((task) => 
            !task.isCompleted &&
            task.deadline.isAfter(today.add(const Duration(days: 1))) && 
            task.deadline.isBefore(nextWeek))
        .toList();
  }

  List<TaskModel> get completedTasks {
    return _allTasks
        .where((task) => task.isCompleted)
        .toList();
  }

  List<TaskModel> get pendingTasks {
    return _allTasks
        .where((task) => 
            !task.isCompleted && 
            task.deadline.isAfter(DateTime.now()))
        .toList();
  }

  // Statistics
  int get totalTasks => _allTasks.length;
  int get completedCount => completedTasks.length;
  int get pendingCount => pendingTasks.length;
  int get overdueCount => overdueTasks.length;

  // Load user tasks
  Future<void> loadUserTasks(String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Get user's tasks
      final tasks = await _tasksRepository.getUserTasks(userId);
      
      // Get all events to map event info
      final events = await _eventsRepository.getAllEvents();
      
      // Create events map for quick lookup
      _eventsMap = {
        for (var event in events) event.id: event
      };

      // Filter tasks to only include those from events user participates in
      _allTasks = tasks.where((task) {
        final event = _eventsMap[task.eventId];
        return event != null && 
               (event.isUserAdmin(userId) || event.isUserMember(userId));
      }).toList();

      // Sort tasks by deadline (earliest first)
      _allTasks.sort((a, b) => a.deadline.compareTo(b.deadline));

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load tasks: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Complete a task
  Future<bool> completeTask(String taskId, String userId) async {
    try {
      final success = await _tasksRepository.completeTask(taskId, userId);
      if (success) {
        // Update local task
        final taskIndex = _allTasks.indexWhere((task) => task.id == taskId);
        if (taskIndex != -1) {
          final task = _allTasks[taskIndex];
          final updatedCompletedBy = [
            ...task.completedBy,
            CompletionDetails(userId: userId, completedAt: DateTime.now()),
          ];
          
          // Update status
          String newStatus = task.status;
          if (updatedCompletedBy.length >= task.assignedToUsers.length) {
            newStatus = 'completed';
          } else if (task.isPending) {
            newStatus = 'in_progress';
          }

          _allTasks[taskIndex] = task.copyWith(
            completedBy: updatedCompletedBy,
            status: newStatus,
          );
          notifyListeners();
        }
      }
      return success;
    } catch (e) {
      _error = 'Failed to complete task: $e';
      notifyListeners();
      return false;
    }
  }

  // Uncomplete a task
  Future<bool> uncompleteTask(String taskId, String userId) async {
    try {
      final success = await _tasksRepository.uncompleteTask(taskId, userId);
      if (success) {
        // Update local task
        final taskIndex = _allTasks.indexWhere((task) => task.id == taskId);
        if (taskIndex != -1) {
          final task = _allTasks[taskIndex];
          final updatedCompletedBy = task.completedBy
              .where((completion) => completion.userId != userId)
              .toList();

          // Update status
          String newStatus;
          if (updatedCompletedBy.isEmpty) {
            newStatus = 'pending';
          } else if (updatedCompletedBy.length < task.assignedToUsers.length) {
            newStatus = 'in_progress';
          } else {
            newStatus = 'completed';
          }

          _allTasks[taskIndex] = task.copyWith(
            completedBy: updatedCompletedBy,
            status: newStatus,
          );
          notifyListeners();
        }
      }
      return success;
    } catch (e) {
      _error = 'Failed to uncomplete task: $e';
      notifyListeners();
      return false;
    }
  }

  // Get task priority order for sorting
  int _getPriorityOrder(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return 1;
      case 'medium':
        return 2;
      case 'low':
        return 3;
      default:
        return 4;
    }
  }

  // Sort tasks by priority
  void sortTasksByPriority() {
    _allTasks.sort((a, b) {
      final aPriority = _getPriorityOrder(a.priority);
      final bPriority = _getPriorityOrder(b.priority);
      return aPriority.compareTo(bPriority);
    });
    notifyListeners();
  }

  // Sort tasks by deadline
  void sortTasksByDeadline() {
    _allTasks.sort((a, b) => a.deadline.compareTo(b.deadline));
    notifyListeners();
  }

  // Get event for task
  EventModel? getEventForTask(String eventId) {
    return _eventsMap[eventId];
  }

  // Refresh tasks
  Future<void> refreshTasks(String userId) async {
    await loadUserTasks(userId);
  }

  // Clear data
  void clearData() {
    _allTasks.clear();
    _eventsMap.clear();
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}