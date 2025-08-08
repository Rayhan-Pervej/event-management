import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String? group; // Optional
  final List<String>? subGroups; // Optional
  final Timestamp? createdAt; // Optional

  const UserModel({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.group,
    this.subGroups,
    this.createdAt,
  });

  // Method to get full name
  String get fullName => '$firstName $lastName';

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'group': group,
      'subGroups': subGroups ?? [],
      'createdAt': createdAt ?? Timestamp.now(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      group: map['group'],
      subGroups: List<String>.from(map['subGroups'] ?? []),
      createdAt: map['createdAt'],
    );
  }
}