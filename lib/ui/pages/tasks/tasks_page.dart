// File: ui/pages/user_tasks_page.dart
import 'package:event_management/ui/pages/tasks/widgets/task_section.dart';
import 'package:event_management/ui/widgets/app_dimensions.dart';
import 'package:event_management/ui/widgets/default_appbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:event_management/providers/user_tasks_provider.dart';
import 'package:event_management/core/constants/build_text.dart';

import 'package:event_management/service/notification_manager.dart';
import 'package:icons_plus/icons_plus.dart';

class UserTasksPage extends StatefulWidget {
  const UserTasksPage({super.key});

  @override
  State<UserTasksPage> createState() => _UserTasksPageState();
}

class _UserTasksPageState extends State<UserTasksPage> {
  String _sortBy = 'deadline'; // 'deadline' or 'priority'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTasks();
    });
  }

  void _loadTasks() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      context.read<UserTasksProvider>().loadUserTasks(currentUser.uid);
    }
  }

  Future<void> _handleTaskToggle(String taskId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final provider = context.read<UserTasksProvider>();
    final task = provider.allTasks.firstWhere((t) => t.id == taskId);
    final isCompleted = task.isCompletedByUser(currentUser.uid);

    bool success;
    if (isCompleted) {
      success = await provider.uncompleteTask(taskId, currentUser.uid);
    } else {
      success = await provider.completeTask(taskId, currentUser.uid);
    }

    if (success) {
      // Refresh notification listeners to ensure real-time updates
      await NotificationManager().refreshListeners();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isCompleted ? 'Task marked as incomplete' : 'Task completed!',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update task'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: DefaultAppBar(
        title: 'My Tasks',
        isShowBackButton: false,

        actions: [
          // Sort Button
          PopupMenuButton<String>(
            icon: Icon(Iconsax.sort_outline, color: colorScheme.onBackground),
            onSelected: (value) {
              setState(() {
                _sortBy = value;
              });
              final provider = context.read<UserTasksProvider>();
              if (value == 'priority') {
                provider.sortTasksByPriority();
              } else {
                provider.sortTasksByDeadline();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'deadline',
                child: Row(
                  children: [
                    Icon(
                      Iconsax.clock_outline,
                      color: _sortBy == 'deadline' ? colorScheme.primary : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Sort by Deadline',
                      style: TextStyle(
                        color: _sortBy == 'deadline'
                            ? colorScheme.primary
                            : null,
                        fontWeight: _sortBy == 'deadline'
                            ? FontWeight.w600
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'priority',
                child: Row(
                  children: [
                    Icon(
                      Iconsax.flag_outline,
                      color: _sortBy == 'priority' ? colorScheme.primary : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Sort by Priority',
                      style: TextStyle(
                        color: _sortBy == 'priority'
                            ? colorScheme.primary
                            : null,
                        fontWeight: _sortBy == 'priority'
                            ? FontWeight.w600
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // // Refresh Button
          // IconButton(
          //   onPressed: _loadTasks,
          //   icon: Icon(
          //     Iconsax.refresh_outline,
          //     color: colorScheme.onBackground,
          //   ),
          // ),
        ],
      ),
      body: Consumer<UserTasksProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Center(
              child: CircularProgressIndicator(color: colorScheme.primary),
            );
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Iconsax.info_circle_outline,
                    size: 64,
                    color: Colors.red.withOpacity(0.5),
                  ),
                  AppDimensions.h16,
                  BuildText(
                    text: 'Error loading tasks',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onBackground,
                  ),
                  AppDimensions.h8,
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: BuildText(
                      text: provider.error!,
                      fontSize: 14,
                      color: colorScheme.onBackground.withOpacity(0.7),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  AppDimensions.h16,
                  ElevatedButton(
                    onPressed: _loadTasks,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.allTasks.isEmpty) {
            return _buildEmptyState(context);
          }

          return RefreshIndicator(
            onRefresh: () async {
              _loadTasks();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppDimensions.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Statistics Cards
                  _buildStatisticsRow(context, provider),

                  AppDimensions.h24,

                  // Task Sections
                  TaskSection(
                    title: 'Overdue Tasks',
                    tasks: provider.overdueTasks,
                    eventsMap: provider.eventsMap,
                    currentUserId: FirebaseAuth.instance.currentUser?.uid ?? '',
                    onTaskToggle: _handleTaskToggle,
                    headerColor: Colors.red,
                    headerIcon: Iconsax.warning_2_outline,
                    initiallyExpanded: true,
                  ),

                  TaskSection(
                    title: 'Due Today',
                    tasks: provider.dueTodayTasks,
                    eventsMap: provider.eventsMap,
                    currentUserId: FirebaseAuth.instance.currentUser?.uid ?? '',
                    onTaskToggle: _handleTaskToggle,
                    headerColor: Colors.orange,
                    headerIcon: Iconsax.clock_outline,
                    initiallyExpanded: true,
                  ),

                  TaskSection(
                    title: 'Upcoming Tasks',
                    tasks: provider.upcomingTasks,
                    eventsMap: provider.eventsMap,
                    currentUserId: FirebaseAuth.instance.currentUser?.uid ?? '',
                    onTaskToggle: _handleTaskToggle,
                    headerColor: Colors.blue,
                    headerIcon: Iconsax.calendar_outline,
                    initiallyExpanded: true,
                  ),

                  TaskSection(
                    title: 'Completed Tasks',
                    tasks: provider.completedTasks,
                    eventsMap: provider.eventsMap,
                    currentUserId: FirebaseAuth.instance.currentUser?.uid ?? '',
                    onTaskToggle: _handleTaskToggle,
                    headerColor: Colors.green,
                    headerIcon: Iconsax.tick_circle_outline,
                    initiallyExpanded: false,
                  ),

                  // Bottom padding for navigation bar
                  AppDimensions.h24,
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatisticsRow(BuildContext context, UserTasksProvider provider) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            title: 'Total',
            count: provider.totalTasks,
            color: colorScheme.primary,
            icon: Iconsax.task_square_outline,
          ),
        ),
        AppDimensions.w12,
        Expanded(
          child: _buildStatCard(
            context,
            title: 'Pending',
            count: provider.pendingCount,
            color: Colors.orange,
            icon: Iconsax.clock_outline,
          ),
        ),
        AppDimensions.w12,
        Expanded(
          child: _buildStatCard(
            context,
            title: 'Overdue',
            count: provider.overdueCount,
            color: Colors.red,
            icon: Iconsax.warning_2_outline,
          ),
        ),
        AppDimensions.w12,
        Expanded(
          child: _buildStatCard(
            context,
            title: 'Done',
            count: provider.completedCount,
            color: Colors.green,
            icon: Iconsax.tick_circle_outline,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space8,
        vertical: AppDimensions.space12,
      ),
      decoration: BoxDecoration(
        color: colorScheme.onPrimary,
        borderRadius: BorderRadius.circular(AppDimensions.radius12),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          AppDimensions.h8,
          BuildText(
            text: count.toString(),
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          AppDimensions.h4,
          BuildText(
            text: title,
            fontSize: 12,
            color: colorScheme.onSurface.withOpacity(0.7),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.space32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.task_square_outline,
              size: 80,
              color: colorScheme.onBackground.withOpacity(0.3),
            ),
            AppDimensions.h24,
            BuildText(
              text: 'No tasks assigned',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: colorScheme.onBackground,
            ),
            AppDimensions.h8,
            BuildText(
              text:
                  'Tasks assigned to you will appear here.\nCheck back later or ask your event admin to assign you some tasks.',
              fontSize: 14,
              color: colorScheme.onBackground.withOpacity(0.7),
              textAlign: TextAlign.center,
            ),
            AppDimensions.h24,
            ElevatedButton.icon(
              onPressed: _loadTasks,
              icon: const Icon(Iconsax.refresh_outline),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
