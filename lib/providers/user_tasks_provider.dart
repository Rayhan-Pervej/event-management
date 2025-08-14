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
  String? _currentUserId;

  // Getters
  List<TaskModel> get allTasks => _allTasks;
  Map<String, EventModel> get eventsMap => _eventsMap;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // FIXED: Separate single and recurring tasks
  List<TaskModel> get singleTasks =>
      _allTasks.where((task) => !task.isRecurring).toList();
  List<TaskModel> get recurringTasks =>
      _allTasks.where((task) => task.isRecurring).toList();

  // FIXED: Filtered task lists (only for single tasks - recurring tasks don't have deadlines/completion status)
  List<TaskModel> get overdueTasks {
    final now = DateTime.now();
    return singleTasks
        .where(
          (task) =>
              !task.isCompleted &&
              task.deadline != null &&
              task.deadline!.isBefore(now),
        )
        .toList();
  }

  List<TaskModel> get dueTodayTasks {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    return singleTasks
        .where(
          (task) =>
              !task.isCompleted &&
              task.deadline != null &&
              task.deadline!.isAfter(today) &&
              task.deadline!.isBefore(tomorrow),
        )
        .toList();
  }

  List<TaskModel> get upcomingTasks {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final nextWeek = today.add(const Duration(days: 7));

    return singleTasks
        .where(
          (task) =>
              !task.isCompleted &&
              task.deadline != null &&
              task.deadline!.isAfter(today.add(const Duration(days: 1))) &&
              task.deadline!.isBefore(nextWeek),
        )
        .toList();
  }

  List<TaskModel> get completedTasks {
    return singleTasks.where((task) => task.isCompleted).toList();
  }

  List<TaskModel> get pendingTasks {
    return singleTasks
        .where(
          (task) =>
              !task.isCompleted &&
              (task.deadline == null || task.deadline!.isAfter(DateTime.now())),
        )
        .toList();
  }

  // FIXED: Smart recurring task pending logic based on recurrence type
  List<TaskModel> get recurringTasksPending {
    if (_currentUserId == null) return [];
    return recurringTasks
        .where((task) => !_isCompletedForCurrentPeriod(task, _currentUserId!))
        .toList();
  }

  List<TaskModel> get recurringTasksCompleted {
    if (_currentUserId == null) return [];
    return recurringTasks
        .where((task) => _isCompletedForCurrentPeriod(task, _currentUserId!))
        .toList();
  }

  // Helper method to check completion based on recurrence type
  bool _isCompletedForCurrentPeriod(TaskModel task, String userId) {
    switch (task.recurrenceType) {
      case RecurrenceType.daily:
        return task.isCompletedToday(userId);

      case RecurrenceType.weekly:
        return _isCompletedThisWeek(task, userId);

      case RecurrenceType.monthly:
        return _isCompletedThisMonth(task, userId);

      case RecurrenceType.yearly:
        return _isCompletedThisYear(task, userId);

      case RecurrenceType.none:
        return false;
    }
  }

  // Helper methods for different time periods
  bool _isCompletedThisWeek(TaskModel task, String userId) {
    final now = DateTime.now();
    // Get Monday of current week
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    // Check each day of this week
    for (int i = 0; i < 7; i++) {
      final date = startOfWeek.add(Duration(days: i));
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      if (task.isCompletedForDate(dateStr, userId)) {
        return true;
      }
    }
    return false;
  }

  bool _isCompletedThisMonth(TaskModel task, String userId) {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month;
    final daysInMonth = DateTime(year, month + 1, 0).day;

    // Check each day of this month
    for (int day = 1; day <= daysInMonth; day++) {
      final dateStr =
          '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
      if (task.isCompletedForDate(dateStr, userId)) {
        return true;
      }
    }
    return false;
  }

  bool _isCompletedThisYear(TaskModel task, String userId) {
    final now = DateTime.now();
    final year = now.year;

    // Check each month of this year
    for (int month = 1; month <= 12; month++) {
      final daysInMonth = DateTime(year, month + 1, 0).day;
      for (int day = 1; day <= daysInMonth; day++) {
        final dateStr =
            '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
        if (task.isCompletedForDate(dateStr, userId)) {
          return true;
        }
      }
    }
    return false;
  }

  // UPDATED: Combined task lists with smart recurring logic
  List<TaskModel> get allCompletedTasks {
    if (_currentUserId == null) return completedTasks;
    return [
      ...completedTasks,
      ...recurringTasksCompleted, // FIXED: Use smart completion check
    ];
  }

  List<TaskModel> get allPendingTasks {
    if (_currentUserId == null) return pendingTasks;
    return [
      ...pendingTasks,
      ...recurringTasksPending, // FIXED: Use smart pending check
    ];
  }

  // UPDATED: Statistics with smart logic
  int get recurringCompletedCount => recurringTasksCompleted.length;
  int get recurringPendingCount => recurringTasksPending.length;

  // Keep the old methods for backward compatibility if needed
  List<TaskModel> get recurringTasksCompletedToday {
    if (_currentUserId == null) return [];
    return recurringTasks
        .where((task) => task.isCompletedToday(_currentUserId!))
        .toList();
  }

  List<TaskModel> get recurringTasksPendingToday {
    if (_currentUserId == null) return [];
    return recurringTasks
        .where((task) => !task.isCompletedToday(_currentUserId!))
        .toList();
  }

  // FIXED: Statistics
  int get totalTasks => _allTasks.length;
  int get singleTasksCount => singleTasks.length;
  int get recurringTasksCount => recurringTasks.length;
  int get completedCount => completedTasks.length;
  int get pendingCount => pendingTasks.length;
  int get overdueCount => overdueTasks.length;

  // NEW: Recurring task statistics
  int get recurringCompletedTodayCount => recurringTasksCompletedToday.length;
  int get recurringPendingTodayCount => recurringTasksPendingToday.length;

  // NEW: Combined statistics
  int get totalCompletedToday => completedCount + recurringCompletedTodayCount;
  int get totalPendingToday => pendingCount + recurringPendingTodayCount;

  // Load user tasks
  Future<void> loadUserTasks(String userId) async {
    try {
      _isLoading = true;
      _error = null;
      _currentUserId = userId;
      notifyListeners();

      // Get user's tasks
      final tasks = await _tasksRepository.getUserTasks(userId);

      // Get all events to map event info
      final events = await _eventsRepository.getAllEvents();

      // Create events map for quick lookup
      _eventsMap = {for (var event in events) event.id: event};

      // Filter tasks to only include those from events user participates in
      _allTasks = tasks.where((task) {
        final event = _eventsMap[task.eventId];
        return event != null &&
            (event.isUserAdmin(userId) || event.isUserMember(userId));
      }).toList();

      // FIXED: Sort tasks properly handling nullable deadlines
      _sortTasks();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load tasks: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // NEW: Load only single tasks
  Future<void> loadUserSingleTasks(String userId) async {
    try {
      _isLoading = true;
      _error = null;
      _currentUserId = userId;
      notifyListeners();

      final tasks = await _tasksRepository.getUserSingleTasks(userId);
      final events = await _eventsRepository.getAllEvents();

      _eventsMap = {for (var event in events) event.id: event};

      // Keep existing recurring tasks and replace single tasks
      final existingRecurringTasks = recurringTasks;
      final newSingleTasks = tasks.where((task) {
        final event = _eventsMap[task.eventId];
        return event != null &&
            (event.isUserAdmin(userId) || event.isUserMember(userId));
      }).toList();

      _allTasks = [...existingRecurringTasks, ...newSingleTasks];
      _sortTasks();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load single tasks: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // NEW: Load only recurring tasks
  Future<void> loadUserRecurringTasks(String userId) async {
    try {
      _isLoading = true;
      _error = null;
      _currentUserId = userId;
      notifyListeners();

      final tasks = await _tasksRepository.getUserRecurringTasks(userId);
      final events = await _eventsRepository.getAllEvents();

      _eventsMap = {for (var event in events) event.id: event};

      // Keep existing single tasks and replace recurring tasks
      final existingSingleTasks = singleTasks;
      final newRecurringTasks = tasks.where((task) {
        final event = _eventsMap[task.eventId];
        return event != null &&
            (event.isUserAdmin(userId) || event.isUserMember(userId));
      }).toList();

      _allTasks = [...existingSingleTasks, ...newRecurringTasks];
      _sortTasks();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load recurring tasks: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // FIXED: Complete a task (handles both single and recurring)
  Future<bool> completeTask(
    String taskId,
    String userId, {
    String? date,
  }) async {
    try {
      final success = await _tasksRepository.completeTask(
        taskId,
        userId,
        date: date,
      );
      if (success) {
        // Find the task
        final taskIndex = _allTasks.indexWhere((task) => task.id == taskId);
        if (taskIndex != -1) {
          final task = _allTasks[taskIndex];

          if (task.isRecurring) {
            // For recurring tasks, update daily completions
            final updatedTask = task.markCompletedForDate(
              date ?? TaskModel.getTodayDateString(),
              userId,
            );
            _allTasks[taskIndex] = updatedTask;
          } else {
            // For single tasks, update completedBy and status
            final updatedCompletedBy = [
              ...task.completedBy,
              CompletionDetails(userId: userId, completedAt: DateTime.now()),
            ];

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
          }
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

  // NEW: Complete recurring task for today
  Future<bool> completeTaskToday(String taskId, String userId) async {
    return completeTask(taskId, userId, date: TaskModel.getTodayDateString());
  }

  // NEW: Complete recurring task for specific date
  Future<bool> completeTaskForDate(
    String taskId,
    String userId,
    String date,
  ) async {
    return completeTask(taskId, userId, date: date);
  }

  // FIXED: Uncomplete a task (handles both single and recurring)
  Future<bool> uncompleteTask(
    String taskId,
    String userId, {
    String? date,
  }) async {
    try {
      final success = await _tasksRepository.uncompleteTask(
        taskId,
        userId,
        date: date,
      );
      if (success) {
        final taskIndex = _allTasks.indexWhere((task) => task.id == taskId);
        if (taskIndex != -1) {
          final task = _allTasks[taskIndex];

          if (task.isRecurring) {
            // For recurring tasks, remove from daily completions
            final targetDate = date ?? TaskModel.getTodayDateString();
            List<DailyCompletion> updatedCompletions = List.from(
              task.dailyCompletions,
            );

            for (int i = 0; i < updatedCompletions.length; i++) {
              if (updatedCompletions[i].date == targetDate) {
                final updatedCompletedBy = updatedCompletions[i].completedBy
                    .where((completion) => completion.userId != userId)
                    .toList();

                if (updatedCompletedBy.isEmpty) {
                  updatedCompletions.removeAt(i);
                } else {
                  updatedCompletions[i] = DailyCompletion(
                    date: targetDate,
                    completedBy: updatedCompletedBy,
                  );
                }
                break;
              }
            }

            _allTasks[taskIndex] = task.copyWith(
              dailyCompletions: updatedCompletions,
            );
          } else {
            // For single tasks, update completedBy and status
            final updatedCompletedBy = task.completedBy
                .where((completion) => completion.userId != userId)
                .toList();

            String newStatus;
            if (updatedCompletedBy.isEmpty) {
              newStatus = 'pending';
            } else if (updatedCompletedBy.length <
                task.assignedToUsers.length) {
              newStatus = 'in_progress';
            } else {
              newStatus = 'completed';
            }

            _allTasks[taskIndex] = task.copyWith(
              completedBy: updatedCompletedBy,
              status: newStatus,
            );
          }
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

  // NEW: Uncomplete recurring task for today
  Future<bool> uncompleteTaskToday(String taskId, String userId) async {
    return uncompleteTask(taskId, userId, date: TaskModel.getTodayDateString());
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

  // FIXED: Sort tasks properly handling both single and recurring tasks
  void _sortTasks() {
    _allTasks.sort((a, b) {
      // First sort by task type (single tasks first, then recurring)
      if (a.isRecurring != b.isRecurring) {
        return a.isRecurring ? 1 : -1;
      }

      // For single tasks
      if (!a.isRecurring && !b.isRecurring) {
        // Sort by deadline (handle nulls)
        if (a.deadline != null && b.deadline != null) {
          return a.deadline!.compareTo(b.deadline!);
        } else if (a.deadline != null) {
          return -1; // a has deadline, comes first
        } else if (b.deadline != null) {
          return 1; // b has deadline, comes first
        } else {
          return 0; // both null
        }
      }

      // For recurring tasks, sort by priority then creation date
      if (a.isRecurring && b.isRecurring) {
        final aPriority = _getPriorityOrder(a.priority);
        final bPriority = _getPriorityOrder(b.priority);

        if (aPriority != bPriority) {
          return aPriority.compareTo(bPriority);
        }

        return b.createdAt.compareTo(a.createdAt); // Newest first
      }

      return 0;
    });
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

  // FIXED: Sort tasks by deadline (only applicable to single tasks)
  void sortTasksByDeadline() {
    _allTasks.sort((a, b) {
      // Recurring tasks go to the end
      if (a.isRecurring && !b.isRecurring) return 1;
      if (!a.isRecurring && b.isRecurring) return -1;

      // Both single tasks
      if (!a.isRecurring && !b.isRecurring) {
        if (a.deadline != null && b.deadline != null) {
          return a.deadline!.compareTo(b.deadline!);
        } else if (a.deadline != null) {
          return -1;
        } else if (b.deadline != null) {
          return 1;
        }
      }

      return 0;
    });
    notifyListeners();
  }

  // NEW: Sort tasks by completion status (for current user)
  void sortTasksByCompletionStatus() {
    if (_currentUserId == null) return;

    _allTasks.sort((a, b) {
      final aCompleted = a.isRecurring
          ? a.isCompletedToday(_currentUserId!)
          : a.isCompletedByUser(_currentUserId!);
      final bCompleted = b.isRecurring
          ? b.isCompletedToday(_currentUserId!)
          : b.isCompletedByUser(_currentUserId!);

      // Incomplete tasks first
      if (!aCompleted && bCompleted) return -1;
      if (aCompleted && !bCompleted) return 1;

      return 0;
    });
    notifyListeners();
  }

  // Get event for task
  EventModel? getEventForTask(String eventId) {
    return _eventsMap[eventId];
  }

  // NEW: Get completion history for recurring task
  Future<List<String>> getTaskCompletionHistory(String taskId) async {
    if (_currentUserId == null) return [];
    try {
      return await _tasksRepository.getUserCompletionHistory(
        taskId,
        _currentUserId!,
      );
    } catch (e) {
      _error = 'Failed to get completion history: $e';
      notifyListeners();
      return [];
    }
  }

  // NEW: Get today's completion statistics
  Map<String, int> getTodayCompletionStats() {
    if (_currentUserId == null) {
      return {'completed': 0, 'pending': 0, 'total': 0};
    }

    final completedToday = recurringTasksCompletedToday.length;
    final pendingToday = recurringTasksPendingToday.length;

    return {
      'completed': completedToday,
      'pending': pendingToday,
      'total': recurringTasks.length,
    };
  }

  // NEW: Filter tasks by recurrence type
  List<TaskModel> getTasksByRecurrenceType(RecurrenceType type) {
    return recurringTasks.where((task) => task.recurrenceType == type).toList();
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
    _currentUserId = null;
    notifyListeners();
  }
}
