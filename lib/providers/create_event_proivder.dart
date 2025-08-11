// File: providers/create_event_provider.dart
import 'package:event_management/models/event_model.dart';
import 'package:event_management/repository/event_repository.dart';
import 'package:event_management/service/notification_manager.dart';
import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:event_management/models/event_model.dart';
// import 'package:event_management/services/firestore_service.dart';

class CreateEventProvider extends ChangeNotifier {
  final EventsRepository _eventsRepository = EventsRepository();
  // Form controllers
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController locationController = TextEditingController();

  // Date and time variables
  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  // State variables
  bool _isLoading = false;
  String? _errorMessage;

  // Admin and member lists - changed to EventParticipant lists
  final List<EventParticipant> _admins = [];
  final List<EventParticipant> _members = [];

  // Getters
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  TimeOfDay? get startTime => _startTime;
  TimeOfDay? get endTime => _endTime;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<EventParticipant> get admins => List.from(_admins);
  List<EventParticipant> get members => List.from(_members);

  // Computed getters
  bool get isFormValid {
    return titleController.text.trim().isNotEmpty &&
        descriptionController.text.trim().isNotEmpty &&
        locationController.text.trim().isNotEmpty &&
        _startDate != null &&
        _endDate != null &&
        _startTime != null &&
        _endTime != null &&
        _isValidDateRange;
  }

  bool get _isValidDateRange {
    if (_startDate == null || _endDate == null) return false;
    if (_startTime == null || _endTime == null) return false;

    final startDateTime = DateTime(
      _startDate!.year,
      _startDate!.month,
      _startDate!.day,
      _startTime!.hour,
      _startTime!.minute,
    );

    final endDateTime = DateTime(
      _endDate!.year,
      _endDate!.month,
      _endDate!.day,
      _endTime!.hour,
      _endTime!.minute,
    );

    return endDateTime.isAfter(startDateTime);
  }

  // Date setters
  void setStartDate(DateTime date) {
    _startDate = date;
    _clearError();
    notifyListeners();
  }

  void setEndDate(DateTime date) {
    _endDate = date;
    _clearError();
    notifyListeners();
  }

  void setStartTime(TimeOfDay time) {
    _startTime = time;
    _clearError();
    notifyListeners();
  }

  void setEndTime(TimeOfDay time) {
    _endTime = time;
    _clearError();
    notifyListeners();
  }

  // Admin management methods
  void addAdmin(EventParticipant adminData) {
    // Check if admin already exists
    if (!_admins.any((admin) => admin.id == adminData.id)) {
      _admins.add(adminData);
      // Remove from members if they were a member
      _members.removeWhere((member) => member.id == adminData.id);
      _clearError();
      notifyListeners();
    }
  }

  void removeAdmin(String userId) {
    _admins.removeWhere((admin) => admin.id == userId);
    _clearError();
    notifyListeners();
  }

  void updateAdmin(String userId, EventParticipant updatedData) {
    final index = _admins.indexWhere((admin) => admin.id == userId);
    if (index != -1) {
      _admins[index] = updatedData;
      _clearError();
      notifyListeners();
    }
  }

  // Member management methods
  void addMember(EventParticipant memberData) {
    // Check if member already exists and is not an admin
    if (!_members.any((member) => member.id == memberData.id) &&
        !_admins.any((admin) => admin.id == memberData.id)) {
      _members.add(memberData);
      _clearError();
      notifyListeners();
    }
  }

  void removeMember(String userId) {
    _members.removeWhere((member) => member.id == userId);
    _clearError();
    notifyListeners();
  }

  void updateMember(String userId, EventParticipant updatedData) {
    final index = _members.indexWhere((member) => member.id == userId);
    if (index != -1) {
      _members[index] = updatedData;
      _clearError();
      notifyListeners();
    }
  }

  // Promote member to admin
  void promoteMemberToAdmin(String userId) {
    final memberIndex = _members.indexWhere((member) => member.id == userId);
    if (memberIndex != -1) {
      final memberData = _members[memberIndex];
      _members.removeAt(memberIndex);
      _admins.add(memberData);
      _clearError();
      notifyListeners();
    }
  }

  // Demote admin to member
  void demoteAdminToMember(String userId) {
    final adminIndex = _admins.indexWhere((admin) => admin.id == userId);
    if (adminIndex != -1) {
      final adminData = _admins[adminIndex];
      _admins.removeAt(adminIndex);
      _members.add(adminData);
      _clearError();
      notifyListeners();
    }
  }

  // Helper method to create EventParticipant from UserModel
  EventParticipant createEventParticipant({
    required String id,
    required String firstName,
    required String lastName,
  }) {
    return EventParticipant(id: id, firstName: firstName, lastName: lastName);
  }

  // Error handling
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  // Create event method - updated to work with EventParticipant objects
  Future<bool> createEvent(
    String currentUserId, {
    required String creatorFirstName,
    required String creatorLastName,
  }) async {
    if (!isFormValid) {
      _setError('Please fill all required fields');
      return false;
    }

    _isLoading = true;
    _clearError();
    notifyListeners();

    try {
      // Combine date and time
      final startDateTime = DateTime(
        _startDate!.year,
        _startDate!.month,
        _startDate!.day,
        _startTime!.hour,
        _startTime!.minute,
      );

      final endDateTime = DateTime(
        _endDate!.year,
        _endDate!.month,
        _endDate!.day,
        _endTime!.hour,
        _endTime!.minute,
      );

      // Ensure creator is in admins list with proper details
      List<EventParticipant> finalAdmins = List.from(_admins);
      if (!finalAdmins.any((admin) => admin.id == currentUserId)) {
        finalAdmins.add(
          EventParticipant(
            id: currentUserId,
            firstName: creatorFirstName,
            lastName: creatorLastName,
          ),
        );
      } else {
        // Update existing admin with correct details if they're already added
        final index = finalAdmins.indexWhere(
          (admin) => admin.id == currentUserId,
        );
        if (index != -1) {
          finalAdmins[index] = EventParticipant(
            id: currentUserId,
            firstName: creatorFirstName,
            lastName: creatorLastName,
          );
        }
      }

      // Create event model
      final event = EventModel(
        id: '', // Firestore will generate this
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
        location: locationController.text.trim(),
        startDate: startDateTime,
        endDate: endDateTime,
        admins: finalAdmins,
        members: _members,
        createdBy: currentUserId,
        createdAt: DateTime.now(),
      );

      // Save to Firestore
      await _eventsRepository.createEvent(event);
      await NotificationManager().refreshListeners();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _setError('Failed to create event: ${e.toString()}');
      return false;
    }
  }

  // Reset form - updated to clear object lists
  void resetForm() {
    titleController.clear();
    descriptionController.clear();
    locationController.clear();
    _startDate = null;
    _endDate = null;
    _startTime = null;
    _endTime = null;
    _errorMessage = null;
    _isLoading = false;
    _admins.clear();
    _members.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    locationController.dispose();
    super.dispose();
  }
}
