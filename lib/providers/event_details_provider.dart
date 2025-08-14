// File: providers/event_details_provider.dart
import 'package:event_management/models/task_model.dart';
import 'package:event_management/models/event_model.dart';
import 'package:event_management/repository/event_repository.dart';
import 'package:event_management/repository/task_repository.dart';
import 'package:flutter/material.dart';

class EventDetailsProvider extends ChangeNotifier {
  final TasksRepository _tasksRepository = TasksRepository();
  final EventsRepository _eventsRepository = EventsRepository();

  // State variables
  List<TaskModel> _tasks = [];
  bool _isLoadingTasks = false;
  bool _isLoadingEvent = false;
  String? _errorMessage;
  EventModel? _event;

  // Getters
  List<TaskModel> get tasks => _tasks;
  bool get isLoadingTasks => _isLoadingTasks;
  bool get isLoadingEvent => _isLoadingEvent;
  String? get errorMessage => _errorMessage;
  EventModel? get event => _event;

  // Task filtering - FIXED to handle recurring tasks properly
  List<TaskModel> get singleTasks =>
      _tasks.where((task) => !task.isRecurring).toList();

  List<TaskModel> get recurringTasks =>
      _tasks.where((task) => task.isRecurring).toList();

  // Single task filtering (only applies to single tasks)
  List<TaskModel> get pendingTasks {
    final pending = <TaskModel>[];

    // Add pending single tasks
    pending.addAll(singleTasks.where((task) => task.isPending));

    // Add recurring tasks that are pending for current period
    // Since we don't have currentUserId in EventDetailsProvider,
    // we'll check if ANY user hasn't completed it for the current period
    pending.addAll(
      recurringTasks.where((task) => _isRecurringTaskPending(task)),
    );

    return pending;
  }

  List<TaskModel> get inProgressTasks =>
      singleTasks.where((task) => task.isInProgress).toList();
  List<TaskModel> get completedTasks =>
      singleTasks.where((task) => task.isCompleted).toList();
  List<TaskModel> get overdueTasks =>
      singleTasks.where((task) => task.isOverdue).toList();

  // Task counts
  int get totalTasks => _tasks.length;
  int get singleTasksCount => singleTasks.length;
  int get recurringTasksCount => recurringTasks.length;
  int get pendingCount => pendingTasks.length;
  int get inProgressCount => inProgressTasks.length;
  int get completedCount => completedTasks.length;
  int get overdueCount => overdueTasks.length;

  // Get user-specific tasks
  List<TaskModel> getUserTasks(String userId) {
    return _tasks.where((task) => task.isAssignedToUser(userId)).toList();
  }

  List<TaskModel> getUserSingleTasks(String userId) {
    return getUserTasks(userId).where((task) => !task.isRecurring).toList();
  }

  List<TaskModel> getUserRecurringTasks(String userId) {
    return getUserTasks(userId).where((task) => task.isRecurring).toList();
  }

  List<TaskModel> getUserPendingTasks(String userId) {
    return getUserSingleTasks(userId).where((task) => task.isPending).toList();
  }

  bool _isRecurringTaskPending(TaskModel task) {
    switch (task.recurrenceType) {
      case RecurrenceType.daily:
        // Check if task is not completed today by all assigned users
        return !_isCompletedTodayByAll(task);

      case RecurrenceType.weekly:
        return !_isCompletedThisWeekByAny(task);

      case RecurrenceType.monthly:
        return !_isCompletedThisMonthByAny(task);

      case RecurrenceType.yearly:
        return !_isCompletedThisYearByAny(task);

      case RecurrenceType.none:
        return false;
    }
  }

  bool _isCompletedTodayByAll(TaskModel task) {
    final todayStr = TaskModel.getTodayDateString();
    final completedCount = task.getCompletionCountForDate(todayStr);
    return completedCount >= task.totalAssignees;
  }

