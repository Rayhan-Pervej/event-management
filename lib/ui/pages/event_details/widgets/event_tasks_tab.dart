// File: ui/widgets/event_tasks_tab.dart
import 'package:event_management/core/utils/date_utilites.dart';
import 'package:event_management/ui/pages/create_task/create_task_page.dart';
import 'package:event_management/ui/widgets/app_dimensions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:event_management/providers/event_details_provider.dart';
import 'package:event_management/models/task_model.dart';
import 'package:event_management/core/constants/build_text.dart';
import 'package:event_management/ui/widgets/default_button.dart';
import 'package:icons_plus/icons_plus.dart';

class EventTasksTab extends StatelessWidget {
  final String eventId;
  final bool isAdmin;
  final String currentUserId;

  const EventTasksTab({
    super.key,
    required this.eventId,
    required this.isAdmin,
    required this.currentUserId,
  });

  // Fix: Update the EventTasksTab build method to ensure refresh works with small content

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<EventDetailsProvider>(
      builder: (context, provider, child) {
        return RefreshIndicator(
          onRefresh: () async {
            await provider.reloadTasks();
          },
          child: SingleChildScrollView(
            // Add physics to ensure refresh indicator always works
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppDimensions.space16),
            child: ConstrainedBox(
              // Ensure content takes at least the screen height minus padding
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    kToolbarHeight -
                    100, // Approximate tab bar height + padding
              ),
              child: Column(
                children: [
                  DefaultButton(
                    text: 'Add New Task',
                    press: () async {
                      // Navigate to create task page and wait for result
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreateTaskPage(
                            eventId: eventId,
                            currentUserId: currentUserId,
                          ),
                        ),
                      );

                      // If task was created successfully, refresh the tasks
                      if (result == true) {
                        provider.loadTasks(eventId);
                      }
                    },
                    bgColor: colorScheme.primary,
                  ),
                  AppDimensions.h16,

                  // Task Statistics
                  _buildTaskStats(context, provider),

                  AppDimensions.h16,

                  // Tasks List
                  provider.isLoadingTasks
                      ? Center(
                          child: CircularProgressIndicator(
                            color: colorScheme.primary,
                          ),
                        )
                      : provider.tasks.isEmpty
                      ? _buildEmptyState(context)
                      : Column(
                          children: provider.tasks.map((task) {
                            return _buildTaskCard(context, task, provider);
                          }).toList(),
                        ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTaskStats(BuildContext context, EventDetailsProvider provider) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppDimensions.radius12),
      ),
      child: Column(
        children: [
          // First row - Overall stats
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  label: 'Total',
                  value: provider.totalTasks.toString(),
                  color: colorScheme.primary,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  context,
                  label: 'Single Tasks',
                  value: provider.singleTasksCount.toString(),
                  color: Colors.blue,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  context,
                  label: 'Recurring',
                  value: provider.recurringTasksCount.toString(),
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          AppDimensions.h12,
          // Second row - Single task status (only for single tasks)
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  label: 'Pending',
                  value: provider.pendingCount.toString(),
                  color: Colors.orange,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  context,
                  label: 'Completed',
                  value: provider.completedCount.toString(),
                  color: Colors.green,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  context,
                  label: 'Overdue',
                  value: provider.overdueCount.toString(),
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
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

    return Column(
      children: [
        BuildText(
          text: value,
          fontSize: 18,
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
    );
  }

  Widget _buildTaskCard(
    BuildContext context,
    TaskModel task,
    EventDetailsProvider provider,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isAssignedToUser = task.isAssignedToUser(currentUserId);

    // FIXED: Handle completion check for both task types
    final isCompletedByUser = task.isRecurring
        ? task.isCompletedToday(currentUserId)
        : task.isCompletedByUser(currentUserId);

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.space12),
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppDimensions.radius12),
        // FIXED: Only show overdue border for single tasks
        border: (!task.isRecurring && task.isOverdue)
            ? Border.all(color: Colors.red, width: 1)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Task Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // FIXED: Add recurring indicator
                        if (task.isRecurring) ...[
                          Icon(Icons.repeat, size: 16, color: Colors.purple),
                          AppDimensions.w4,
                        ],
                        Expanded(
                          child: BuildText(
                            text: task.title,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color:
                                (task.isRecurring
                                    ? isCompletedByUser
                                    : task.isCompleted)
                                ? colorScheme.onSurface.withOpacity(0.6)
                                : colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    AppDimensions.h4,
                    Row(
                      children: [
                        _buildPriorityChip(context, task.priority),
                        AppDimensions.w8,
                        // FIXED: Show different status for recurring tasks
                        if (task.isRecurring)
                          _buildRecurrenceChip(
                            context,
                            task.recurrenceDisplayName,
                          )
                        else
                          _buildStatusChip(context, task.status),
                      ],
                    ),
                  ],
                ),
              ),

              if (isAssignedToUser && !isAdmin) ...[
                Checkbox(
                  value: isCompletedByUser,
                  onChanged: (value) async {
                    if (value == true) {
                      // FIXED: Use appropriate completion method
                      final success = task.isRecurring
                          ? await provider.completeTaskToday(
                              task.id,
                              currentUserId,
                            )
                          : await provider.completeTask(task.id, currentUserId);

                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              task.isRecurring
                                  ? 'Task completed for today!'
                                  : 'Task completed!',
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Failed to complete task'),
                          ),
                        );
                      }
                    } else {
                      // Handle uncomplete with confirmation
                      final confirmed = await _showUncompleteConfirmation(
                        context,
                      );
                      if (confirmed) {
                        // FIXED: Use appropriate uncomplete method
                        final success = task.isRecurring
                            ? await provider.uncompleteTaskToday(
                                task.id,
                                currentUserId,
                              )
                            : await provider.uncompleteTask(
                                task.id,
                                currentUserId,
                              );

                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                task.isRecurring
                                    ? 'Task marked as incomplete for today'
                                    : 'Task marked as incomplete',
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to update task'),
                            ),
                          );
                        }
                      }
                    }
                  },
                  activeColor: colorScheme.primary,
                ),
                AppDimensions.w8,
              ],

              // Three-dot menu (for admin only)
              if (isAdmin)
                PopupMenuButton<String>(
                  color: colorScheme.primaryContainer,
                  icon: Icon(
                    Iconsax.more_outline,
                    color: colorScheme.onSurface.withOpacity(0.5),
                  ),
                  onSelected: (value) async {
                    switch (value) {
                      case 'complete':
                        // FIXED: Use appropriate completion method
                        final success = task.isRecurring
                            ? await provider.completeTaskToday(
                                task.id,
                                currentUserId,
                              )
                            : await provider.completeTask(
                                task.id,
                                currentUserId,
                              );

                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                task.isRecurring
                                    ? 'Task completed for today!'
                                    : 'Task completed!',
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to complete task'),
                            ),
                          );
                        }
                        break;
                      case 'uncomplete':
                        final confirmed = await _showUncompleteConfirmation(
                          context,
                        );
                        if (confirmed) {
                          // FIXED: Use appropriate uncomplete method
                          final success = task.isRecurring
                              ? await provider.uncompleteTaskToday(
                                  task.id,
                                  currentUserId,
                                )
                              : await provider.uncompleteTask(
                                  task.id,
                                  currentUserId,
                                );

                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  task.isRecurring
                                      ? 'Task marked as incomplete for today'
                                      : 'Task marked as incomplete',
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Failed to update task'),
                              ),
                            );
                          }
                        }
                        break;
                      case 'edit':
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Navigate to Edit Task'),
                          ),
                        );
                        break;
                      case 'delete':
                        final confirmed = await _showDeleteConfirmation(
                          context,
                        );
                        if (confirmed) {
                          final success = await provider.deleteTask(task.id);
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Task deleted')),
                            );
                          }
                        }
                        break;
                    }
                  },
                  itemBuilder: (context) {
                    List<PopupMenuItem<String>> items = [];

                    // Admin completion options
                    if (task.isRecurring) {
                      // For recurring tasks, show today's completion status
                      if (!task.isCompletedToday(currentUserId)) {
                        items.add(
                          PopupMenuItem(
                            value: 'complete',
                            child: Row(
                              children: [
                                Icon(
                                  Iconsax.tick_circle_outline,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Complete Today',
                                  style: TextStyle(color: Colors.green),
                                ),
                              ],
                            ),
                          ),
                        );
                      } else {
                        items.add(
                          PopupMenuItem(
                            value: 'uncomplete',
                            child: Row(
                              children: [
                                Icon(
                                  Iconsax.close_circle_outline,
                                  color: Colors.orange,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Uncomplete Today',
                                  style: TextStyle(color: Colors.orange),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    } else {
                      // For single tasks, show regular completion status
                      if (!task.isCompleted) {
                        items.add(
                          PopupMenuItem(
                            value: 'complete',
                            child: Row(
                              children: [
                                Icon(
                                  Iconsax.tick_circle_outline,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Mark Complete',
                                  style: TextStyle(color: Colors.green),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      if (task.isCompletedByUser(currentUserId)) {
                        items.add(
                          PopupMenuItem(
                            value: 'uncomplete',
                            child: Row(
                              children: [
                                Icon(
                                  Iconsax.close_circle_outline,
                                  color: Colors.orange,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Mark Incomplete',
                                  style: TextStyle(color: Colors.orange),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    }

                    // Divider if completion options exist
                    if (items.isNotEmpty) {
                      items.add(
                        const PopupMenuItem(
                          value: 'divider',
                          enabled: false,
                          child: Divider(height: 1),
                        ),
                      );
                    }

                    // Admin management options
                    items.addAll([
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Iconsax.edit_outline),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Iconsax.trash_outline, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ]);

                    return items;
                  },
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
            ),
            AppDimensions.h12,
          ],

          // Task Details - FIXED: Handle recurring tasks differently
          if (task.isRecurring) ...[
            // Recurring task details
            Row(
              children: [
                Icon(Icons.repeat, size: 16, color: Colors.purple),
                AppDimensions.w4,
                BuildText(
                  text: task.recurrenceDisplayName,
                  fontSize: 12,
                  color: Colors.purple,
                ),
                AppDimensions.w16,
                Icon(
                  Iconsax.people_outline,
                  size: 16,
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
                AppDimensions.w4,
                BuildText(
                  text: '${task.totalAssignees} assigned',
                  fontSize: 12,
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ],
            ),
          ] else ...[
            // Single task details
            Row(
              children: [
                Icon(
                  Iconsax.calendar_outline,
                  size: 16,
                  color: task.isOverdue
                      ? Colors.red
                      : colorScheme.onSurface.withOpacity(0.6),
                ),
                AppDimensions.w4,
                BuildText(
                  text: DateUtilites.formatDetailedDeadline(task.deadline!),
                  fontSize: 12,
                  color: task.isOverdue
                      ? Colors.red
                      : colorScheme.onSurface.withOpacity(0.6),
                ),
                AppDimensions.w16,
                Icon(
                  Iconsax.people_outline,
                  size: 16,
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
                AppDimensions.w4,
                BuildText(
                  text: '${task.totalAssignees} assigned',
                  fontSize: 12,
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ],
            ),
          ],

          // Completion Progress - FIXED: Handle recurring tasks
          if (task.totalAssignees > 0) ...[
            AppDimensions.h8,
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: task.isRecurring
                        ? task.getCompletionPercentageForDate(
                                TaskModel.getTodayDateString(),
                              ) /
                              100
                        : task.completionPercentage / 100,
                    backgroundColor: colorScheme.onSurface.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      task.isRecurring
                          ? (task.getCompletionCountForDate(
                                      TaskModel.getTodayDateString(),
                                    ) ==
                                    task.totalAssignees
                                ? Colors.green
                                : colorScheme.primary)
                          : (task.isCompleted
                                ? Colors.green
                                : colorScheme.primary),
                    ),
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
            ),
          ],

          // Completion Status for User
          if (isAssignedToUser && isCompletedByUser) ...[
            AppDimensions.h8,
            Row(
              children: [
                Icon(
                  Iconsax.tick_circle_outline,
                  size: 16,
                  color: Colors.green,
                ),
                AppDimensions.w4,
                BuildText(
                  text: task.isRecurring
                      ? 'Completed today'
                      : 'Completed by you',
                  fontSize: 12,
                  color: Colors.green,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecurrenceChip(BuildContext context, String recurrenceType) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space8,
        vertical: AppDimensions.space2,
      ),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radius4),
      ),
      child: BuildText(
        text: recurrenceType.toUpperCase(),
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: Colors.purple,
      ),
    );
  }

  Future<bool> _showUncompleteConfirmation(BuildContext context) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: colorScheme.primaryContainer,
            title: BuildText(
              text: 'Mark as Incomplete',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
            content: BuildText(
              text: 'Are you sure you want to mark this task as incomplete?',
              fontSize: 14,
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: BuildText(
                  text: 'Cancel',
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const BuildText(
                  text: 'Mark Incomplete',
                  color: Colors.orange,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _buildPriorityChip(BuildContext context, String priority) {
    Color chipColor;
    Color textColor;

    switch (priority.toLowerCase()) {
      case 'high':
        chipColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red;
        break;
      case 'medium':
        chipColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange;
        break;
      case 'low':
        chipColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green;
        break;
      default:
        chipColor = Colors.grey.withOpacity(0.1);
        textColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space8,
        vertical: AppDimensions.space2,
      ),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(AppDimensions.radius4),
      ),
      child: BuildText(
        text: priority.toUpperCase(),
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, String status) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color chipColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'pending':
        chipColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange;
        break;
      case 'in_progress':
        chipColor = Colors.blue.withOpacity(0.1);
        textColor = Colors.blue;
        break;
      case 'completed':
        chipColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green;
        break;
      default:
        chipColor = colorScheme.onSurface.withOpacity(0.1);
        textColor = colorScheme.onSurface;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space8,
        vertical: AppDimensions.space2,
      ),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(AppDimensions.radius4),
      ),
      child: BuildText(
        text: status.replaceAll('_', ' ').toUpperCase(),
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.task_square_outline, size: 64),
          AppDimensions.h16,
          BuildText(text: 'No tasks yet', fontSize: 16),
          AppDimensions.h8,
          BuildText(
            text: isAdmin
                ? 'Create your first task to get started'
                : 'Tasks will appear here when created',
            fontSize: 14,

            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<bool> _showDeleteConfirmation(BuildContext context) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: colorScheme.primaryContainer,
            title: BuildText(
              text: 'Delete Task',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
            content: BuildText(
              text:
                  'Are you sure you want to delete this task? This action cannot be undone.',
              fontSize: 14,
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: BuildText(
                  text: 'Cancel',
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const BuildText(
                  text: 'Delete',
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ) ??
        false;
  }
}
