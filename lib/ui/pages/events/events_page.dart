// File: ui/pages/events/events_page.dart
import 'package:event_management/models/event_model.dart';
import 'package:event_management/providers/events_provider.dart';
import 'package:event_management/ui/pages/create_event/create_event_page.dart';
import 'package:event_management/ui/pages/event_details/event_details_page.dart';
import 'package:event_management/ui/pages/events/widgets/create_event_fab.dart';
import 'package:event_management/ui/pages/events/widgets/event_empty_state.dart';
import 'package:event_management/ui/pages/events/widgets/event_filter_chips.dart';
import 'package:event_management/ui/pages/events/widgets/event_card.dart';
import 'package:event_management/ui/widgets/default_appbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  @override
  void initState() {
    super.initState();
    _initializeEvents();
  }

  void _initializeEvents() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final eventsProvider = context.read<EventsProvider>();
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId != null) {
        eventsProvider.initialize(currentUserId);
      }
    });
  }

  void _onFilterChanged(String filter) {
    context.read<EventsProvider>().applyFilter(filter);
  }

  Future<void> _onRefresh() async {
    await context.read<EventsProvider>().refreshEvents();
  }

  void _createEvent() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateEventPage()),
    ).then((_) {
      // Refresh events when returning from create page
      if (mounted) {
        context.read<EventsProvider>().refreshEvents();
      }
    });
  }

  void _onEventTap(EventModel event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventDetailsPage(
          eventId: event.id,
          currentUserId: FirebaseAuth.instance.currentUser!.uid,
        ),
      ),
    );
  }

  Widget _buildErrorMessage(
    EventsProvider eventsProvider,
    ColorScheme colorScheme,
  ) {
    if (eventsProvider.errorMessage == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: colorScheme.onErrorContainer,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              eventsProvider.errorMessage!,
              style: TextStyle(
                color: colorScheme.onErrorContainer,
                fontSize: 14,
              ),
            ),
          ),
          IconButton(
            onPressed: _onRefresh,
            icon: Icon(
              Icons.refresh,
              color: colorScheme.onErrorContainer,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList(EventsProvider eventsProvider) {
    if (eventsProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Always wrap content in RefreshIndicator for universal refresh capability
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: eventsProvider.hasEvents
          ? ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: eventsProvider.events.length,
              itemBuilder: (context, index) {
                final event = eventsProvider.events[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: EventCard(
                    event: event,
                    onTap: () => _onEventTap(event),
                  ),
                );
              },
            )
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: EventsEmptyState(onCreateEvent: _createEvent),
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: DefaultAppBar(
        title: 'Events',
        isShowBackButton: false,
        centerTitle: false,
      ),
      body: Consumer<EventsProvider>(
        builder: (context, eventsProvider, child) {
          return Column(
            children: [
              // Filter Section
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  border: Border(
                    bottom: BorderSide(
                      color: colorScheme.onSurface.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: EventFilterChips(
                  filters: const ['All', 'Upcoming', 'Ongoing', 'Completed'],
                  selectedFilter: eventsProvider.currentFilter,
                  onFilterChanged: _onFilterChanged,
                ),
              ),

              // Error message
              _buildErrorMessage(eventsProvider, colorScheme),

              // Events List with universal refresh capability
              Expanded(child: _buildEventsList(eventsProvider)),
            ],
          );
        },
      ),
      floatingActionButton: Consumer<EventsProvider>(
        builder: (context, eventsProvider, child) {
          final currentUserId = FirebaseAuth.instance.currentUser?.uid;
          return currentUserId != null
              ? CreateEventFAB(onPressed: _createEvent)
              : const SizedBox.shrink();
        },
      ),
    );
  }
}
