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

  // Task filtering
  List<TaskModel> get pendingTasks =>
      _tasks.where((task) => task.isPending).toList();
  List<TaskModel> get inProgressTasks =>
      _tasks.where((task) => task.isInProgress).toList();
  List<TaskModel> get completedTasks =>
      _tasks.where((task) => task.isCompleted).toList();
  List<TaskModel> get overdueTasks =>
      _tasks.where((task) => task.isOverdue).toList();

  // Task counts
  int get totalTasks => _tasks.length;
  int get pendingCount => pendingTasks.length;
  int get inProgressCount => inProgressTasks.length;
  int get completedCount => completedTasks.length;
  int get overdueCount => overdueTasks.length;

  // Get user-specific tasks
  List<TaskModel> getUserTasks(String userId) {
    return _tasks.where((task) => task.isAssignedToUser(userId)).toList();
  }

  List<TaskModel> getUserPendingTasks(String userId) {
    return getUserTasks(userId).where((task) => task.isPending).toList();
  }

  List<TaskModel> getUserCompletedTasks(String userId) {
    return getUserTasks(
      userId,
    ).where((task) => task.isCompletedByUser(userId)).toList();
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

  // Sort tasks by priority and due date
  void _sortTasks() {
    _tasks.sort((a, b) {
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

      // Finally by due date (earliest first)
      return a.deadline.compareTo(b.deadline);
    });
  }

  Future<void> reloadTasks() async {
    final currentEventId = _event?.id;
    if (currentEventId != null) {
      await loadTasks(currentEventId);
    }
  }

  // Complete a task
  Future<bool> completeTask(String taskId, String userId) async {
    try {
      final success = await _tasksRepository.completeTask(taskId, userId);
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

  // Update task status
  Future<bool> updateTaskStatus(String taskId, String newStatus) async {
    try {
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

  Future<bool> uncompleteTask(String taskId, String userId) async {
    try {
      final success = await _tasksRepository.uncompleteTask(taskId, userId);
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
