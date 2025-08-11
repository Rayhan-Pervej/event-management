// File: ui/widgets/task_section.dart
import 'package:event_management/ui/pages/tasks/widgets/user_task_card.dart';
import 'package:event_management/ui/widgets/app_dimensions.dart';
import 'package:flutter/material.dart';
import 'package:event_management/models/task_model.dart';
import 'package:event_management/models/event_model.dart';
import 'package:event_management/core/constants/build_text.dart';
import 'package:icons_plus/icons_plus.dart';

class TaskSection extends StatefulWidget {
  final String title;
  final List<TaskModel> tasks;
  final Map<String, EventModel> eventsMap;
  final String currentUserId;
  final Function(String taskId) onTaskToggle;
  final Color? headerColor;
  final IconData? headerIcon;
  final bool isCollapsible;
  final bool initiallyExpanded;

  const TaskSection({
    super.key,
    required this.title,
    required this.tasks,
    required this.eventsMap,
    required this.currentUserId,
    required this.onTaskToggle,
    this.headerColor,
    this.headerIcon,
    this.isCollapsible = true,
    this.initiallyExpanded = true,
  });

  @override
  State<TaskSection> createState() => _TaskSectionState();
}

class _TaskSectionState extends State<TaskSection> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (widget.tasks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.space16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radius12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          InkWell(
            onTap: widget.isCollapsible 
                ? () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  }
                : null,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppDimensions.radius12),
            ),
            child: Container(
              padding: const EdgeInsets.all(AppDimensions.space16),
              decoration: BoxDecoration(
                color: widget.headerColor?.withOpacity(0.1) ?? 
                       colorScheme.primary.withOpacity(0.1),
                borderRadius: _isExpanded && widget.tasks.isNotEmpty
                    ? const BorderRadius.vertical(
                        top: Radius.circular(AppDimensions.radius12),
                      )
                    : BorderRadius.circular(AppDimensions.radius12),
              ),
              child: Row(
                children: [
                  if (widget.headerIcon != null) ...[
                    Icon(
                      widget.headerIcon,
                      color: widget.headerColor ?? colorScheme.primary,
                      size: 20,
                    ),
                    AppDimensions.w8,
                  ],
                  
                  Expanded(
                    child: BuildText(
                      text: widget.title,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: widget.headerColor ?? colorScheme.primary,
                    ),
                  ),
                  
                  // Task count badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.space8,
                      vertical: AppDimensions.space4,
                    ),
                    decoration: BoxDecoration(
                      color: widget.headerColor ?? colorScheme.primary,
                      borderRadius: BorderRadius.circular(AppDimensions.radius8),
                    ),
                    child: BuildText(
                      text: widget.tasks.length.toString(),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  
                  if (widget.isCollapsible) ...[
                    AppDimensions.w8,
                    Icon(
                      _isExpanded 
                          ? Iconsax.arrow_up_2_outline 
                          : Iconsax.arrow_down_1_outline,
                      color: widget.headerColor ?? colorScheme.primary,
                      size: 18,
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Tasks List
          if (_isExpanded) ...[
            Padding(
              padding: const EdgeInsets.all(AppDimensions.space16),
              child: Column(
                children: widget.tasks.asMap().entries.map((entry) {
                  final index = entry.key;
                  final task = entry.value;
                  final event = widget.eventsMap[task.eventId];

                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index < widget.tasks.length - 1 
                          ? AppDimensions.space12 
                          : 0,
                    ),
                    child: UserTaskCard(
                      task: task,
                      event: event,
                      currentUserId: widget.currentUserId,
                      onTaskToggle: widget.onTaskToggle,
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}