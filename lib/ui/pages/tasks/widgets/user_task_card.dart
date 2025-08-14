// File: ui/widgets/user_task_card.dart
import 'package:event_management/core/utils/date_utilites.dart';
import 'package:event_management/ui/widgets/app_dimensions.dart';
import 'package:flutter/material.dart';
import 'package:event_management/models/task_model.dart';
import 'package:event_management/models/event_model.dart';
import 'package:event_management/core/constants/build_text.dart';
import 'package:icons_plus/icons_plus.dart';

class UserTaskCard extends StatelessWidget {
  final TaskModel task;
  final EventModel? event;
  final String currentUserId;
  final Function(String taskId) onTaskToggle;
  final VoidCallback? onTaskTap;

  const UserTaskCard({
    super.key,
    required this.task,
    required this.event,
    required this.currentUserId,
    required this.onTaskToggle,
    this.onTaskTap,
  });

@override
Widget build(BuildContext context) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  
  // FIXED: Handle completion check for both task types
  final isCompletedByUser = task.isRecurring 
      ? task.isCompletedToday(currentUserId)
      : task.isCompletedByUser(currentUserId);

  return GestureDetector(
    onTap: onTaskTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.space12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppDimensions.radius12),
        // FIXED: Only show overdue border for single tasks
        border: (!task.isRecurring && task.isOverdue && !task.isCompleted)
            ? Border.all(color: Colors.red, width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Task Title with recurring indicator
                      Row(
                        children: [
                          // FIXED: Add recurring indicator
                          if (task.isRecurring) ...[
                            Icon(
                              Icons.repeat,
                              size: 16,
                              color: Colors.purple,
                            ),
                            AppDimensions.w4,
                          ],
                          Expanded(
                            child: BuildText(
                              text: task.title,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      AppDimensions.h4,

                      // Event Info
                      if (event != null) ...[
                        Row(
                          children: [
                            Icon(
                              Iconsax.calendar_1_outline,
                              size: 14,
                              color: colorScheme.primary,
                            ),
                            AppDimensions.w4,
                            Expanded(
                              child: BuildText(
                                text: event!.title,
                                fontSize: 12,
                                color: colorScheme.primary,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        AppDimensions.h8,
                      ],

                      // Priority and Status/Recurrence Chips
                      Row(
                        children: [
                          _buildPriorityChip(context),
                          AppDimensions.w8,
                          // FIXED: Show different chip for recurring tasks
                          if (task.isRecurring)
                            _buildRecurrenceChip(context)
                          else
                            _buildStatusChip(context),
                          // FIXED: Only show overdue for single tasks
                          if (!task.isRecurring && task.isOverdue && !task.isCompleted) ...[
                            AppDimensions.w8,
                            _buildOverdueChip(context),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Completion Checkbox
                Checkbox(
                  value: isCompletedByUser,
                  onChanged: (value) => onTaskToggle(task.id),
                  activeColor: colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),

            AppDimensions.h12,

            // Task Description
            if (task.description.isNotEmpty) ...[
              BuildText(
                text: task.description,
                fontSize: 14,
                color: colorScheme.onSurface.withOpacity(0.7),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              AppDimensions.h12,
            ],

            // FIXED: Different info for recurring vs single tasks
            if (task.isRecurring) ...[
              // Recurring task info
              Row(
                children: [
                  Expanded(child: _buildRecurrenceInfo(context)),
                  AppDimensions.w16,
                  _buildTodayProgressInfo(context),
                ],
              ),
            ] else ...[
              // Single task deadline and progress info
              Row(
                children: [
                  Expanded(child: _buildDeadlineInfo(context)),
                  AppDimensions.w16,
                  _buildProgressInfo(context),
                ],
              ),
            ],

            // Completion Progress Bar
            if (task.totalAssignees > 1) ...[
              AppDimensions.h12,
              _buildProgressBar(context),
            ],

            // User's completion status
            if (isCompletedByUser) ...[
              AppDimensions.h8,
              Row(
                children: [
                  Icon(
                    Iconsax.tick_circle_bold,
                    size: 16,
                    color: Colors.green,
                  ),
                  AppDimensions.w4,
                  BuildText(
                    text: task.isRecurring ? 'Completed today' : 'Completed by you',
                    fontSize: 12,
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

Widget _buildRecurrenceChip(BuildContext context) {
  return Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppDimensions.space8,
      vertical: AppDimensions.space4,
    ),
    decoration: BoxDecoration(
      color: Colors.purple.withOpacity(0.1),
      borderRadius: BorderRadius.circular(AppDimensions.radius8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.repeat, size: 12, color: Colors.purple),
        AppDimensions.w4,
        BuildText(
          text: task.recurrenceDisplayName.toUpperCase(),
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.purple,
        ),
      ],
    ),
  );
}

Widget _buildRecurrenceInfo(BuildContext context) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;

  return Row(
    children: [
      Icon(Icons.repeat, size: 14, color: Colors.purple),
      AppDimensions.w4,
      Expanded(
        child: BuildText(
          text: '${task.recurrenceDisplayName} task',
          fontSize: 12,
          color: Colors.purple,
          fontWeight: FontWeight.w500,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}

Widget _buildTodayProgressInfo(BuildContext context) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  final today = TaskModel.getTodayDateString();
  final completedToday = task.getCompletionCountForDate(today);

  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        Iconsax.people_outline,
        size: 14,
        color: colorScheme.onSurface.withOpacity(0.6),
      ),
      AppDimensions.w4,
      BuildText(
        text: '$completedToday/${task.totalAssignees} today',
        fontSize: 12,
        color: colorScheme.onSurface.withOpacity(0.6),
      ),
    ],
  );
}

  Widget _buildPriorityChip(BuildContext context) {
    Color chipColor;
    Color textColor;
    IconData icon;

    switch (task.priority.toLowerCase()) {
      case 'high':
        chipColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red;
        icon = Iconsax.arrow_up_outline;
        break;
      case 'medium':
        chipColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange;
        icon = Iconsax.minus_outline;
        break;
      case 'low':
        chipColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green;
        icon = Iconsax.arrow_down_outline;
        break;
      default:
        chipColor = Colors.grey.withOpacity(0.1);
        textColor = Colors.grey;
        icon = Iconsax.minus_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space8,
        vertical: AppDimensions.space4,
      ),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(AppDimensions.radius8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          AppDimensions.w4,
          BuildText(
            text: task.priority.toUpperCase(),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color chipColor;
    Color textColor;
    IconData icon;

    switch (task.status.toLowerCase()) {
      case 'pending':
        chipColor = Colors.grey.withOpacity(0.1);
        textColor = Colors.grey;
        icon = Iconsax.clock_outline;
        break;
      case 'in_progress':
        chipColor = Colors.blue.withOpacity(0.1);
        textColor = Colors.blue;
        icon = Iconsax.play_outline;
        break;
      case 'completed':
        chipColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green;
        icon = Iconsax.tick_circle_outline;
        break;
      default:
        chipColor = colorScheme.onSurface.withOpacity(0.1);
        textColor = colorScheme.onSurface;
        icon = Iconsax.info_circle_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space8,
        vertical: AppDimensions.space4,
      ),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(AppDimensions.radius8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          AppDimensions.w4,
          BuildText(
            text: task.status.replaceAll('_', ' ').toUpperCase(),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ],
      ),
    );
  }

  Widget _buildOverdueChip(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space8,
        vertical: AppDimensions.space4,
      ),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radius8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Iconsax.warning_2_outline, size: 12, color: Colors.red),
          AppDimensions.w4,
          BuildText(
            text: 'OVERDUE',
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.red,
          ),
        ],
      ),
    );
  }

Widget _buildDeadlineInfo(BuildContext context) {
  // FIXED: Handle null deadline for recurring tasks
  if (task.deadline == null) {
    return Row(
      children: [
        Icon(Icons.repeat, size: 14, color: Colors.purple),
        AppDimensions.w4,
        Expanded(
          child: BuildText(
            text: 'Recurring task',
            fontSize: 12,
            color: Colors.purple,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  final now = DateTime.now();
  final timeDiff = task.deadline!.difference(now);

  Color deadlineColor;
  String timeText;

  if (task.isCompleted) {
    deadlineColor = colorScheme.onSurface.withOpacity(0.6);
    timeText = DateUtilites.formatDetailedDeadline(task.deadline!);
  } else if (timeDiff.isNegative) {
    deadlineColor = Colors.red;
    final overdueDuration = now.difference(task.deadline!);
    if (overdueDuration.inDays > 0) {
      timeText = '${overdueDuration.inDays}d overdue';
    } else if (overdueDuration.inHours > 0) {
      timeText = '${overdueDuration.inHours}h overdue';
    } else {
      timeText = '${overdueDuration.inMinutes}m overdue';
    }
  } else if (timeDiff.inDays == 0) {
    deadlineColor = Colors.orange;
    if (timeDiff.inHours > 0) {
      timeText = 'Due in ${timeDiff.inHours}h';
    } else {
      timeText = 'Due in ${timeDiff.inMinutes}m';
    }
  } else if (timeDiff.inDays == 1) {
    deadlineColor = Colors.orange;
    timeText = 'Due tomorrow';
  } else if (timeDiff.inDays <= 7) {
    deadlineColor = colorScheme.onSurface.withOpacity(0.7);
    timeText = 'Due in ${timeDiff.inDays}d';
  } else {
    deadlineColor = colorScheme.onSurface.withOpacity(0.7);
    timeText = DateUtilites.formatDetailedDeadline(task.deadline!);
  }

  return Row(
    children: [
      Icon(Iconsax.clock_outline, size: 14, color: deadlineColor),
      AppDimensions.w4,
      Expanded(
        child: BuildText(
          text: timeText,
          fontSize: 12,
          color: deadlineColor,
          fontWeight: timeDiff.isNegative || timeDiff.inDays <= 1
              ? FontWeight.w600
              : FontWeight.normal,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}

  Widget _buildProgressInfo(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Iconsax.people_outline,
          size: 14,
          color: colorScheme.onSurface.withOpacity(0.6),
        ),
        AppDimensions.w4,
        BuildText(
          text: '${task.completedCount}/${task.totalAssignees}',
          fontSize: 12,
          color: colorScheme.onSurface.withOpacity(0.6),
        ),
      ],
    );
  }

Widget _buildProgressBar(BuildContext context) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  
  // FIXED: Use appropriate progress calculation
  final progressValue = task.isRecurring 
      ? task.getCompletionPercentageForDate(TaskModel.getTodayDateString()) / 100
      : task.completionPercentage / 100;
  
  final isFullyCompleted = task.isRecurring 
      ? task.getCompletionCountForDate(TaskModel.getTodayDateString()) == task.totalAssignees
      : task.isCompleted;

  return Row(
    children: [
      Expanded(
        child: LinearProgressIndicator(
          value: progressValue,
          backgroundColor: colorScheme.onSurface.withOpacity(0.1),
          valueColor: AlwaysStoppedAnimation<Color>(
            isFullyCompleted ? Colors.green : colorScheme.primary,
          ),
          minHeight: 4,
        ),
      ),
      AppDimensions.w8,
      BuildText(
        text: task.isRecurring 
            ? '${task.getCompletionPercentageForDate(TaskModel.getTodayDateString()).toInt()}%'
            : '${task.completionPercentage.toInt()}%',
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurface.withOpacity(0.7),
      ),
    ],
  );
}
}
