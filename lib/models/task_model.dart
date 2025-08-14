// File: models/task_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum RecurrenceType {
  none,
  daily,
  weekly,
  monthly,
  yearly,
}

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

class DailyCompletion {
  final String date; // Format: 'yyyy-MM-dd'
  final List<CompletionDetails> completedBy;

  DailyCompletion({
    required this.date,
    required this.completedBy,
  });

  factory DailyCompletion.fromMap(Map<String, dynamic> map) {
    return DailyCompletion(
      date: map['date'] ?? '',
      completedBy: (map['completedBy'] as List? ?? [])
          .map((item) => CompletionDetails.fromMap(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'completedBy': completedBy.map((completion) => completion.toMap()).toList(),
    };
  }

  factory DailyCompletion.fromJson(Map<String, dynamic> json) {
    return DailyCompletion(
      date: json['date'] ?? '',
      completedBy: (json['completedBy'] as List? ?? [])
          .map((item) => CompletionDetails.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'completedBy': completedBy.map((completion) => completion.toJson()).toList(),
    };
  }

  bool isCompletedByUser(String userId) {
    return completedBy.any((completion) => completion.userId == userId);
  }

  DateTime? getCompletionTimeByUser(String userId) {
    final completion = completedBy.where((c) => c.userId == userId).firstOrNull;
    return completion?.completedAt;
  }
}

class TaskModel {
  final String id;
  final String eventId;
  final String title;
  final String description;
  final List<String> assignedToUsers;
  final List<String> assignedToGroups;
  final DateTime? deadline; // Nullable for recurring tasks
  final String status; // 'pending', 'in_progress', 'completed'
  final String priority; // 'low', 'medium', 'high'
  final List<CompletionDetails> completedBy; // For single tasks
  final String createdBy;
  final DateTime createdAt;
  
  // Recurring task fields
  final RecurrenceType recurrenceType;
  final bool isRecurring; // True for recurring tasks
  final List<DailyCompletion> dailyCompletions; // For recurring tasks

  TaskModel({
    required this.id,
    required this.eventId,
    required this.title,
    required this.description,
    required this.assignedToUsers,
    required this.assignedToGroups,
    this.deadline,
    required this.status,
    required this.priority,
    required this.completedBy,
    required this.createdBy,
    required this.createdAt,
    this.recurrenceType = RecurrenceType.none,
    this.isRecurring = false,
    this.dailyCompletions = const [],
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

    List<DailyCompletion> dailyCompletionsList = [];
    if (data['dailyCompletions'] != null) {
      dailyCompletionsList = (data['dailyCompletions'] as List)
          .map((item) => DailyCompletion.fromMap(item as Map<String, dynamic>))
          .toList();
    }

    return TaskModel(
      id: doc.id,
      eventId: data['eventId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      assignedToUsers: List<String>.from(data['assignedToUsers'] ?? []),
      assignedToGroups: List<String>.from(data['assignedToGroups'] ?? []),
      deadline: data['deadline'] != null ? (data['deadline'] as Timestamp).toDate() : null,
      status: data['status'] ?? 'pending',
      priority: data['priority'] ?? 'medium',
      completedBy: completedByList,
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      recurrenceType: RecurrenceType.values.firstWhere(
        (e) => e.toString() == data['recurrenceType'],
        orElse: () => RecurrenceType.none,
      ),
      isRecurring: data['isRecurring'] ?? false,
      dailyCompletions: dailyCompletionsList,
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

    List<DailyCompletion> dailyCompletionsList = [];
    if (json['dailyCompletions'] != null) {
      dailyCompletionsList = (json['dailyCompletions'] as List)
          .map((item) => DailyCompletion.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return TaskModel(
      id: json['id'] ?? '',
      eventId: json['eventId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      assignedToUsers: List<String>.from(json['assignedToUsers'] ?? []),
      assignedToGroups: List<String>.from(json['assignedToGroups'] ?? []),
      deadline: json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
      status: json['status'] ?? 'pending',
      priority: json['priority'] ?? 'medium',
      completedBy: completedByList,
      createdBy: json['createdBy'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      recurrenceType: RecurrenceType.values.firstWhere(
        (e) => e.toString() == json['recurrenceType'],
        orElse: () => RecurrenceType.none,
      ),
      isRecurring: json['isRecurring'] ?? false,
      dailyCompletions: dailyCompletionsList,
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
      'deadline': deadline != null ? Timestamp.fromDate(deadline!) : null,
      'status': status,
      'priority': priority,
      'completedBy': completedBy.map((completion) => completion.toMap()).toList(),
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'recurrenceType': recurrenceType.toString(),
      'isRecurring': isRecurring,
      'dailyCompletions': dailyCompletions.map((completion) => completion.toMap()).toList(),
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
      'deadline': deadline?.toIso8601String(),
      'status': status,
      'priority': priority,
      'completedBy': completedBy.map((completion) => completion.toJson()).toList(),
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'recurrenceType': recurrenceType.toString(),
      'isRecurring': isRecurring,
      'dailyCompletions': dailyCompletions.map((completion) => completion.toJson()).toList(),
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
    RecurrenceType? recurrenceType,
    bool? isRecurring,
    List<DailyCompletion>? dailyCompletions,
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
      recurrenceType: recurrenceType ?? this.recurrenceType,
      isRecurring: isRecurring ?? this.isRecurring,
      dailyCompletions: dailyCompletions ?? this.dailyCompletions,
    );
  }

  // Helper methods - EXISTING METHODS (preserved for single tasks)
  bool isAssignedToUser(String userId) {
    return assignedToUsers.contains(userId);
  }

  bool isAssignedToGroup(String groupName) {
    return assignedToGroups.contains(groupName);
  }

  bool isCompletedByUser(String userId) {
    if (isRecurring) {
      return isCompletedToday(userId);
    }
    return completedBy.any((completion) => completion.userId == userId);
  }

  DateTime? getCompletionTimeByUser(String userId) {
    if (isRecurring) {
      return getCompletionTimeForDate(getTodayDateString(), userId);
    }
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
    if (isRecurring) return false; // Recurring tasks don't have overdue concept
    if (isCompleted) return false;
    if (deadline == null) return false;
    return DateTime.now().isAfter(deadline!);
  }

  bool get isDueSoon {
    if (isRecurring) return false; // Recurring tasks don't have due soon concept
    if (isCompleted) return false;
    if (deadline == null) return false;
    final now = DateTime.now();
    final difference = deadline!.difference(now);
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
  
  int get totalCompletions {
    if (isRecurring) {
      return getCompletionCountForDate(getTodayDateString());
    }
    return completedBy.length;
  }

  // Get completion percentage
  double get completionPercentage {
    if (totalAssignees == 0) return 0.0;
    return (totalCompletions / totalAssignees) * 100;
  }

  int get completedCount {
    if (isRecurring) {
      return getCompletionCountForDate(getTodayDateString());
    }
    return completedBy.length;
  }

  // NEW METHODS - For recurring tasks
  String get recurrenceDisplayName {
    switch (recurrenceType) {
      case RecurrenceType.daily:
        return 'Daily';
      case RecurrenceType.weekly:
        return 'Weekly';
      case RecurrenceType.monthly:
        return 'Monthly';
      case RecurrenceType.yearly:
        return 'Yearly';
      case RecurrenceType.none:
        return 'One-time';
    }
  }

  // Mark task as completed for a specific date and user (recurring tasks)
  TaskModel markCompletedForDate(String date, String userId) {
    if (!isRecurring) {
      // For single tasks, use existing completedBy
      if (!isCompletedByUser(userId)) {
        final updatedCompletedBy = List<CompletionDetails>.from(completedBy);
        updatedCompletedBy.add(CompletionDetails(
          userId: userId,
          completedAt: DateTime.now(),
        ));
        return copyWith(completedBy: updatedCompletedBy);
      }
      return this;
    }

    final existingCompletionIndex = dailyCompletions.indexWhere((dc) => dc.date == date);
    
    List<DailyCompletion> updatedCompletions = List.from(dailyCompletions);
    
    if (existingCompletionIndex >= 0) {
      // Date exists, add user completion if not already completed
      final existingCompletion = dailyCompletions[existingCompletionIndex];
      if (!existingCompletion.isCompletedByUser(userId)) {
        final updatedCompletedBy = List<CompletionDetails>.from(existingCompletion.completedBy);
        updatedCompletedBy.add(CompletionDetails(
          userId: userId,
          completedAt: DateTime.now(),
        ));
        
        updatedCompletions[existingCompletionIndex] = DailyCompletion(
          date: date,
          completedBy: updatedCompletedBy,
        );
      }
    } else {
      // New date, create new daily completion
      updatedCompletions.add(DailyCompletion(
        date: date,
        completedBy: [CompletionDetails(
          userId: userId,
          completedAt: DateTime.now(),
        )],
      ));
    }
    
    return copyWith(dailyCompletions: updatedCompletions);
  }

  // Check if task is completed for a specific date by user (recurring tasks)
  bool isCompletedForDate(String date, String userId) {
    if (!isRecurring) return isCompletedByUser(userId);
    
    final dailyCompletion = dailyCompletions.where((dc) => dc.date == date).firstOrNull;
    return dailyCompletion?.isCompletedByUser(userId) ?? false;
  }

  // Get completion time for a specific date and user (recurring tasks)
  DateTime? getCompletionTimeForDate(String date, String userId) {
    if (!isRecurring) return getCompletionTimeByUser(userId);
    
    final dailyCompletion = dailyCompletions.where((dc) => dc.date == date).firstOrNull;
    return dailyCompletion?.getCompletionTimeByUser(userId);
  }

  // Get all completion dates for a user (recurring tasks)
  List<String> getCompletionDatesForUser(String userId) {
    if (!isRecurring) {
      return isCompletedByUser(userId) ? [getTodayDateString()] : [];
    }
    
    return dailyCompletions
        .where((dc) => dc.isCompletedByUser(userId))
        .map((dc) => dc.date)
        .toList();
  }

  // Get today's date in yyyy-MM-dd format
  static String getTodayDateString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  // Check if completed today by user
  bool isCompletedToday(String userId) {
    return isCompletedForDate(getTodayDateString(), userId);
  }

  // Mark as completed for today
  TaskModel markCompletedToday(String userId) {
    return markCompletedForDate(getTodayDateString(), userId);
  }

  // Get completion stats for a specific date (recurring tasks)
  int getCompletionCountForDate(String date) {
    if (!isRecurring) return completedBy.length;
    
    final dailyCompletion = dailyCompletions.where((dc) => dc.date == date).firstOrNull;
    return dailyCompletion?.completedBy.length ?? 0;
  }

  // Get completion percentage for a specific date (recurring tasks)
  double getCompletionPercentageForDate(String date) {
    if (totalAssignees == 0) return 0.0;
    return (getCompletionCountForDate(date) / totalAssignees) * 100;
  }

  @override
  String toString() {
    return 'TaskModel(id: $id, title: $title, status: $status, deadline: $deadline, isRecurring: $isRecurring)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TaskModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}