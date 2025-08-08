// File: ui/pages/events/widgets/create_event_fab.dart
import 'package:flutter/material.dart';

class CreateEventFAB extends StatelessWidget {
  final VoidCallback onPressed;

  const CreateEventFAB({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FloatingActionButton.extended(
      onPressed: onPressed,
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      elevation: 3,
      icon: const Icon(Icons.add),
      label: const Text(
        'Create Event',
        style: TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}