  bool _isCompletedThisWeekByAny(TaskModel task) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    for (int i = 0; i < 7; i++) {
      final date = startOfWeek.add(Duration(days: i));
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      if (task.getCompletionCountForDate(dateStr) > 0) {
        return true;
      }
    }
    return false;
  }

  bool _isCompletedThisMonthByAny(TaskModel task) {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month;
    final daysInMonth = DateTime(year, month + 1, 0).day;

    for (int day = 1; day <= daysInMonth; day++) {
      final dateStr =
          '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
      if (task.getCompletionCountForDate(dateStr) > 0) {
        return true;
      }
    }
    return false;
  }

  bool _isCompletedThisYearByAny(TaskModel task) {
    final now = DateTime.now();
    final year = now.year;

    for (int month = 1; month <= 12; month++) {
      final daysInMonth = DateTime(year, month + 1, 0).day;
      for (int day = 1; day <= daysInMonth; day++) {
        final dateStr =
            '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
        if (task.getCompletionCountForDate(dateStr) > 0) {
          return true;
        }
      }
    }
    return false;
  }

  // FIXED: Updated to handle both single and recurring tasks
  List<TaskModel> getUserCompletedTasks(String userId) {
    final userTasks = getUserTasks(userId);
    return userTasks.where((task) {
      if (task.isRecurring) {
        return task.isCompletedToday(userId);
      } else {
        return task.isCompletedByUser(userId);
      }
    }).toList();
  }

  // NEW: Get user's recurring tasks not completed today
  List<TaskModel> getUserPendingRecurringTasks(String userId) {
    return getUserRecurringTasks(
      userId,
    ).where((task) => !task.isCompletedToday(userId)).toList();
  }

  // NEW: Get user's recurring tasks completed today
  List<TaskModel> getUserCompletedRecurringTasksToday(String userId) {
    return getUserRecurringTasks(
      userId,
    ).where((task) => task.isCompletedToday(userId)).toList();
  }

  // Initialize event details
  Future<void> initialize(String eventId) async {
    _setLoadingEvent(true);
    _clearError();

    try {
      await Future.wait([_loadEvent(eventId), loadTasks(eventId)]);
    } catch (e) {
      _setError('Failed to initialize: ${e.toString()}');
    } finally {
      _setLoadingEvent(false);
    }
  }

  // Load event details
  Future<void> _loadEvent(String eventId) async {
    try {
      _event = await _eventsRepository.getEventById(eventId);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load event details: ${e.toString()}');
    }
  }

  // Load tasks for the event
  Future<void> loadTasks(String eventId) async {
    _setLoadingTasks(true);
    _clearError();

    try {
      _tasks = await _tasksRepository.getTasksByEventId(eventId);
      _sortTasks();
    } catch (e) {
      _setError('Failed to load tasks: ${e.toString()}');
    } finally {
      _setLoadingTasks(false);
    }
  }

  // NEW: Load only single tasks
  Future<void> loadSingleTasks(String eventId) async {
    _setLoadingTasks(true);
    _clearError();

    try {
      final singleTasksList = await _tasksRepository.getSingleTasksByEventId(
        eventId,
      );
      // Keep existing recurring tasks and replace single tasks
      _tasks = [...recurringTasks, ...singleTasksList];
      _sortTasks();
    } catch (e) {
      _setError('Failed to load single tasks: ${e.toString()}');
    } finally {
      _setLoadingTasks(false);
    }
  }

  // NEW: Load only recurring tasks
  Future<void> loadRecurringTasks(String eventId) async {
    _setLoadingTasks(true);
    _clearError();

    try {
      final recurringTasksList = await _tasksRepository
          .getRecurringTasksByEventId(eventId);
      // Keep existing single tasks and replace recurring tasks
      _tasks = [...singleTasks, ...recurringTasksList];
      _sortTasks();
    } catch (e) {
      _setError('Failed to load recurring tasks: ${e.toString()}');
    } finally {
      _setLoadingTasks(false);
    }
  }

  // Refresh all data
  Future<void> refresh(String eventId) async {
    try {
      // Force fetch fresh data from the database
      _event = await _eventsRepository.getEventById(eventId);
      _tasks = await _tasksRepository.getTasksByEventId(eventId);
      _sortTasks();
      notifyListeners();
    } catch (e) {
      _setError('Failed to refresh: ${e.toString()}');
    }
  }

  // Force refresh event data only
  Future<void> refreshEvent(String eventId) async {
    try {
      _event = await _eventsRepository.getEventById(eventId);
      notifyListeners();
    } catch (e) {
      _setError('Failed to refresh event: ${e.toString()}');
    }
  }

  // Update event locally (called when changes are made from other screens)
  void updateEvent(EventModel updatedEvent) {
    _event = updatedEvent;
    notifyListeners();
  }

  // Updated promoteToAdmin method in EventDetailsProvider
  Future<void> promoteToAdmin(String eventId, String memberId) async {
    if (_event == null) return;

    try {
      // Update in Firestore first
      await _eventsRepository.promoteMemberToAdmin(eventId, memberId);

      // Find the member to promote
      final memberIndex = _event!.members.indexWhere((m) => m.id == memberId);
      if (memberIndex == -1) {
        throw Exception('Member not found');
      }

      final member = _event!.members[memberIndex];

      // Create new lists (since the original lists might be immutable)
      final updatedMembers = List<EventParticipant>.from(_event!.members);
      final updatedAdmins = List<EventParticipant>.from(_event!.admins);

      // Remove from members and add to admins
      updatedMembers.removeAt(memberIndex);
      updatedAdmins.add(member);

      // Create updated event with new lists
      _event = _event!.copyWith(members: updatedMembers, admins: updatedAdmins);

      notifyListeners();
    } catch (e) {
      // If there's an error, refresh from database to ensure consistency
      await refreshEvent(eventId);
      _setError('Failed to promote member: ${e.toString()}');
      rethrow;
    }
  }

  Future<void> removeFromEvent(String eventId, String memberId) async {
    if (_event == null) return;

    try {
      // Update in Firestore first
      await _eventsRepository.removeUserFromEvent(eventId, memberId);

      // Create new lists (since the original lists might be immutable)
      final updatedMembers = List<EventParticipant>.from(_event!.members);
      final updatedAdmins = List<EventParticipant>.from(_event!.admins);

      // Remove from both lists
      updatedMembers.removeWhere((m) => m.id == memberId);
      updatedAdmins.removeWhere((m) => m.id == memberId);

      // Create updated event with new lists
      _event = _event!.copyWith(members: updatedMembers, admins: updatedAdmins);

      notifyListeners();
    } catch (e) {
      // If there's an error, refresh from database to ensure consistency
      await refreshEvent(eventId);
      _setError('Failed to remove member: ${e.toString()}');
      rethrow;
    }
  }

  // In EventDetailsProvider - demoteToMember method
  Future<void> demoteToMember(String eventId, String adminId) async {
    if (_event == null) return;

    try {
      // Update in Firestore first
      await _eventsRepository.demoteAdminToMember(eventId, adminId);

      // Find the admin to demote
      final adminIndex = _event!.admins.indexWhere((a) => a.id == adminId);
      if (adminIndex == -1) {
        throw Exception('Admin not found');
      }

      final admin = _event!.admins[adminIndex];

      // Create new lists (this will now work properly with the fixed copyWith)
      final updatedMembers = List<EventParticipant>.from(_event!.members);
      final updatedAdmins = List<EventParticipant>.from(_event!.admins);

      // Remove from admins and add to members
      updatedAdmins.removeAt(adminIndex);
      updatedMembers.add(admin);

      // Create updated event with new lists
      _event = _event!.copyWith(members: updatedMembers, admins: updatedAdmins);

      notifyListeners();
    } catch (e) {
      // If there's an error, refresh from database to ensure consistency
      await refreshEvent(eventId);
      _setError('Failed to demote admin: ${e.toString()}');
      rethrow;
    }
  }

  // FIXED: Sort tasks properly handling nullable deadline for recurring tasks
  void _sortTasks() {
    _tasks.sort((a, b) {
      // First sort by task type (single tasks first, then recurring)
      if (a.isRecurring != b.isRecurring) {
        return a.isRecurring ? 1 : -1;
      }

      // For single tasks, use existing logic
      if (!a.isRecurring && !b.isRecurring) {
        // First sort by completion status (incomplete first)
        if (a.isCompleted != b.isCompleted) {
          return a.isCompleted ? 1 : -1;
        }

        // Then by priority (high to low)
        final priorityOrder = {'high': 0, 'medium': 1, 'low': 2};
        final aPriority = priorityOrder[a.priority.toLowerCase()] ?? 1;
        final bPriority = priorityOrder[b.priority.toLowerCase()] ?? 1;

        if (aPriority != bPriority) {
          return aPriority.compareTo(bPriority);
        }

        // Finally by due date (earliest first) - handle nullable deadline
        if (a.deadline != null && b.deadline != null) {
          return a.deadline!.compareTo(b.deadline!);
        } else if (a.deadline != null) {
          return -1; // a has deadline, b doesn't - a comes first
        } else if (b.deadline != null) {
          return 1; // b has deadline, a doesn't - b comes first
        } else {
          return 0; // both null
        }
      }

      // For recurring tasks, sort by priority then creation date
      if (a.isRecurring && b.isRecurring) {
        final priorityOrder = {'high': 0, 'medium': 1, 'low': 2};
        final aPriority = priorityOrder[a.priority.toLowerCase()] ?? 1;
        final bPriority = priorityOrder[b.priority.toLowerCase()] ?? 1;

        if (aPriority != bPriority) {
          return aPriority.compareTo(bPriority);
        }

        // Then by creation date (newest first)
        return b.createdAt.compareTo(a.createdAt);
      }

      return 0;
    });
  }

  Future<void> reloadTasks() async {
    final currentEventId = _event?.id;
    if (currentEventId != null) {
      await loadTasks(currentEventId);
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
        // Reload tasks from database to get the updated state
        final currentEventId = _event?.id;
        if (currentEventId != null) {
          await loadTasks(currentEventId);
        }
      }
      return success;
    } catch (e) {
      _setError('Failed to complete task: ${e.toString()}');
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

  // FIXED: Update task status (only for single tasks)
  Future<bool> updateTaskStatus(String taskId, String newStatus) async {
    try {
      // Find the task first to check if it's recurring
      final task = _tasks.firstWhere((t) => t.id == taskId);
      if (task.isRecurring) {
        _setError('Cannot update status for recurring tasks');
        return false;
      }

      final success = await _tasksRepository.updateTaskStatus(
        taskId,
        newStatus,
      );
      if (success) {
        // Update local task
        final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
        if (taskIndex != -1) {
          _tasks[taskIndex] = _tasks[taskIndex].copyWith(status: newStatus);
          _sortTasks();
          notifyListeners();
        }
      }
      return success;
    } catch (e) {
      _setError('Failed to update task status: ${e.toString()}');
      return false;
    }
  }

  // Delete task (admin only)
  Future<bool> deleteTask(String taskId) async {
    try {
      final success = await _tasksRepository.deleteTask(taskId);
      if (success) {
        // Reload tasks from database to get the updated state
        final currentEventId = _event?.id;
        if (currentEventId != null) {
          await loadTasks(currentEventId);
        }
      }
      return success;
    } catch (e) {
      _setError('Failed to delete task: ${e.toString()}');
      return false;
    }
  }

  // FIXED: Uncomplete task (handles both single and recurring)
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
        // Reload tasks from database to get the updated state
        final currentEventId = _event?.id;
        if (currentEventId != null) {
          await loadTasks(currentEventId);
        }
      }
      return success;
    } catch (e) {
      _setError('Failed to uncomplete task: ${e.toString()}');
      return false;
    }
  }

  // NEW: Uncomplete recurring task for today
  Future<bool> uncompleteTaskToday(String taskId, String userId) async {
    return uncompleteTask(taskId, userId, date: TaskModel.getTodayDateString());
  }

  // Get recent tasks (last 3 for preview)
  List<TaskModel> getRecentTasks({int limit = 3}) {
    final sortedTasks = List<TaskModel>.from(_tasks);
    sortedTasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sortedTasks.take(limit).toList();
  }

  // Get user's recent tasks
  List<TaskModel> getUserRecentTasks(String userId, {int limit = 3}) {
    final userTasks = getUserTasks(userId);
    userTasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return userTasks.take(limit).toList();
  }

  // NEW: Get user's completion history for a recurring task
  Future<List<String>> getUserCompletionHistory(
    String taskId,
    String userId,
  ) async {
    try {
      return await _tasksRepository.getUserCompletionHistory(taskId, userId);
    } catch (e) {
      _setError('Failed to get completion history: ${e.toString()}');
      return [];
    }
  }

  // Private methods
  void _setLoadingTasks(bool loading) {
    _isLoadingTasks = loading;
    notifyListeners();
  }

  void _setLoadingEvent(bool loading) {
    _isLoadingEvent = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
