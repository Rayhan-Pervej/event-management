// File: providers/manage_team_provider.dart
import 'package:event_management/models/user.dart';
import 'package:event_management/repository/event_repository.dart';
import 'package:flutter/material.dart';
import 'package:event_management/models/event_model.dart';
import 'package:event_management/repository/user_repository.dart';

class ManageTeamProvider extends ChangeNotifier {
  final EventsRepository _eventsRepository = EventsRepository();
  final UserRepository _userRepository = UserRepository();

  // State variables
  EventModel? _event;
  List<UserModel> _searchResults = [];
  bool _isSearching = false;
  bool _isLoading = false;
  bool _membersWereAdded = false; // Track when members are successfully added

  String? _errorMessage;

  // Selected users and role - CHANGED TO LIST
  List<UserModel> _selectedUsers = [];
  String _selectedRole = 'member'; // 'member' or 'admin'

  // Search controller
  final TextEditingController searchController = TextEditingController();

  // Getters
  EventModel? get event => _event;
  List<UserModel> get searchResults => _searchResults;
  bool get isSearching => _isSearching;
  bool get isLoading => _isLoading;
  bool get membersWereAdded => _membersWereAdded;
  String? get errorMessage => _errorMessage;
  List<UserModel> get selectedUsers => _selectedUsers;
  bool get hasSelectedUsers => _selectedUsers.isNotEmpty;
  int get selectedUsersCount => _selectedUsers.length;
  String get selectedRole => _selectedRole;

  // Initialize with event
  void initialize(EventModel event) {
    _event = event;
    _membersWereAdded = false;
    searchController.clear(); // ✅ Clear search on initialization
    _searchResults.clear(); // ✅ Clear search results too
    _selectedUsers.clear(); // ✅ Clear any previous selections
  }

  // Reset the members added flag
  void resetMembersAddedFlag() {
    _membersWereAdded = false;
  }

  // Search users from Firestore
  Future<void> searchUsers(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _setSearching(true);
    _clearError();

    try {
      final users = await _userRepository.searchUsers(query);

      // Filter out users who are already members of this event
      _searchResults = users.where((user) {
        return _event != null && !_event!.isUserParticipant(user.uid);
      }).toList();
    } catch (e) {
      _setError('Search failed: ${e.toString()}');
      _searchResults = [];
    } finally {
      _setSearching(false);
    }
  }

  // Toggle user selection (for checkboxes)
  void toggleUserSelection(UserModel user) {
    if (isUserSelected(user.uid)) {
      _selectedUsers.removeWhere((u) => u.uid == user.uid);
    } else {
      _selectedUsers.add(user);
    }
    notifyListeners();
  }

  // Check if user is selected
  bool isUserSelected(String userId) {
    return _selectedUsers.any((u) => u.uid == userId);
  }

  // Clear all selected users
  void clearSelectedUsers() {
    _selectedUsers.clear();
    notifyListeners();
  }

  // Set selected role
  void setSelectedRole(String role) {
    _selectedRole = role;
    notifyListeners();
  }

  // Add all selected members to event
  Future<bool> addSelectedMembers() async {
    if (_event == null || _selectedUsers.isEmpty) return false;

    _setLoading(true);
    _clearError();

    try {
      EventModel updatedEvent = _event!;

      // Add each selected user to the event
      for (final user in _selectedUsers) {
        final participant = EventParticipant(
          id: user.uid,
          firstName: user.firstName,
          lastName: user.lastName,
        );

        if (_selectedRole == 'admin') {
          updatedEvent = updatedEvent.addAdmin(participant);
        } else {
          updatedEvent = updatedEvent.addMember(participant);
        }
      }

      // Update in Firestore
      await _eventsRepository.updateEvent(updatedEvent);

      // Update local state
      _event = updatedEvent;

      // Mark that members were successfully added
      _membersWereAdded = true;

      // Remove selected users from search results and clear selection
      final selectedUserIds = _selectedUsers.map((u) => u.uid).toSet();
      _searchResults.removeWhere((user) => selectedUserIds.contains(user.uid));
      _selectedUsers.clear();
      searchController.clear();
      _setLoading(false);

      // Use post frame callback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });

      return true;
    } catch (e) {
      _setLoading(false);
      _setError('Failed to add members: ${e.toString()}');
      return false;
    }
  }

  // Get the updated event (useful for syncing with other providers)
  EventModel? getUpdatedEvent() {
    return _event;
  }

  // Update event from external source (e.g., when refreshed from EventDetailsProvider)
  void updateEvent(EventModel updatedEvent) {
    _event = updatedEvent;

    // Update search results to filter out new members
    if (_searchResults.isNotEmpty) {
      _searchResults = _searchResults.where((user) {
        return !updatedEvent.isUserParticipant(user.uid);
      }).toList();
    }

    // Use post frame callback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // Clear search
  void clearSearch() {
    searchController.clear();
    _searchResults = [];
    notifyListeners();
  }

  // Check if there are any changes that need to be saved
  bool get hasUnsavedChanges => _selectedUsers.isNotEmpty;

  // Private methods
  void _setSearching(bool searching) {
    _isSearching = searching;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

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

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
