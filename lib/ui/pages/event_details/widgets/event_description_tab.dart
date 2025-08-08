// File: ui/widgets/event_description_tab.dart
import 'package:event_management/ui/widgets/app_dimensions.dart';
import 'package:flutter/material.dart';
import 'package:event_management/models/event_model.dart';

import 'package:event_management/core/constants/build_text.dart';
import 'package:event_management/ui/widgets/default_horizontal_divider.dart';
import 'package:icons_plus/icons_plus.dart';

class EventDescriptionTab extends StatelessWidget {
  final EventModel event;
  final bool isAdmin;

  const EventDescriptionTab({
    super.key,
    required this.event,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimensions.space16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(AppDimensions.radius12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Iconsax.document_text_outline,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                    AppDimensions.w8,
                    BuildText(
                      text: 'Description',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ],
                ),
                AppDimensions.h12,
                BuildText(
                  text: event.description.isNotEmpty 
                      ? event.description 
                      : 'No description available',
                  fontSize: 14,
                  color: event.description.isNotEmpty 
                      ? colorScheme.onSurface 
                      : colorScheme.onSurface.withOpacity(0.5),
                ),
              ],
            ),
          ),

          AppDimensions.h16,

          // Event Details Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimensions.space16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(AppDimensions.radius12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Iconsax.info_circle_outline,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                    AppDimensions.w8,
                    BuildText(
                      text: 'Event Details',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ],
                ),
                AppDimensions.h16,
                
                // Location
                _buildDetailRow(
                  context,
                  icon: Iconsax.location_outline,
                  label: 'Location',
                  value: event.location,
                ),
                
                AppDimensions.h12,
                const DefaultHorizontalDivider(),
                AppDimensions.h12,
                
                // Start Date
                _buildDetailRow(
                  context,
                  icon: Iconsax.calendar_1_outline,
                  label: 'Start Date',
                  value: _formatDateTime(event.startDate),
                ),
                
                AppDimensions.h12,
                const DefaultHorizontalDivider(),
                AppDimensions.h12,
                
                // End Date
                _buildDetailRow(
                  context,
                  icon: Iconsax.calendar_tick_outline,
                  label: 'End Date',
                  value: _formatDateTime(event.endDate),
                ),
                
                AppDimensions.h12,
                const DefaultHorizontalDivider(),
                AppDimensions.h12,
                
                // Total Participants
                _buildDetailRow(
                  context,
                  icon: Iconsax.people_outline,
                  label: 'Total Participants',
                  value: '${event.totalParticipants} people',
                ),
              ],
            ),
          ),

          AppDimensions.h16,

          // Statistics Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimensions.space16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(AppDimensions.radius12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Iconsax.chart_2_outline,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                    AppDimensions.w8,
                    BuildText(
                      text: 'Event Statistics',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ],
                ),
                AppDimensions.h16,
                
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        context,
                        label: 'Admins',
                        value: '${event.admins.length}',
                        color: colorScheme.primary,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        context,
                        label: 'Members',
                        value: '${event.members.length}',
                        color: colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(
          icon,
          color: colorScheme.primary,
          size: 18,
        ),
        AppDimensions.w12,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BuildText(
                text: label,
                fontSize: 12,
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
              AppDimensions.h4,
              BuildText(
                text: value,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.space12),
      margin: const EdgeInsets.only(right: AppDimensions.space8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radius8),
      ),
      child: Column(
        children: [
          BuildText(
            text: value,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          AppDimensions.h4,
          BuildText(
            text: label,
            fontSize: 12,
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}