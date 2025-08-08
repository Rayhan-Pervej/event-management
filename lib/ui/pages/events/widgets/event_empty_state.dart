// File: ui/pages/events/widgets/events_empty_state.dart
import 'package:event_management/core/constants/build_text.dart';
import 'package:flutter/material.dart';

class EventsEmptyState extends StatelessWidget {
  final VoidCallback onCreateEvent;


  const EventsEmptyState({
    super.key,
    required this.onCreateEvent,

  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bool isAdmin = true;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_outlined,
              size: 80,
              color: colorScheme.onSurface.withOpacity(0.3),
            ),

            const SizedBox(height: 24),

            BuildText(
              text: isAdmin ? 'No Events Created Yet' : 'No Events Available',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            BuildText(
              text: isAdmin
                  ? 'Start by creating your first event to manage tasks and teams.'
                  : 'You haven\'t been assigned to any events yet. Contact your admin for access.',
              fontSize: 16,
              color: colorScheme.onSurface.withOpacity(0.7),
              textAlign: TextAlign.center,
              maxLines: 3,
            ),

            const SizedBox(height: 24),

            // Refresh hint text
            BuildText(
              text: 'Pull down to refresh or tap the refresh button below',
              fontSize: 14,
              color: colorScheme.onSurface.withOpacity(0.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
