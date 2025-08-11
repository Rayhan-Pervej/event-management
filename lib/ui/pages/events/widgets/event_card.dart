// File: ui/pages/events/widgets/event_card.dart
import 'package:event_management/core/constants/build_text.dart';
import 'package:event_management/models/event_model.dart';
import 'package:event_management/ui/widgets/event_status_chip.dart';
import 'package:flutter/material.dart';
// import 'package:event_management/models/event_model.dart';
// import 'package:event_management/core/constants/build_text.dart';

class EventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback onTap;

  const EventCard({super.key, required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      color: colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: BuildText(
                      text: event.title,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      maxLines: 2,
                    ),
                  ),
                  EventStatusChip(status: event.status),
                ],
              ),

              const SizedBox(height: 8),

              // Location
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: BuildText(
                      text: event.location,
                      fontSize: 14,
                      color: colorScheme.onSurface.withOpacity(0.8),
                      maxLines: 1,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Date Range
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  BuildText(
                    text: _formatDateRange(event.startDate, event.endDate),
                    fontSize: 14,
                    color: colorScheme.onSurface.withOpacity(0.8),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Footer Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 16,
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                      const SizedBox(width: 4),
                      BuildText(
                        text: '${event.totalParticipants} participants',
                        fontSize: 12,
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ],
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: colorScheme.onSurface.withOpacity(0.4),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateRange(DateTime start, DateTime end) {
    // TODO: Implement proper date formatting using intl package
    return '${start.day}/${start.month} - ${end.day}/${end.month}';
  }
}
