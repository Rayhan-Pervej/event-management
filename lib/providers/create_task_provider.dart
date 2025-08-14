// File: providers/create_task_provider.dart
import 'package:event_management/repository/event_repository.dart';
import 'package:event_management/service/notification_manager.dart';
import 'package:flutter/material.dart';
import 'package:event_management/models/task_model.dart';
import 'package:event_management/models/event_model.dart';
import 'package:event_management/repository/task_repository.dart';

class CreateTaskProvider extends ChangeNotifier {
  final TasksRepository _tasksRepository = TasksRepository();
  final EventsRepository _eventsRepository = EventsRepository();

  // Form controllers
  final TextEditingController taskNameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // State variables
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _selectedPriority = 'medium';
  final List<String> _selectedMembers = [];
  EventModel? _currentEvent;
  bool _isLoading = false;
  bool _isLoadingEvent = true;
  bool _isRecurring = false;
  RecurrenceType _selectedRecurrenceType = RecurrenceType.daily;

  // Getters
  DateTime? get selectedDate => _selectedDate;
  TimeOfDay? get selectedTime => _selectedTime;
  String get selectedPriority => _selectedPriority;
  List<String> get selectedMembers => _selectedMembers;
  EventModel? get currentEvent => _currentEvent;
  bool get isLoading => _isLoading;
  bool get isLoadingEvent => _isLoadingEvent;
  bool get isRecurring => _isRecurring;
  RecurrenceType get selectedRecurrenceType => _selectedRecurrenceType;
  final List<String> priorities = ['low', 'medium', 'high'];

  @override
  void dispose() {
    taskNameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> loadEventDetails(String eventId) async {
    _isLoadingEvent = true;
    notifyListeners();

    try {
      final event = await _eventsRepository.getEventById(eventId);

      _currentEvent = event;
      _isLoadingEvent = false;
      notifyListeners();
    } catch (e) {
      _isLoadingEvent = false;
      notifyListeners();
      rethrow;
    }
  }

  String getRecurrenceDisplayName(RecurrenceType type) {
    switch (type) {
      case RecurrenceType.daily:
        return 'Daily';
      case RecurrenceType.weekly:
        return 'Weekly';
      case RecurrenceType.monthly:
        return 'Monthly';
      case RecurrenceType.yearly:
        return 'Yearly';
      case RecurrenceType.none:
        return 'None';
    }
  }

  void setSelectedDate(DateTime? date) {
    _selectedDate = date;
    notifyListeners();
  }

  void setSelectedTime(TimeOfDay? time) {
    _selectedTime = time;
    notifyListeners();
  }

  void setSelectedPriority(String priority) {
    _selectedPriority = priority;
    notifyListeners();
  }

  void toggleMemberSelection(String memberId) {
    if (_selectedMembers.contains(memberId)) {
      _selectedMembers.remove(memberId);
    } else {
      _selectedMembers.add(memberId);
    }
    notifyListeners();
  }

  bool isMemberSelected(String memberId) {
    return _selectedMembers.contains(memberId);
  }

  List<String> getAllEventMembers() {
    if (_currentEvent == null) {
      return [];
    }

    final allMembers = <String>{};

    // Add admin IDs from EventParticipant objects
    final adminIds = _currentEvent!.admins.map((admin) => admin.id).toList();

    allMembers.addAll(adminIds);

    // Add member IDs from EventParticipant objects
    final memberIds = _currentEvent!.members
        .map((member) => member.id)
        .toList();

    allMembers.addAll(memberIds);

    final result = allMembers.toList();

    return result;
  }

  List<EventParticipant> getAllEventParticipants() {
    if (_currentEvent == null) return [];

    final allParticipants = <EventParticipant>[];
    allParticipants.addAll(_currentEvent!.admins);
    allParticipants.addAll(_currentEvent!.members);

    // Remove duplicates by ID
    final uniqueParticipants = <String, EventParticipant>{};
    for (var participant in allParticipants) {
      uniqueParticipants[participant.id] = participant;
    }

    return uniqueParticipants.values.toList();
  }

  bool isParticipantAdmin(String participantId) {
    if (_currentEvent == null) return false;
    return _currentEvent!.admins.any((admin) => admin.id == participantId);
  }

  bool isParticipantMember(String participantId) {
    if (_currentEvent == null) return false;
    return _currentEvent!.members.any((member) => member.id == participantId);
  }

  String? validateTaskName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Task name is required';
    }
    if (value.trim().length < 3) {
      return 'Task name must be at least 3 characters';
    }
    return null;
  }

  String? validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Description is required';
    }
    return null;
  }

  void setIsRecurring(bool value) {
    _isRecurring = value;
    // Clear date/time when switching to recurring
    if (_isRecurring) {
      _selectedDate = null;
      _selectedTime = null;
    }
    notifyListeners();
  }

  void setSelectedRecurrenceType(RecurrenceType type) {
    _selectedRecurrenceType = type;
    notifyListeners();
  }

  bool validateForm() {
    if (!formKey.currentState!.validate()) return false;

    // For single tasks, require date and time
    if (!_isRecurring && (_selectedDate == null || _selectedTime == null)) {
      return false;
    }

    if (_selectedMembers.isEmpty) {
      return false;
    }

    return true;
  }

  Future<bool> createTask(String eventId, String currentUserId) async {
    if (!validateForm()) return false;

    _isLoading = true;
    notifyListeners();

    try {
      DateTime? deadline;

      // Only set deadline for single tasks
      if (!_isRecurring) {
        deadline = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          _selectedTime!.hour,
          _selectedTime!.minute,
        );
      }

      final task = TaskModel(
        id: '',
        eventId: eventId,
        title: taskNameController.text.trim(),
        description: descriptionController.text.trim(),
        assignedToUsers: _selectedMembers,
        assignedToGroups: [],
        deadline: deadline, // null for recurring tasks
        status: 'pending',
        priority: _selectedPriority,
        completedBy: [],
        createdBy: currentUserId,
        createdAt: DateTime.now(),
        // Recurring task fields
        isRecurring: _isRecurring,
        recurrenceType: _isRecurring
            ? _selectedRecurrenceType
            : RecurrenceType.none,
        dailyCompletions: [],
      );

      await _tasksRepository.createTask(task);
      await NotificationManager().refreshListeners();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Color getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  String getPriorityDisplayName(String priority) {
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

  void reset() {
    taskNameController.clear();
    descriptionController.clear();
    _selectedDate = null;
    _selectedTime = null;
    _selectedPriority = 'medium';
    _selectedMembers.clear();
    _currentEvent = null;
    _isRecurring = false;
    _selectedRecurrenceType = RecurrenceType.daily;
    _isLoading = false;
    _isLoadingEvent = true;
    notifyListeners();
  }
}
