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

  // Complete Task
  Future<bool> completeTask(String taskId, String userId) async {
    try {
      final taskDoc = await _firestore.collection(_collection).doc(taskId).get();
      if (!taskDoc.exists) return false;

      final task = TaskModel.fromFirestore(taskDoc);
      
      // Check if user is assigned to this task
      if (!task.isAssignedToUser(userId)) {
        throw Exception('User is not assigned to this task');
      }

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

      await _firestore.collection(_collection).doc(taskId).update({
        'completedBy': updatedCompletedBy.map((c) => c.toMap()).toList(),
        'status': newStatus,
      });

      return true;
    } catch (e) {
      throw Exception('Failed to complete task: $e');
    }
  }

  Future<bool> uncompleteTask(String taskId, String userId) async {
  try {
    final taskDoc = await _firestore.collection(_collection).doc(taskId).get();
    if (!taskDoc.exists) return false;

    final task = TaskModel.fromFirestore(taskDoc);
    
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

    await _firestore.collection(_collection).doc(taskId).update({
      'completedBy': updatedCompletedBy.map((c) => c.toMap()).toList(),
      'status': newStatus,
    });

    return true;
  } catch (e) {
    throw Exception('Failed to uncomplete task: $e');
  }
}

  // Update Task Status
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

  // Get Tasks by Status
  Future<List<TaskModel>> getTasksByStatus(String eventId, String status) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('eventId', isEqualTo: eventId)
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

  // Get Overdue Tasks
  Future<List<TaskModel>> getOverdueTasks(String eventId) async {
    try {
      final now = Timestamp.now();
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('eventId', isEqualTo: eventId)
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
}