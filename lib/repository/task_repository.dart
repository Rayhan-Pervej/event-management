// File: repository/task_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_management/models/task_model.dart';

class TasksRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'tasks';

  // Create Task
  Future<String> createTask(TaskModel task) async {
    try {
      final docRef = _firestore.collection(_collection).doc();
      final taskWithId = task.copyWith(id: docRef.id);
      await docRef.set(taskWithId.toJson());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create task: $e');
    }
  }

  // Get Tasks by Event ID
  Future<List<TaskModel>> getTasksByEventId(String eventId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('eventId', isEqualTo: eventId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => TaskModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch tasks: $e');
    }
  }

  // Get Single Tasks by Event ID
  Future<List<TaskModel>> getSingleTasksByEventId(String eventId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('eventId', isEqualTo: eventId)
          .where('isRecurring', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => TaskModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch single tasks: $e');
    }
  }

  // Get Recurring Tasks by Event ID
  Future<List<TaskModel>> getRecurringTasksByEventId(String eventId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('eventId', isEqualTo: eventId)
          .where('isRecurring', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => TaskModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch recurring tasks: $e');
    }
  }

  // Get Task by ID
  Future<TaskModel?> getTaskById(String taskId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(taskId).get();
      if (doc.exists) {
        return TaskModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch task: $e');
    }
  }

  // Get User Tasks (assigned to user)
  Future<List<TaskModel>> getUserTasks(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('assignedToUsers', arrayContains: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => TaskModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch user tasks: $e');
    }
  }

  // Get User Single Tasks
  Future<List<TaskModel>> getUserSingleTasks(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('assignedToUsers', arrayContains: userId)
          .where('isRecurring', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => TaskModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch user single tasks: $e');
    }
  }

  // Get User Recurring Tasks
  Future<List<TaskModel>> getUserRecurringTasks(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('assignedToUsers', arrayContains: userId)
          .where('isRecurring', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => TaskModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch user recurring tasks: $e');
    }
  }

  // Complete Task (handles both single and recurring)
  Future<bool> completeTask(String taskId, String userId, {String? date}) async {
    try {
      final taskDoc = await _firestore.collection(_collection).doc(taskId).get();
      if (!taskDoc.exists) return false;

      final task = TaskModel.fromFirestore(taskDoc);
      
      // Check if user is assigned to this task
      if (!task.isAssignedToUser(userId)) {
        throw Exception('User is not assigned to this task');
      }

      if (task.isRecurring) {
        return _completeRecurringTask(task, userId, date ?? TaskModel.getTodayDateString());
      } else {
        return _completeSingleTask(task, userId);
      }
    } catch (e) {
      throw Exception('Failed to complete task: $e');
    }
  }

  // Complete Single Task (private method)
  Future<bool> _completeSingleTask(TaskModel task, String userId) async {
    // Check if user already completed this task
    if (task.isCompletedByUser(userId)) {
      return true; // Already completed
    }

    // Add completion details
    final updatedCompletedBy = [
      ...task.completedBy,
      CompletionDetails(userId: userId, completedAt: DateTime.now()),
    ];

    // Update status to completed if all assigned users have completed
    String newStatus = task.status;
    if (updatedCompletedBy.length >= task.assignedToUsers.length) {
      newStatus = 'completed';
    } else if (task.isPending) {
      newStatus = 'in_progress';
    }

    await _firestore.collection(_collection).doc(task.id).update({
      'completedBy': updatedCompletedBy.map((c) => c.toMap()).toList(),
      'status': newStatus,
    });

    return true;
  }

  // Complete Recurring Task (private method)
  Future<bool> _completeRecurringTask(TaskModel task, String userId, String date) async {
    // Check if user already completed this task for the specified date
    if (task.isCompletedForDate(date, userId)) {
      return true; // Already completed for this date
    }

    final updatedTask = task.markCompletedForDate(date, userId);

    await _firestore.collection(_collection).doc(task.id).update({
      'dailyCompletions': updatedTask.dailyCompletions.map((dc) => dc.toMap()).toList(),
    });

    return true;
  }

  // Complete Task for Today (convenience method for recurring tasks)
  Future<bool> completeTaskToday(String taskId, String userId) async {
    return completeTask(taskId, userId, date: TaskModel.getTodayDateString());
  }

  // Complete Task for Specific Date (for recurring tasks)
  Future<bool> completeTaskForDate(String taskId, String userId, String date) async {
    return completeTask(taskId, userId, date: date);
  }

  // Uncomplete Task (handles both single and recurring)
  Future<bool> uncompleteTask(String taskId, String userId, {String? date}) async {
    try {
      final taskDoc = await _firestore.collection(_collection).doc(taskId).get();
      if (!taskDoc.exists) return false;

      final task = TaskModel.fromFirestore(taskDoc);

      if (task.isRecurring) {
        return _uncompleteRecurringTask(task, userId, date ?? TaskModel.getTodayDateString());
      } else {
        return _uncompleteSingleTask(task, userId);
      }
    } catch (e) {
      throw Exception('Failed to uncomplete task: $e');
    }
  }

  // Uncomplete Single Task (private method)
  Future<bool> _uncompleteSingleTask(TaskModel task, String userId) async {
    // Check if user has completed this task
    if (!task.isCompletedByUser(userId)) {
      return true; // User hasn't completed it, nothing to do
    }

    // Remove user from completed list
    final updatedCompletedBy = task.completedBy
        .where((completion) => completion.userId != userId)
        .toList();

    // Update status based on remaining completions
    String newStatus;
    if (updatedCompletedBy.isEmpty) {
      newStatus = 'pending';
    } else if (updatedCompletedBy.length < task.assignedToUsers.length) {
      newStatus = 'in_progress';
    } else {
      newStatus = 'completed';
    }

    await _firestore.collection(_collection).doc(task.id).update({
      'completedBy': updatedCompletedBy.map((c) => c.toMap()).toList(),
      'status': newStatus,
    });

    return true;
  }

  // Uncomplete Recurring Task (private method)
  Future<bool> _uncompleteRecurringTask(TaskModel task, String userId, String date) async {
    // Check if user has completed this task for the specified date
    if (!task.isCompletedForDate(date, userId)) {
      return true; // User hasn't completed it for this date, nothing to do
    }

    // Remove user completion for the specified date
    List<DailyCompletion> updatedCompletions = List.from(task.dailyCompletions);
    
    for (int i = 0; i < updatedCompletions.length; i++) {
      if (updatedCompletions[i].date == date) {
        final updatedCompletedBy = updatedCompletions[i].completedBy
            .where((completion) => completion.userId != userId)
            .toList();
        
        if (updatedCompletedBy.isEmpty) {
          // Remove the entire date entry if no one completed it
          updatedCompletions.removeAt(i);
        } else {
          // Update with remaining completions
          updatedCompletions[i] = DailyCompletion(
            date: date,
            completedBy: updatedCompletedBy,
          );
        }
        break;
      }
    }

    await _firestore.collection(_collection).doc(task.id).update({
      'dailyCompletions': updatedCompletions.map((dc) => dc.toMap()).toList(),
    });

    return true;
  }

  // Update Task Status (only for single tasks)
  Future<bool> updateTaskStatus(String taskId, String newStatus) async {
    try {
      await _firestore.collection(_collection).doc(taskId).update({
        'status': newStatus,
      });
      return true;
    } catch (e) {
      throw Exception('Failed to update task status: $e');
    }
  }

  // Update Task
  Future<bool> updateTask(TaskModel task) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(task.id)
          .update(task.toJson());
      return true;
    } catch (e) {
      throw Exception('Failed to update task: $e');
    }
  }

  // Delete Task
  Future<bool> deleteTask(String taskId) async {
    try {
      await _firestore.collection(_collection).doc(taskId).delete();
      return true;
    } catch (e) {
      throw Exception('Failed to delete task: $e');
    }
  }

  // Get Tasks by Status (only for single tasks)
  Future<List<TaskModel>> getTasksByStatus(String eventId, String status) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('eventId', isEqualTo: eventId)
          .where('isRecurring', isEqualTo: false)
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => TaskModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch tasks by status: $e');
    }
  }

  // Get Overdue Tasks (only for single tasks)
  Future<List<TaskModel>> getOverdueTasks(String eventId) async {
    try {
      final now = Timestamp.now();
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('eventId', isEqualTo: eventId)
          .where('isRecurring', isEqualTo: false)
          .where('deadline', isLessThan: now)
          .where('status', whereIn: ['pending', 'in_progress'])
          .get();

      return querySnapshot.docs
          .map((doc) => TaskModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch overdue tasks: $e');
    }
  }

  // Get Recurring Tasks Not Completed Today
  Future<List<TaskModel>> getRecurringTasksNotCompletedToday(String userId) async {
    try {
      final today = TaskModel.getTodayDateString();
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('assignedToUsers', arrayContains: userId)
          .where('isRecurring', isEqualTo: true)
          .get();

      final tasks = querySnapshot.docs
          .map((doc) => TaskModel.fromFirestore(doc))
          .where((task) => !task.isCompletedToday(userId))
          .toList();

      return tasks;
    } catch (e) {
      throw Exception('Failed to fetch pending recurring tasks: $e');
    }
  }

  // Get User's Completion History for Recurring Task
  Future<List<String>> getUserCompletionHistory(String taskId, String userId) async {
    try {
      final task = await getTaskById(taskId);
      if (task == null || !task.isRecurring) return [];
      
      return task.getCompletionDatesForUser(userId);
    } catch (e) {
      throw Exception('Failed to fetch completion history: $e');
    }
  }

  // Stream Methods for Real-time Updates
  Stream<List<TaskModel>> getTasksStream(String eventId) {
    return _firestore
        .collection(_collection)
        .where('eventId', isEqualTo: eventId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TaskModel.fromFirestore(doc))
            .toList());
  }

  Stream<List<TaskModel>> getSingleTasksStream(String eventId) {
    return _firestore
        .collection(_collection)
        .where('eventId', isEqualTo: eventId)
        .where('isRecurring', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TaskModel.fromFirestore(doc))
            .toList());
  }

  Stream<List<TaskModel>> getRecurringTasksStream(String eventId) {
    return _firestore
        .collection(_collection)
        .where('eventId', isEqualTo: eventId)
        .where('isRecurring', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TaskModel.fromFirestore(doc))
            .toList());
  }

  Stream<List<TaskModel>> getUserTasksStream(String userId) {
    return _firestore
        .collection(_collection)
        .where('assignedToUsers', arrayContains: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TaskModel.fromFirestore(doc))
            .toList());
  }

  Stream<List<TaskModel>> getUserSingleTasksStream(String userId) {
    return _firestore
        .collection(_collection)
        .where('assignedToUsers', arrayContains: userId)
        .where('isRecurring', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TaskModel.fromFirestore(doc))
            .toList());
  }

  Stream<List<TaskModel>> getUserRecurringTasksStream(String userId) {
    return _firestore
        .collection(_collection)
        .where('assignedToUsers', arrayContains: userId)
        .where('isRecurring', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TaskModel.fromFirestore(doc))
            .toList());
  }

  Stream<TaskModel?> getTaskStream(String taskId) {
    return _firestore
        .collection(_collection)
        .doc(taskId)
        .snapshots()
        .map((doc) => doc.exists ? TaskModel.fromFirestore(doc) : null);
  }

  // Assign Users to Task
  Future<bool> assignUsersToTask(String taskId, List<String> userIds) async {
    try {
      await _firestore.collection(_collection).doc(taskId).update({
        'assignedToUsers': FieldValue.arrayUnion(userIds),
      });
      return true;
    } catch (e) {
      throw Exception('Failed to assign users to task: $e');
    }
  }

  // Remove Users from Task
  Future<bool> removeUsersFromTask(String taskId, List<String> userIds) async {
    try {
      await _firestore.collection(_collection).doc(taskId).update({
        'assignedToUsers': FieldValue.arrayRemove(userIds),
      });
      return true;
    } catch (e) {
      throw Exception('Failed to remove users from task: $e');
    }
  }

  // Search Tasks
  Future<List<TaskModel>> searchTasks(String eventId, String searchTerm) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('eventId', isEqualTo: eventId)
          .orderBy('title')
          .startAt([searchTerm])
          .endAt(['$searchTerm\uf8ff'])
          .get();

      return querySnapshot.docs
          .map((doc) => TaskModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to search tasks: $e');
    }
  }

  // Search Single Tasks
  Future<List<TaskModel>> searchSingleTasks(String eventId, String searchTerm) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('eventId', isEqualTo: eventId)
          .where('isRecurring', isEqualTo: false)
          .orderBy('title')
          .startAt([searchTerm])
          .endAt(['$searchTerm\uf8ff'])
          .get();

      return querySnapshot.docs
          .map((doc) => TaskModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to search single tasks: $e');
    }
  }

  // Search Recurring Tasks
  Future<List<TaskModel>> searchRecurringTasks(String eventId, String searchTerm) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('eventId', isEqualTo: eventId)
          .where('isRecurring', isEqualTo: true)
          .orderBy('title')
          .startAt([searchTerm])
          .endAt(['$searchTerm\uf8ff'])
          .get();

      return querySnapshot.docs
          .map((doc) => TaskModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to search recurring tasks: $e');
    }
  }
}