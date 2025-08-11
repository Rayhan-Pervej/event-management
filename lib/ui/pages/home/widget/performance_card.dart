// File: ui/widgets/performance_card.dart
import 'package:event_management/models/member_performance.dart';
import 'package:event_management/ui/widgets/app_dimensions.dart';
import 'package:flutter/material.dart';
import 'package:event_management/core/constants/build_text.dart';

class PerformanceCard extends StatelessWidget {
  final String title;
  final List<MemberPerformance> members;
  final Color cardColor;
  final IconData icon;
  final bool isTopPerformers;

  const PerformanceCard({
    super.key,
    required this.title,
    required this.members,
    required this.cardColor,
    required this.icon,
    required this.isTopPerformers,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (members.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.space16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppDimensions.radius12),
        border: Border.all(color: cardColor.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppDimensions.space16),
            decoration: BoxDecoration(
              color: cardColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppDimensions.radius12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: cardColor, size: 20),
                AppDimensions.w8,
                Expanded(
                  child: BuildText(
                    text: title,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: cardColor,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.space8,
                    vertical: AppDimensions.space4,
                  ),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(AppDimensions.radius8),
                  ),
                  child: BuildText(
                    text: members.length.toString(),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Members List
          Padding(
            padding: const EdgeInsets.all(AppDimensions.space16),
            child: Column(
              children: members.asMap().entries.map((entry) {
                final index = entry.key;
                final member = entry.value;

                return _buildMemberItem(
                  context,
                  member,
                  index + 1,
                  index < members.length - 1,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberItem(
    BuildContext context,
    MemberPerformance member,
    int rank,
    bool showDivider,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Row(
          children: [
            // Rank Badge
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _getRankColor(rank).withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radius8),
                border: Border.all(
                  color: _getRankColor(rank).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Center(
                child: BuildText(
                  text: rank.toString(),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _getRankColor(rank),
                ),
              ),
            ),

            AppDimensions.w12,

            // Member Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BuildText(
                    text: member.fullName,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                  AppDimensions.h4,
                  Row(
                    children: [
                      _buildStatChip(
                        context,
                        '${member.completionRate.toInt()}%',
                        'completion',
                        isTopPerformers ? Colors.green : Colors.orange,
                      ),
                      AppDimensions.w8,
                      _buildStatChip(
                        context,
                        '${member.totalTasks}',
                        'tasks',
                        Colors.blue,
                      ),
                      if (!isTopPerformers && member.overdueTasks > 0) ...[
                        AppDimensions.w8,
                        _buildStatChip(
                          context,
                          '${member.overdueTasks}',
                          'overdue',
                          Colors.red,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Performance Score
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                BuildText(
                  text: '${member.performanceScore.toInt()}',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: cardColor,
                ),
                BuildText(
                  text: 'score',
                  fontSize: 10,
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ],
            ),
          ],
        ),

        if (showDivider) ...[
          AppDimensions.h12,
          Divider(color: colorScheme.outline.withOpacity(0.2), height: 1),
          AppDimensions.h12,
        ],
      ],
    );
  }

  Widget _buildStatChip(
    BuildContext context,
    String value,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space8,
        vertical: AppDimensions.space2,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radius4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          BuildText(
            text: value,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color,
          ),
          AppDimensions.w4,
          BuildText(text: label, fontSize: 9, color: color.withOpacity(0.8)),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return isTopPerformers ? Colors.amber : Colors.red;
      case 2:
        return isTopPerformers ? Colors.grey : Colors.orange;
      case 3:
        return isTopPerformers ? Colors.brown : Colors.yellow.shade700;
      default:
        return Colors.grey;
    }
  }
}
