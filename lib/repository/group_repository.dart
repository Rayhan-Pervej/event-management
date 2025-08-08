// File: repository/groups_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_management/models/group_model.dart';
// import 'package:event_management/models/group_model.dart';

class GroupsRepository {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'groups';
  
  // Create Group
  Future<String> createGroup(GroupModel group) async {
    try {
      final docRef = _firestore.collection(_collection).doc();
      final groupWithId = group.copyWith(id: docRef.id);
      await docRef.set(groupWithId.toJson());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create group: $e');
    }
  }
  
  // Get Groups by Event
  Future<List<GroupModel>> getEventGroups(String eventId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('eventId', isEqualTo: eventId)
          .orderBy('createdAt', descending: false)
          .get();
      
      return querySnapshot.docs
          .map((doc) => GroupModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch event groups: $e');
    }
  }
  
  // Get Group by ID
  Future<GroupModel?> getGroupById(String groupId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(groupId).get();
      
      if (doc.exists) {
        return GroupModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch group: $e');
    }
  }
  
  // Update Group
  Future<void> updateGroup(GroupModel group) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(group.id)
          .update(group.toJson());
    } catch (e) {
      throw Exception('Failed to update group: $e');
    }
  }
  
  // Delete Group
  Future<void> deleteGroup(String groupId) async {
    try {
      await _firestore.collection(_collection).doc(groupId).delete();
    } catch (e) {
      throw Exception('Failed to delete group: $e');
    }
  }
  
  // Add Member to Group
  Future<void> addMemberToGroup(String groupId, String userId) async {
    try {
      await _firestore.collection(_collection).doc(groupId).update({
        'members': FieldValue.arrayUnion([userId])
      });
    } catch (e) {
      throw Exception('Failed to add member to group: $e');
    }
  }
  
  // Remove Member from Group
  Future<void> removeMemberFromGroup(String groupId, String userId) async {
    try {
      await _firestore.collection(_collection).doc(groupId).update({
        'members': FieldValue.arrayRemove([userId])
      });
    } catch (e) {
      throw Exception('Failed to remove member from group: $e');
    }
  }
  
  // Get User's Groups in Event
  Future<List<GroupModel>> getUserGroupsInEvent(String eventId, String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('eventId', isEqualTo: eventId)
          .where('members', arrayContains: userId)
          .get();
      
      return querySnapshot.docs
          .map((doc) => GroupModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch user groups: $e');
    }
  }
  
  // Stream Methods for Real-time Updates
  Stream<List<GroupModel>> getEventGroupsStream(String eventId) {
    return _firestore
        .collection(_collection)
        .where('eventId', isEqualTo: eventId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GroupModel.fromFirestore(doc))
            .toList());
  }
  
  Stream<GroupModel?> getGroupStream(String groupId) {
    return _firestore
        .collection(_collection)
        .doc(groupId)
        .snapshots()
        .map((doc) => doc.exists ? GroupModel.fromFirestore(doc) : null);
  }
}