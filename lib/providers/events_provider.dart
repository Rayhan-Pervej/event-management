// File: providers/events_provider.dart
import 'package:event_management/models/event_model.dart';
import 'package:event_management/repository/event_repository.dart';
import 'package:flutter/material.dart';

class EventsProvider extends ChangeNotifier {
  final EventsRepository _eventsRepository = EventsRepository();

  // State variables
  List<EventModel> _allEvents = [];
  List<EventModel> _filteredEvents = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _currentFilter = 'All';
  String? _currentUserId;

  // Getters
  List<EventModel> get events => _filteredEvents;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get currentFilter => _currentFilter;
  bool get hasEvents => _filteredEvents.isNotEmpty;
  int get totalEvents => _allEvents.length;

  // Initialize with user ID
  Future<void> initialize(String userId) async {
    _currentUserId = userId;
    await loadEvents();
  }

  // Load events for current user
  Future<void> loadEvents() async {
    if (_currentUserId == null) return;

    _setLoading(true);
    _clearError();

    try {
      // Load events where user is admin or member
      _allEvents = await _eventsRepository.getUserEvents(_currentUserId!);
      _applyCurrentFilter();
    } catch (e) {
      _setError('Failed to load events: ${e.toString()}');
      _allEvents = [];
      _filteredEvents = [];
    } finally {
      _setLoading(false);
    }
  }

  // Apply filter to events
  void applyFilter(String filter) {
    _currentFilter = filter;
    _applyCurrentFilter();
    notifyListeners();
  }

  // Private method to apply current filter
  void _applyCurrentFilter() {
    switch (_currentFilter.toLowerCase()) {
      case 'upcoming':
        _filteredEvents = _allEvents
            .where((event) => event.isUpcoming)
            .toList();
        break;
      case 'ongoing':
        _filteredEvents = _allEvents.where((event) => event.isOngoing).toList();
        break;
      case 'completed':
        _filteredEvents = _allEvents
            .where((event) => event.isCompleted)
            .toList();
        break;
      case 'all':
      default:
        _filteredEvents = List.from(_allEvents);
        break;
    }

    // Sort events by start date (newest first)
    _filteredEvents.sort((a, b) => b.startDate.compareTo(a.startDate));
  }

  // Refresh events
  Future<void> refreshEvents() async {
    await loadEvents();
  }

  Future<void> promoteToAdmin(String eventId, String memberId) async {
    try {
      await _eventsRepository.promoteMemberToAdmin(eventId, memberId);
      // Update local state after API call
      await _updateLocalEvent(eventId);
    } catch (e) {
      _setError('Failed to promote member: ${e.toString()}');
      rethrow;
    }
  }

  Future<void> removeFromEvent(String eventId, String memberId) async {
    try {
      await _eventsRepository.removeUserFromEvent(eventId, memberId);
      // Update local state after API call
      await _updateLocalEvent(eventId);
    } catch (e) {
      _setError('Failed to remove member: ${e.toString()}');
      rethrow;
    }
  }

  // Helper method to update a specific event from the server
  Future<void> _updateLocalEvent(String eventId) async {
    try {
      final updatedEvent = await _eventsRepository.getEventById(eventId);
      final index = _allEvents.indexWhere((event) => event.id == eventId);
      if (index != -1) {
        _allEvents[index] = updatedEvent!;
        _applyCurrentFilter();
        notifyListeners();
      }
    } catch (e) {
      // If we can't fetch the updated event, just refresh all events
      await loadEvents();
    }
  }

  // Force refresh a specific event
  Future<void> refreshEvent(String eventId) async {
    try {
      final updatedEvent = await _eventsRepository.getEventById(eventId);
      final index = _allEvents.indexWhere((event) => event.id == eventId);
      if (index != -1) {
        _allEvents[index] = updatedEvent!;
        _applyCurrentFilter();
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to refresh event: ${e.toString()}');
    }
  }

  // Add event (after creation)
  void addEvent(EventModel event) {
    _allEvents.insert(0, event);
    _applyCurrentFilter();
    notifyListeners();
  }

  // Update event in local state
  void updateEvent(EventModel updatedEvent) {
    final index = _allEvents.indexWhere((event) => event.id == updatedEvent.id);
    if (index != -1) {
      _allEvents[index] = updatedEvent;
      _applyCurrentFilter();
      // Use post frame callback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  // Update event silently (without notifyListeners)
  void updateEventSilently(EventModel updatedEvent) {
    final index = _allEvents.indexWhere((event) => event.id == updatedEvent.id);
    if (index != -1) {
      _allEvents[index] = updatedEvent;
      _applyCurrentFilter();
    }
  }

  // Remove event from local state
  void removeEvent(String eventId) {
    _allEvents.removeWhere((event) => event.id == eventId);
    _applyCurrentFilter();
    notifyListeners();
  }

  // Get event by ID
  EventModel? getEventById(String eventId) {
    try {
      return _allEvents.firstWhere((event) => event.id == eventId);
    } catch (e) {
      return null;
    }
  }

  // Check if current user is admin of any event
  bool get isUserAdmin {
    if (_currentUserId == null) return false;
    return _allEvents.any((event) => event.isUserAdmin(_currentUserId!));
  }

  // Get events count by status
  int getEventsCountByStatus(String status) {
    switch (status.toLowerCase()) {
      case 'upcoming':
        return _allEvents.where((event) => event.isUpcoming).length;
      case 'ongoing':
        return _allEvents.where((event) => event.isOngoing).length;
      case 'completed':
        return _allEvents.where((event) => event.isCompleted).length;
      default:
        return _allEvents.length;
    }
  }

  // Get user's admin events
  List<EventModel> get userAdminEvents {
    if (_currentUserId == null) return [];
    return _allEvents
        .where((event) => event.isUserAdmin(_currentUserId!))
        .toList();
  }

  // Get user's member events
  List<EventModel> get userMemberEvents {
    if (_currentUserId == null) return [];
    return _allEvents
        .where(
          (event) =>
              event.isUserMember(_currentUserId!) &&
              !event.isUserAdmin(_currentUserId!),
        )
        .toList();
  }

  // Private methods
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
}
