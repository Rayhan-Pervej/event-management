import 'package:cloud_firestore/cloud_firestore.dart';

// Sub-model for admin and member objects
class EventParticipant {
  final String id;
  final String firstName;
  final String lastName;

  EventParticipant({
    required this.id,
    required this.firstName,
    required this.lastName,
  });

  // Factory constructor from Map
  factory EventParticipant.fromMap(Map<String, dynamic> map) {
    return EventParticipant(
      id: map['id'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
    );
  }

  // Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
    };
  }

  // Get full name
  String get fullName => '$firstName $lastName';

  // CopyWith method
  EventParticipant copyWith({
    String? id,
    String? firstName,
    String? lastName,
  }) {
    return EventParticipant(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
    );
  }

  @override
  String toString() {
    return 'EventParticipant(id: $id, name: $fullName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventParticipant && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class EventModel {
  final String id;
  final String title;
  final String description;
  final String location;
  final DateTime startDate;
  final DateTime endDate;
  final List<EventParticipant> admins; // List of admin participants
  final List<EventParticipant> members; // List of member participants
  final String createdBy;
  final DateTime createdAt;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.startDate,
    required this.endDate,
    required this.admins,
    required this.members,
    required this.createdBy,
    required this.createdAt,
  });

  // Factory constructor to create EventModel from Firestore document
  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return EventModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      location: data['location'] ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      admins: (data['admins'] as List?)?.map((e) => EventParticipant.fromMap(e as Map<String, dynamic>)).toList() ?? [],
      members: (data['members'] as List?)?.map((e) => EventParticipant.fromMap(e as Map<String, dynamic>)).toList() ?? [],
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  // Factory constructor from JSON/Map
  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      admins: (json['admins'] as List?)?.map((e) => EventParticipant.fromMap(e as Map<String, dynamic>)).toList() ?? [],
      members: (json['members'] as List?)?.map((e) => EventParticipant.fromMap(e as Map<String, dynamic>)).toList() ?? [],
      createdBy: json['createdBy'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  // Convert to JSON/Map for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'location': location,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'admins': admins.map((admin) => admin.toMap()).toList(),
      'members': members.map((member) => member.toMap()).toList(),
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Convert to Map for JSON serialization (without Timestamp)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'location': location,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'admins': admins.map((admin) => admin.toMap()).toList(),
      'members': members.map((member) => member.toMap()).toList(),
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // CopyWith method for updating specific fields
  EventModel copyWith({
    String? id,
    String? title,
    String? description,
    String? location,
    DateTime? startDate,
    DateTime? endDate,
    List<EventParticipant>? admins,
    List<EventParticipant>? members,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      admins: admins ?? this.admins,
      members: members ?? this.members,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Helper methods - updated to work with EventParticipant objects
  bool isUserAdmin(String userId) {
    return admins.any((admin) => admin.id == userId);
  }

  bool isUserMember(String userId) {
    return members.any((member) => member.id == userId);
  }

  bool isUserParticipant(String userId) {
    return isUserAdmin(userId) || isUserMember(userId);
  }

  int get totalParticipants => admins.length + members.length;

  bool get isOngoing {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  bool get isUpcoming {
    final now = DateTime.now();
    return now.isBefore(startDate);
  }

  bool get isCompleted {
    final now = DateTime.now();
    return now.isAfter(endDate);
  }

  String get status {
    if (isUpcoming) return 'Upcoming';
    if (isOngoing) return 'Ongoing';
    return 'Completed';
  }

  // Helper methods to get user details
  EventParticipant? getAdminById(String userId) {
    try {
      return admins.firstWhere((admin) => admin.id == userId);
    } catch (e) {
      return null;
    }
  }

  EventParticipant? getMemberById(String userId) {
    try {
      return members.firstWhere((member) => member.id == userId);
    } catch (e) {
      return null;
    }
  }

  // Helper methods to add/remove users
  EventModel addAdmin(EventParticipant adminData) {
    if (!isUserAdmin(adminData.id)) {
      return copyWith(admins: [...admins, adminData]);
    }
    return this;
  }

  EventModel removeAdmin(String userId) {
    return copyWith(admins: admins.where((admin) => admin.id != userId).toList());
  }

  EventModel addMember(EventParticipant memberData) {
    if (!isUserMember(memberData.id)) {
      return copyWith(members: [...members, memberData]);
    }
    return this;
  }

  EventModel removeMember(String userId) {
    return copyWith(members: members.where((member) => member.id != userId).toList());
  }

  @override
  String toString() {
    return 'EventModel(id: $id, title: $title, status: $status, participants: $totalParticipants)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}