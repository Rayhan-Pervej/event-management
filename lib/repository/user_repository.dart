// File: repository/user_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_management/models/user.dart';


class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'users'; // Adjust collection name as needed

  // Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(userId).get();
      
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      
      return null;
    }
  }

  // Get multiple users by IDs
  Future<List<UserModel>> getUsersByIds(List<String> userIds) async {
    if (userIds.isEmpty) return [];
    
    try {
      final List<UserModel> users = [];
      
      // Firestore 'in' query limit is 10, so we need to batch requests
      for (int i = 0; i < userIds.length; i += 10) {
        final batch = userIds.skip(i).take(10).toList();
        final querySnapshot = await _firestore
            .collection(_collection)
            .where('uid', whereIn: batch)
            .get();
        
        for (final doc in querySnapshot.docs) {
          if (doc.exists) {
            users.add(UserModel.fromMap(doc.data()));
          }
        }
      }
      
      return users;
    } catch (e) {
      
      return [];
    }
  }

  // Create user
  Future<bool> createUser(UserModel user) async {
    try {
      await _firestore.collection(_collection).doc(user.uid).set(user.toMap());
      return true;
    } catch (e) {
      
      return false;
    }
  }

  // Update user
  Future<bool> updateUser(UserModel user) async {
    try {
      await _firestore.collection(_collection).doc(user.uid).update(user.toMap());
      return true;
    } catch (e) {
      
      return false;
    }
  }

  // Delete user
  Future<bool> deleteUser(String userId) async {
    try {
      await _firestore.collection(_collection).doc(userId).delete();
      return true;
    } catch (e) {
      
      return false;
    }
  }

  // Get all users (for admin purposes)
  Future<List<UserModel>> getAllUsers() async {
    try {
      final querySnapshot = await _firestore.collection(_collection).get();
      return querySnapshot.docs
          .map((doc) => UserModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      
      return [];
    }
  }

  // Search users by name or email
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('email', isGreaterThanOrEqualTo: query)
          .where('email', isLessThanOrEqualTo: '$query\uf8ff')
          .get();
      
      return querySnapshot.docs
          .map((doc) => UserModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      
      return [];
    }
  }
}