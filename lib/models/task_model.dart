// File: models/task_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class CompletionDetails {
  final String userId;
  final DateTime completedAt;

  CompletionDetails({required this.userId, required this.completedAt});

  factory CompletionDetails.fromMap(Map<String, dynamic> map) {
    return CompletionDetails(
      userId: map['userId'] ?? '',
      completedAt: (map['completedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {'userId': userId, 'completedAt': Timestamp.fromDate(completedAt)};
  }

  factory CompletionDetails.fromJson(Map<String, dynamic> json) {
    return CompletionDetails(
      userId: json['userId'] ?? '',
      completedAt: DateTime.parse(json['completedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'userId': userId, 'completedAt': completedAt.toIso8601String()};
  }
}

class TaskModel {
  final String id;
  final String eventId;
  final String title;
  final String description;
  final List<String> assignedToUsers;
  final List<String> assignedToGroups;
  final DateTime deadline;
  final String status; // 'pending', 'in_progress', 'completed'
  final String priority; // 'low', 'medium', 'high'
  final List<CompletionDetails>
  completedBy; // List of users who completed with timestamps
  final String createdBy;
  final DateTime createdAt;

  TaskModel({
    required this.id,
    required this.eventId,
    required this.title,
    required this.description,
    required this.assignedToUsers,
    required this.assignedToGroups,
    required this.deadline,
    required this.status,
    required this.priority,
    required this.completedBy,
    required this.createdBy,
    required this.createdAt,
  });

  // Factory constructor from Firestore
  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    List<CompletionDetails> completedByList = [];
    if (data['completedBy'] != null) {
      completedByList = (data['completedBy'] as List)
          .map(
            (item) => CompletionDetails.fromMap(item as Map<String, dynamic>),
          )
          .toList();
    }

    return TaskModel(
      id: doc.id,
      eventId: data['eventId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      assignedToUsers: List<String>.from(data['assignedToUsers'] ?? []),
      assignedToGroups: List<String>.from(data['assignedToGroups'] ?? []),
      deadline: (data['deadline'] as Timestamp).toDate(),
      status: data['status'] ?? 'pending',
      priority: data['priority'] ?? 'medium',
      completedBy: completedByList,
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  // Factory from JSON
  factory TaskModel.fromJson(Map<String, dynamic> json) {
    List<CompletionDetails> completedByList = [];
    if (json['completedBy'] != null) {
      completedByList = (json['completedBy'] as List)
          .map(
            (item) => CompletionDetails.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    }

    return TaskModel(
      id: json['id'] ?? '',
      eventId: json['eventId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      assignedToUsers: List<String>.from(json['assignedToUsers'] ?? []),
      assignedToGroups: List<String>.from(json['assignedToGroups'] ?? []),
      deadline: DateTime.parse(json['deadline']),
      status: json['status'] ?? 'pending',
      priority: json['priority'] ?? 'medium',
      completedBy: completedByList,
      createdBy: json['createdBy'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  // Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    final data = {
      'eventId': eventId,
      'title': title,
      'description': description,
      'assignedToUsers': assignedToUsers,
      'assignedToGroups': assignedToGroups,
      'deadline': Timestamp.fromDate(deadline),
      'status': status,
      'priority': priority,
      'completedBy': completedBy
          .map((completion) => completion.toMap())
          .toList(),
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };

    if (id.isNotEmpty) data['id'] = id;
    return data;
  }

  // Convert to Map for JSON serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'eventId': eventId,
      'title': title,
      'description': description,
      'assignedToUsers': assignedToUsers,
      'assignedToGroups': assignedToGroups,
      'deadline': deadline.toIso8601String(),
      'status': status,
      'priority': priority,
      'completedBy': completedBy
          .map((completion) => completion.toJson())
          .toList(),
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // CopyWith method
  TaskModel copyWith({
    String? id,
    String? eventId,
    String? title,
    String? description,
    List<String>? assignedToUsers,
    List<String>? assignedToGroups,
    DateTime? deadline,
    String? status,
    String? priority,
    List<CompletionDetails>? completedBy,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      title: title ?? this.title,
      description: description ?? this.description,
      assignedToUsers: assignedToUsers ?? this.assignedToUsers,
      assignedToGroups: assignedToGroups ?? this.assignedToGroups,
      deadline: deadline ?? this.deadline,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      completedBy: completedBy ?? this.completedBy,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Helper methods
  bool isAssignedToUser(String userId) {
    return assignedToUsers.contains(userId);
  }

  bool isAssignedToGroup(String groupName) {
    return assignedToGroups.contains(groupName);
  }

  bool isCompletedByUser(String userId) {
    return completedBy.any((completion) => completion.userId == userId);
  }

  DateTime? getCompletionTimeByUser(String userId) {
    final completion = completedBy.firstWhere(
      (completion) => completion.userId == userId,
      orElse: () => CompletionDetails(userId: '', completedAt: DateTime.now()),
    );
    return completion.userId.isNotEmpty ? completion.completedAt : null;
  }

  bool get isPending => status == 'pending';
  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';

  bool get isOverdue {
    if (isCompleted) return false;
    return DateTime.now().isAfter(deadline);
  }

  bool get isDueSoon {
    if (isCompleted) return false;
    final now = DateTime.now();
    final difference = deadline.difference(now);
    return difference.inHours <= 24 && difference.inHours > 0;
  }

  String get priorityDisplayName {
    switch (priority.toLowerCase()) {
      case 'high':
        return 'High Priority';
      case 'medium':
        return 'Medium Priority';
      case 'low':
        return 'Low Priority';
      default:
        return 'Medium Priority';
    }
  }

  String get statusDisplayName {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      default:
        return 'Pending';
    }
  }

  int get totalAssignees => assignedToUsers.length + assignedToGroups.length;
  int get totalCompletions => completedBy.length;

  // Get completion percentage
  double get completionPercentage {
    if (totalAssignees == 0) return 0.0;
    return (totalCompletions / totalAssignees) * 100;
  }

  @override
  String toString() {
    return 'TaskModel(id: $id, title: $title, status: $status, deadline: $deadline)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TaskModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  int get completedCount => completedBy.length;
}
