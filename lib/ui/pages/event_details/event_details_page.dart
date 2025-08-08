// File: ui/pages/event_details_page.dart
import 'package:event_management/models/event_model.dart';
import 'package:event_management/ui/pages/event_details/widgets/event_description_tab.dart';
import 'package:event_management/ui/pages/event_details/widgets/event_members_tab.dart';
import 'package:event_management/ui/pages/event_details/widgets/event_tasks_tab.dart';
import 'package:event_management/ui/widgets/app_dimensions.dart';
import 'package:event_management/ui/widgets/default_appbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:event_management/providers/event_details_provider.dart';
import 'package:event_management/providers/events_provider.dart';
import 'package:event_management/ui/widgets/event_status_chip.dart';

import 'package:event_management/core/constants/build_text.dart';

class EventDetailsPage extends StatefulWidget {
  final String eventId;
  final String currentUserId;

  const EventDetailsPage({
    super.key,
    required this.eventId,
    required this.currentUserId,
  });

  @override
  State<EventDetailsPage> createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late EventDetailsProvider _eventDetailsProvider;
  late EventsProvider _eventsProvider;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _eventDetailsProvider = Provider.of<EventDetailsProvider>(
      context,
      listen: false,
    );
    _eventsProvider = Provider.of<EventsProvider>(context, listen: false);
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _eventDetailsProvider.initialize(widget.eventId);
  }

  Future<void> _refreshData() async {
    // Force refresh both providers from the database
    await Future.wait([
      _eventDetailsProvider.refresh(widget.eventId),
      _eventsProvider.refreshEvent(widget.eventId),
    ]);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Listen for changes in EventsProvider and update EventDetailsProvider
  void _syncWithEventsProvider() {
    final updatedEvent = _eventsProvider.getEventById(widget.eventId);
    if (updatedEvent != null && _eventDetailsProvider.event != null) {
      // Check if member/admin counts have changed
      final currentEvent = _eventDetailsProvider.event!;
      final shouldUpdate = _shouldUpdateEvent(currentEvent, updatedEvent);

      if (shouldUpdate) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _eventDetailsProvider.updateEvent(updatedEvent);
        });
      }
    }
  }

  // Helper method to check if event should be updated
  bool _shouldUpdateEvent(EventModel current, EventModel updated) {
    // Check if member/admin counts have changed
    if (current.members.length != updated.members.length ||
        current.admins.length != updated.admins.length) {
      return true;
    }

    // Check if member IDs have changed
    final currentMemberIds = current.members.map((m) => m.id).toSet();
    final updatedMemberIds = updated.members.map((m) => m.id).toSet();

    final currentAdminIds = current.admins.map((a) => a.id).toSet();
    final updatedAdminIds = updated.admins.map((a) => a.id).toSet();

    return !currentMemberIds.containsAll(updatedMemberIds) ||
        !updatedMemberIds.containsAll(currentMemberIds) ||
        !currentAdminIds.containsAll(updatedAdminIds) ||
        !updatedAdminIds.containsAll(currentAdminIds);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.primaryContainer,
      appBar: DefaultAppBar(
        title: 'Event Details',
        backgroundColor: colorScheme.surface,
      ),
      body: Consumer2<EventDetailsProvider, EventsProvider>(
        builder: (context, eventDetailsProvider, eventsProvider, child) {
          // Sync data from EventsProvider
          _syncWithEventsProvider();

          if (eventDetailsProvider.event == null &&
              eventDetailsProvider.isLoadingEvent) {
            return Center(
              child: CircularProgressIndicator(color: colorScheme.primary),
            );
          }

          if (eventDetailsProvider.event == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: colorScheme.error),
                  AppDimensions.h16,
                  BuildText(
                    text: 'Event not found',
                    fontSize: 16,
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ],
              ),
            );
          }

          final event = eventDetailsProvider.event!;
          final isAdmin = event.isUserAdmin(widget.currentUserId);

          return Column(
            children: [
              // Event Header
              Container(
                width: double.infinity,
                color: colorScheme.surface,
                padding: const EdgeInsets.all(AppDimensions.space16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: BuildText(
                            text: event.title,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        EventStatusChip(status: event.status),
                      ],
                    ),
                    AppDimensions.h8,
                    BuildText(
                      text: event.location,
                      fontSize: 14,
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                    AppDimensions.h4,
                    BuildText(
                      text:
                          '${_formatDate(event.startDate)} - ${_formatDate(event.endDate)}',
                      fontSize: 14,
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ],
                ),
              ),

              // Tab Bar
              Container(
                color: colorScheme.surface,
                child: TabBar(
                  controller: _tabController,
                  labelColor: colorScheme.primary,
                  unselectedLabelColor: colorScheme.onSurface.withOpacity(0.6),
                  indicatorColor: colorScheme.primary,
                  indicatorWeight: 2,
                  tabs: const [
                    Tab(text: 'Description'),
                    Tab(text: 'Members'),
                    Tab(text: 'Tasks'),
                  ],
                ),
              ),

              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    RefreshIndicator(
                      onRefresh: _refreshData,
                      child: EventDescriptionTab(
                        event: event,
                        isAdmin: isAdmin,
                      ),
                    ),
                    RefreshIndicator(
                      onRefresh: _refreshData,
                      child: EventMembersTab(
                        event: event,
                        isAdmin: isAdmin,
                        currentUserId: widget.currentUserId,
                        onRefresh: _refreshData,
                      ),
                    ),
                    RefreshIndicator(
                      onRefresh: _refreshData,
                      child: EventTasksTab(
                        eventId: widget.eventId,
                        isAdmin: isAdmin,
                        currentUserId: widget.currentUserId,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
