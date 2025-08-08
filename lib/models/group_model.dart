// File: models/group_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class GroupModel {
  final String id;
  final String eventId;
  final String name;
  final String? description;
  final List<String> members;
  final String createdBy;
  final DateTime createdAt;

  GroupModel({
    required this.id,
    required this.eventId,
    required this.name,
    this.description,
    required this.members,
    required this.createdBy,
    required this.createdAt,
  });

  // Factory constructor from Firestore
  factory GroupModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return GroupModel(
      id: doc.id,
      eventId: data['eventId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'],
      members: List<String>.from(data['members'] ?? []),
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  // Factory from JSON
  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['id'] ?? '',
      eventId: json['eventId'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      members: List<String>.from(json['members'] ?? []),
      createdBy: json['createdBy'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  // Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    final data = {
      'eventId': eventId,
      'name': name,
      'members': members,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };

    if (id.isNotEmpty) data['id'] = id;
    if (description != null) data['description'] = description ?? '';

    return data;
  }

  // Convert to Map for JSON serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'eventId': eventId,
      'name': name,
      'description': description,
      'members': members,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // CopyWith method
  GroupModel copyWith({
    String? id,
    String? eventId,
    String? name,
    String? description,
    List<String>? members,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return GroupModel(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      name: name ?? this.name,
      description: description ?? this.description,
      members: members ?? this.members,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Helper methods
  bool hasMember(String userId) {
    return members.contains(userId);
  }

  int get memberCount => members.length;

  bool get isEmpty => members.isEmpty;

  @override
  String toString() {
    return 'GroupModel(id: $id, name: $name, members: ${members.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GroupModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}