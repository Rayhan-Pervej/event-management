// File: ui/widgets/event_status_chip.dart (Core widget - reusable across app)
import 'package:event_management/core/constants/build_text.dart';
import 'package:flutter/material.dart';
// import 'package:event_management/core/constants/build_text.dart';

class EventStatusChip extends StatelessWidget {
  final String status;
  final double? fontSize;

  const EventStatusChip({
    super.key,
    required this.status,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    Color chipColor;
    Color textColor;
    
    switch (status.toLowerCase()) {
      case 'upcoming':
        chipColor = Colors.blue.withOpacity(0.1);
        textColor = Colors.blue;
        break;
      case 'ongoing':
        chipColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green;
        break;
      case 'completed':
        chipColor = Colors.grey.withOpacity(0.1);
        textColor = Colors.grey;
        break;
      default:
        chipColor = colorScheme.primaryContainer;
        textColor = colorScheme.onPrimaryContainer;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: BuildText(
        text: status,
        fontSize: fontSize!,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
    );
  }
}