// File: ui/widgets/manage_team/selected_users_widget.dart
import 'package:event_management/ui/widgets/app_dimensions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:event_management/providers/manage_team_provider.dart';
import 'package:event_management/ui/widgets/default_button.dart';
import 'package:event_management/core/constants/build_text.dart';
import 'package:icons_plus/icons_plus.dart';

class SelectedUsersWidget extends StatelessWidget {
  final VoidCallback? onMembersAdded;

  const SelectedUsersWidget({
    super.key,
    this.onMembersAdded,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<ManageTeamProvider>(
      builder: (context, provider, child) {
        final users = provider.selectedUsers;
        final count = provider.selectedUsersCount;

        return Container(
          padding: const EdgeInsets.all(AppDimensions.space16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radius12),
            border: Border.all(color: colorScheme.primary, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Iconsax.user_tick_outline,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  AppDimensions.w8,
                  BuildText(
                    text: 'Selected Users',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                  AppDimensions.w8,
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.space8,
                      vertical: AppDimensions.space4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radius8,
                      ),
                    ),
                    child: BuildText(
                      text: count.toString(),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => provider.clearSelectedUsers(),
                    icon: Icon(
                      Iconsax.close_circle_outline,
                      color: colorScheme.onSurface.withOpacity(0.5),
                      size: 20,
                    ),
                  ),
                ],
              ),

              AppDimensions.h12,

              // Selected users list
              if (count <= 3) ...[
                // Show all users if 3 or less
                ...users.map((user) => _buildUserRow(context, user)),
              ] else ...[
                // Show first 2 and "X more" if more than 3
                ...users.take(2).map((user) => _buildUserRow(context, user)),
                AppDimensions.h8,
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.space12,
                    vertical: AppDimensions.space8,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppDimensions.radius8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Iconsax.people_outline,
                        size: 16,
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                      AppDimensions.w8,
                      BuildText(
                        text: '+ ${count - 2} more users selected',
                        fontSize: 12,
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ],
                  ),
                ),
              ],

              AppDimensions.h16,

              DefaultButton(
                text: provider.isLoading
                    ? 'Adding...'
                    : 'Add $count ${count == 1 ? 'User' : 'Users'} as ${provider.selectedRole.toUpperCase()}',
                press: () => _addMembers(context, provider),
                isLoading: provider.isLoading,
                bgColor: colorScheme.primary,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUserRow(BuildContext context, user) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.space8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: colorScheme.primary.withOpacity(0.1),
            child: BuildText(
              text: _getInitials(user.fullName),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
            ),
          ),
          AppDimensions.w12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BuildText(
                  text: user.fullName,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
                BuildText(
                  text: user.email,
                  fontSize: 11,
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addMembers(
    BuildContext context,
    ManageTeamProvider provider,
  ) async {
    final count = provider.selectedUsersCount;
    final success = await provider.addSelectedMembers();

    if (success && context.mounted) {
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$count ${count == 1 ? 'user' : 'users'} added as ${provider.selectedRole}',
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Call the callback to indicate members were added
      if (onMembersAdded != null) {
        onMembersAdded!();
      }

      // Navigate back to event details page with result indicating changes were made
      Navigator.pop(context, true);
    } else if (provider.errorMessage != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getInitials(String name) {
    List<String> nameParts = name.split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts.first[0]}${nameParts.last[0]}'.toUpperCase();
    } else if (nameParts.isNotEmpty) {
      return nameParts.first[0].toUpperCase();
    }
    return 'U';
  }
}