// File: ui/pages/home_page.dart
import 'package:event_management/ui/pages/home/widget/home_stat_card.dart';
import 'package:event_management/ui/pages/home/widget/performance_card.dart';
import 'package:event_management/ui/widgets/app_dimensions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:event_management/providers/home_provider.dart';
import 'package:event_management/core/constants/build_text.dart';

import 'package:icons_plus/icons_plus.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHomeData();
    });
  }

  void _loadHomeData() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      context.read<HomeProvider>().loadHomeData(currentUser.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Consumer<HomeProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Center(
              child: CircularProgressIndicator(color: colorScheme.primary),
            );
          }

          if (provider.error != null) {
            return _buildErrorState(context, provider);
          }

          final isAdmin = currentUser != null
              ? provider.isUserAdmin(currentUser.uid)
              : false;

          return SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                _loadHomeData();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppDimensions.space16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Header
                    _buildWelcomeHeader(context, currentUser),

                    AppDimensions.h24,

                    // Stats Grid
                    if (isAdmin)
                      _buildAdminStats(context, provider)
                    else
                      _buildMemberStats(
                        context,
                        provider,
                        currentUser?.uid ?? '',
                      ),

                    AppDimensions.h24,

                    // Admin-specific sections
                    if (isAdmin) ...[
                      // Team Performance Section
                      _buildSectionHeader(
                        context,
                        'Team Performance',
                        Iconsax.people_outline,
                        colorScheme.primary,
                      ),
                      AppDimensions.h16,

                      PerformanceCard(
                        title: 'Top Performers',
                        members: provider.topPerformers,
                        cardColor: Colors.green,
                        icon: Iconsax.crown_1_outline,
                        isTopPerformers: true,
                      ),

                      PerformanceCard(
                        title: 'Needs Attention',
                        members: provider.laggingMembers,
                        cardColor: Colors.orange,
                        icon: Iconsax.warning_2_outline,
                        isTopPerformers: false,
                      ),

                      AppDimensions.h24,

                      // Admin Quick Actions
                      _buildSectionHeader(
                        context,
                        'Quick Actions',
                        Iconsax.flash_1_outline,
                        colorScheme.primary,
                      ),
                      AppDimensions.h16,
                      _buildAdminQuickActions(context),
                    ] else ...[
                      // Member-specific sections
                      // My Urgent Tasks
                      _buildSectionHeader(
                        context,
                        'My Urgent Tasks',
                        Iconsax.clock_outline,
                        Colors.orange,
                      ),
                      AppDimensions.h16,
                      _buildUrgentTasks(
                        context,
                        provider,
                        currentUser?.uid ?? '',
                      ),

                      AppDimensions.h24,

                      // My Progress
                      _buildSectionHeader(
                        context,
                        'My Progress',
                        Iconsax.chart_outline,
                        Colors.blue,
                      ),
                      AppDimensions.h16,
                      _buildMyProgressCard(context, provider),
                    ],

                    AppDimensions.h24,

                    // Recent Activity (for both admin and member)
                    _buildSectionHeader(
                      context,
                      'Recent Activity',
                      Iconsax.activity_outline,
                      Colors.purple,
                    ),
                    AppDimensions.h16,
                    _buildRecentActivity(context, provider),

                    // Bottom padding for navigation bar
                    AppDimensions.h24,
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context, User? user) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final timeOfDay = DateTime.now().hour;
    String greeting;

    if (timeOfDay < 12) {
      greeting = 'Good Morning';
    } else if (timeOfDay < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BuildText(
                text: greeting,
                fontSize: 16,
                color: colorScheme.onBackground.withOpacity(0.7),
              ),
              AppDimensions.h4,
              BuildText(
                text: user?.displayName ?? 'Welcome!',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colorScheme.onBackground,
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: _loadHomeData,
          icon: Icon(Iconsax.refresh_outline, color: colorScheme.onBackground),
        ),
      ],
    );
  }

  Widget _buildAdminStats(BuildContext context, HomeProvider provider) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppDimensions.space12,
      mainAxisSpacing: AppDimensions.space12,
      childAspectRatio: 1,
      children: [
        HomeStatCard(
          title: 'Active Events',
          value: provider.totalActiveEvents.toString(),
          icon: Iconsax.calendar_outline,
          color: Colors.blue,
          subtitle: 'ongoing events',
        ),
        HomeStatCard(
          title: 'Active Tasks',
          value: provider.totalActiveTasks.toString(),
          icon: Iconsax.task_square_outline,
          color: Colors.green,
          subtitle: 'pending tasks',
        ),
        HomeStatCard(
          title: 'Overdue Tasks',
          value: provider.totalOverdueTasks.toString(),
          icon: Iconsax.warning_2_outline,
          color: Colors.red,
          subtitle: 'need attention',
        ),
        HomeStatCard(
          title: 'Team Rate',
          value: '${provider.teamCompletionRate.toInt()}%',
          icon: Iconsax.chart_success_outline,
          color: Colors.purple,
          subtitle: 'completion rate',
        ),
      ],
    );
  }

  Widget _buildMemberStats(
    BuildContext context,
    HomeProvider provider,
    String userId,
  ) {
    final urgentTasks = provider.getUrgentTasks(userId);

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppDimensions.space12,
      mainAxisSpacing: AppDimensions.space12,
      childAspectRatio: 1.2,
      children: [
        HomeStatCard(
          title: 'My Events',
          value: provider.myActiveEvents.toString(),
          icon: Iconsax.calendar_1_outline,
          color: Colors.blue,
          subtitle: 'active events',
        ),
        HomeStatCard(
          title: 'Completion Rate',
          value: '${provider.myCompletionRate.toInt()}%',
          icon: Iconsax.chart_success_outline,
          color: Colors.green,
          subtitle: 'my performance',
        ),
        HomeStatCard(
          title: 'Urgent Tasks',
          value: urgentTasks.length.toString(),
          icon: Iconsax.clock_outline,
          color: Colors.orange,
          subtitle: 'need attention',
        ),
        HomeStatCard(
          title: 'This Week',
          value: provider.myCompletedTasksThisWeek.toString(),
          icon: Iconsax.tick_circle_outline,
          color: Colors.purple,
          subtitle: 'completed tasks',
        ),
      ],
    );
  }

  Widget _buildAdminQuickActions(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: colorScheme.onPrimary,
        borderRadius: BorderRadius.circular(AppDimensions.radius12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildQuickActionButton(
              context,
              'Create Event',
              Iconsax.add_circle_outline,
              Colors.blue,
              () {
                // TODO: Navigate to create event
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Navigate to Create Event')),
                );
              },
            ),
          ),
          AppDimensions.w12,
          Expanded(
            child: _buildQuickActionButton(
              context,
              'Create Task',
              Iconsax.task_square_outline,
              Colors.green,
              () {
                // TODO: Navigate to create task
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Navigate to Create Task')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.space12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppDimensions.radius8),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            AppDimensions.h8,
            BuildText(
              text: title,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUrgentTasks(
    BuildContext context,
    HomeProvider provider,
    String userId,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final urgentTasks = provider.getUrgentTasks(userId);

    if (urgentTasks.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppDimensions.space24),
        decoration: BoxDecoration(
          color: colorScheme.onPrimary,
          borderRadius: BorderRadius.circular(AppDimensions.radius12),
        ),
        child: Column(
          children: [
            Icon(
              Iconsax.tick_circle_outline,
              size: 48,
              color: Colors.green.withOpacity(0.5),
            ),
            AppDimensions.h12,
            BuildText(
              text: 'Great job!',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
            AppDimensions.h4,
            BuildText(
              text: 'No urgent tasks at the moment',
              fontSize: 14,
              color: colorScheme.onSurface.withOpacity(0.7),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.onPrimary,
        borderRadius: BorderRadius.circular(AppDimensions.radius12),
      ),
      child: Column(
        children: urgentTasks.asMap().entries.map((entry) {
          final index = entry.key;
          final task = entry.value;
          final isLast = index == urgentTasks.length - 1;

          return _buildUrgentTaskItem(context, task, !isLast);
        }).toList(),
      ),
    );
  }

  Widget _buildUrgentTaskItem(
    BuildContext context,
    dynamic task,
    bool showDivider,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(AppDimensions.space12),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                task.isOverdue
                    ? Iconsax.warning_2_outline
                    : Iconsax.clock_outline,
                color: task.isOverdue ? Colors.red : Colors.orange,
                size: 16,
              ),
              AppDimensions.w8,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BuildText(
                      text: task.title,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    AppDimensions.h4,
                    BuildText(
                      text: _getDeadlineText(task.deadline, task.isOverdue),
                      fontSize: 12,
                      color: task.isOverdue ? Colors.red : Colors.orange,
                    ),
                  ],
                ),
              ),
              Icon(
                Iconsax.arrow_right_3_outline,
                color: colorScheme.onSurface.withOpacity(0.3),
                size: 16,
              ),
            ],
          ),
          if (showDivider) ...[
            AppDimensions.h12,
            Divider(color: colorScheme.outline.withOpacity(0.2), height: 1),
          ],
        ],
      ),
    );
  }

  Widget _buildMyProgressCard(BuildContext context, HomeProvider provider) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.withOpacity(0.1),
            Colors.purple.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radius12),
        border: Border.all(color: Colors.blue.withOpacity(0.2), width: 1),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              BuildText(
                text: 'My Performance',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
              BuildText(
                text: '${provider.myCompletionRate.toInt()}%',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ],
          ),
          AppDimensions.h16,
          LinearProgressIndicator(
            value: provider.myCompletionRate / 100,
            backgroundColor: colorScheme.onSurface.withOpacity(0.1),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            minHeight: 8,
          ),
          AppDimensions.h12,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              BuildText(
                text: 'Tasks completed this week',
                fontSize: 12,
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
              BuildText(
                text: provider.myCompletedTasksThisWeek.toString(),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context, HomeProvider provider) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final activities = provider.getRecentActivity();

    if (activities.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppDimensions.space24),
        decoration: BoxDecoration(
          color: colorScheme.onPrimary,
          borderRadius: BorderRadius.circular(AppDimensions.radius12),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Iconsax.activity_outline,
                size: 48,
                color: colorScheme.onSurface.withOpacity(0.3),
              ),
              AppDimensions.h12,
              BuildText(
                text: 'No recent activity',
                fontSize: 14,
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.onPrimary,
        borderRadius: BorderRadius.circular(AppDimensions.radius12),
      ),
      child: Column(
        children: activities.asMap().entries.map((entry) {
          final index = entry.key;
          final activity = entry.value;
          final isLast = index == activities.length - 1;

          return _buildActivityItem(context, activity, !isLast);
        }).toList(),
      ),
    );
  }

  Widget _buildActivityItem(
    BuildContext context,
    dynamic activity,
    bool showDivider,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(AppDimensions.space12),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.space8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radius8),
                ),
                child: Icon(
                  Iconsax.tick_circle_outline,
                  color: Colors.green,
                  size: 16,
                ),
              ),
              AppDimensions.w12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BuildText(
                      text: activity.message,
                      fontSize: 14,
                      color: colorScheme.onSurface,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    AppDimensions.h4,
                    BuildText(
                      text: _getTimeAgo(activity.timestamp),
                      fontSize: 12,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (showDivider) ...[
            AppDimensions.h12,
            Divider(color: colorScheme.outline.withOpacity(0.2), height: 1),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        AppDimensions.w8,
        BuildText(
          text: title,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, HomeProvider provider) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.space32),
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
              text: 'Error loading data',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colorScheme.onBackground,
            ),
            AppDimensions.h8,
            BuildText(
              text: provider.error!,
              fontSize: 14,
              color: colorScheme.onBackground.withOpacity(0.7),
              textAlign: TextAlign.center,
            ),
            AppDimensions.h16,
            ElevatedButton(
              onPressed: _loadHomeData,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  String _getDeadlineText(DateTime deadline, bool isOverdue) {
    final now = DateTime.now();
    final difference = deadline.difference(now);

    if (isOverdue) {
      final overdue = now.difference(deadline);
      if (overdue.inDays > 0) {
        return '${overdue.inDays}d overdue';
      } else if (overdue.inHours > 0) {
        return '${overdue.inHours}h overdue';
      } else {
        return '${overdue.inMinutes}m overdue';
      }
    } else {
      if (difference.inDays > 0) {
        return 'Due in ${difference.inDays}d';
      } else if (difference.inHours > 0) {
        return 'Due in ${difference.inHours}h';
      } else {
        return 'Due in ${difference.inMinutes}m';
      }
    }
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
