// File: repository/events_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_management/models/event_model.dart';

class EventsRepository {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'events';

  // Create Event
  Future<String> createEvent(EventModel event) async {
    try {
      // Generate document reference first
      final docRef = _firestore.collection(_collection).doc();

      // Create event with the generated ID
      final eventWithId = event.copyWith(id: docRef.id);

      // Set the document with the ID included
      await docRef.set(eventWithId.toJson());

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create event: $e');
    }
  }

  // Get All Events
  Future<List<EventModel>> getAllEvents() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => EventModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch events: $e');
    }
  }

  // Get User Events (where user is admin or member) - FIXED
  Future<List<EventModel>> getUserEvents(String userId) async {
    try {
      final allEventsQuery = await _firestore.collection(_collection).get();

      final List<EventModel> userEvents = [];

      for (var doc in allEventsQuery.docs) {
        try {
          final event = EventModel.fromFirestore(doc);

          // Check if user is admin or member using the helper methods
          if (event.isUserAdmin(userId) || event.isUserMember(userId)) {
            userEvents.add(event);
          }
        } catch (e) {
          print('Error parsing event ${doc.id}: $e');
          // Continue with other events even if one fails
        }
      }

      // Sort by creation date
      userEvents.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return userEvents;
    } catch (e) {
      throw Exception('Failed to fetch user events: $e');
    }
  }

  // Get Events by Status - FIXED
  Future<List<EventModel>> getEventsByStatus(
    String status, {
    String? userId,
  }) async {
    try {
      // Get all events first
      final querySnapshot = await _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .get();

      List<EventModel> allEvents = querySnapshot.docs
          .map((doc) => EventModel.fromFirestore(doc))
          .toList();

      // Filter by user if userId provided
      if (userId != null) {
        allEvents = allEvents
            .where(
              (event) =>
                  event.isUserAdmin(userId) || event.isUserMember(userId),
            )
            .toList();
      }

      // Filter by status
      switch (status.toLowerCase()) {
        case 'upcoming':
          return allEvents.where((event) => event.isUpcoming).toList();
        case 'ongoing':
          return allEvents.where((event) => event.isOngoing).toList();
        case 'completed':
          return allEvents.where((event) => event.isCompleted).toList();
        default:
          return allEvents;
      }
    } catch (e) {
      throw Exception('Failed to fetch events by status: $e');
    }
  }

  // Get Event by ID
  Future<EventModel?> getEventById(String eventId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(eventId).get();

      if (doc.exists) {
        return EventModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch event: $e');
    }
  }

  // Update Event
  Future<void> updateEvent(EventModel event) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(event.id)
          .update(event.toJson());
    } catch (e) {
      throw Exception('Failed to update event: $e');
    }
  }

  // Delete Event
  Future<void> deleteEvent(String eventId) async {
    try {
      await _firestore.collection(_collection).doc(eventId).delete();
    } catch (e) {
      throw Exception('Failed to delete event: $e');
    }
  }

  // Add User to Event (as admin or member) - FIXED for object arrays
  Future<void> addUserToEvent(
    String eventId,
    EventParticipant participant, {
    bool isAdmin = false,
  }) async {
    try {
      final field = isAdmin ? 'admins' : 'members';
      await _firestore.collection(_collection).doc(eventId).update({
        field: FieldValue.arrayUnion([participant.toMap()]),
      });
    } catch (e) {
      throw Exception('Failed to add user to event: $e');
    }
  }

  // Remove User from Event - FIXED for object arrays
  Future<void> removeUserFromEvent(String eventId, String userId) async {
    try {
      // Get the current event to find the exact participant objects
      final event = await getEventById(eventId);
      if (event == null) throw Exception('Event not found');

      final List<Map<String, dynamic>> updatedAdmins = [];
      final List<Map<String, dynamic>> updatedMembers = [];

      // Remove user from admins
      for (var admin in event.admins) {
        if (admin.id != userId) {
          updatedAdmins.add(admin.toMap());
        }
      }

      // Remove user from members
      for (var member in event.members) {
        if (member.id != userId) {
          updatedMembers.add(member.toMap());
        }
      }

      await _firestore.collection(_collection).doc(eventId).update({
        'admins': updatedAdmins,
        'members': updatedMembers,
      });
    } catch (e) {
      throw Exception('Failed to remove user from event: $e');
    }
  }

  // Promote Member to Admin
  Future<void> promoteMemberToAdmin(String eventId, String userId) async {
    try {
      final event = await getEventById(eventId);
      if (event == null) throw Exception('Event not found');

      final member = event.getMemberById(userId);
      if (member == null) throw Exception('User is not a member of this event');

      // Remove from members and add to admins
      final updatedMembers = event.members
          .where((m) => m.id != userId)
          .map((m) => m.toMap())
          .toList();
      final updatedAdmins = [
        ...event.admins.map((a) => a.toMap()),
        member.toMap(),
      ];

      await _firestore.collection(_collection).doc(eventId).update({
        'admins': updatedAdmins,
        'members': updatedMembers,
      });
    } catch (e) {
      throw Exception('Failed to promote member to admin: $e');
    }
  }

  // Demote Admin to Member
  // In EventsRepository
  Future<void> demoteAdminToMember(String eventId, String adminId) async {
    try {
      final eventDoc = await _firestore.collection('events').doc(eventId).get();
      if (!eventDoc.exists) throw Exception('Event not found');

      final eventData = eventDoc.data()!;
      final members = List<Map<String, dynamic>>.from(
        eventData['members'] ?? [],
      );
      final admins = List<Map<String, dynamic>>.from(eventData['admins'] ?? []);

      // Find and remove from admins
      final adminIndex = admins.indexWhere((a) => a['id'] == adminId);
      if (adminIndex == -1) throw Exception('Admin not found');

      final adminData = admins.removeAt(adminIndex);

      // Add to members
      members.add(adminData);

      // Update Firestore
      await _firestore.collection('events').doc(eventId).update({
        'members': members,
        'admins': admins,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to demote admin: $e');
    }
  }

  // Stream Methods for Real-time Updates - FIXED
  Stream<List<EventModel>> getEventsStream() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => EventModel.fromFirestore(doc))
              .toList(),
        );
  }

  // User Events Stream - FIXED (Note: This will get all events and filter in client)
  Stream<List<EventModel>> getUserEventsStream(String userId) {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          final allEvents = snapshot.docs
              .map((doc) => EventModel.fromFirestore(doc))
              .toList();

          // Filter events where user is admin or member
          return allEvents
              .where(
                (event) =>
                    event.isUserAdmin(userId) || event.isUserMember(userId),
              )
              .toList();
        });
  }

  Stream<EventModel?> getEventStream(String eventId) {
    return _firestore
        .collection(_collection)
        .doc(eventId)
        .snapshots()
        .map((doc) => doc.exists ? EventModel.fromFirestore(doc) : null);
  }

  // Search Events
  Future<List<EventModel>> searchEvents(String searchTerm) async {
    try {
      // Note: This is a basic search. For production, consider using
      // Algolia or Elasticsearch for better search capabilities
      final querySnapshot = await _firestore
          .collection(_collection)
          .orderBy('title')
          .startAt([searchTerm])
          .endAt(['$searchTerm\uf8ff'])
          .get();

      return querySnapshot.docs
          .map((doc) => EventModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to search events: $e');
    }
  }

  // Search Events by Title and Description
  Future<List<EventModel>> searchEventsByText(String searchTerm) async {
    try {
      final querySnapshot = await _firestore.collection(_collection).get();

      final allEvents = querySnapshot.docs
          .map((doc) => EventModel.fromFirestore(doc))
          .toList();

      // Filter events that contain the search term in title or description
      final searchLower = searchTerm.toLowerCase();
      return allEvents
          .where(
            (event) =>
                event.title.toLowerCase().contains(searchLower) ||
                event.description.toLowerCase().contains(searchLower) ||
                event.location.toLowerCase().contains(searchLower),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to search events: $e');
    }
  }
}
