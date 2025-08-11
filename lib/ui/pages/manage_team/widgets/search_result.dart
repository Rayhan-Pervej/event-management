// File: ui/widgets/manage_team/search_results_widget.dart
import 'package:event_management/ui/widgets/app_dimensions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:event_management/providers/manage_team_provider.dart';
import 'package:event_management/models/user.dart';
import 'package:event_management/core/constants/build_text.dart';
import 'package:icons_plus/icons_plus.dart';

class SearchResultsWidget extends StatelessWidget {
  const SearchResultsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<ManageTeamProvider>(
      builder: (context, provider, child) {
        if (provider.isSearching) {
          return Center(
            child: CircularProgressIndicator(color: colorScheme.primary),
          );
        }

        if (provider.searchController.text.isEmpty) {
          return _buildEmptySearchState(context);
        }

        if (provider.searchResults.isEmpty) {
          return _buildNoResultsState(context);
        }

        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radius12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppDimensions.space16),
                child: Row(
                  children: [
                    Icon(
                      Iconsax.people_outline,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                    AppDimensions.w8,
                    BuildText(
                      text: 'Search Results',
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
                        text: provider.searchResults.length.toString(),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(
                    left: AppDimensions.space16,
                    right: AppDimensions.space16,
                    bottom: AppDimensions.space16,
                  ),
                  itemCount: provider.searchResults.length,
                  itemBuilder: (context, index) {
                    final user = provider.searchResults[index];
                    return _UserCard(user: user);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptySearchState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.search_normal_outline,
            size: 64,
            color: colorScheme.onSurface.withOpacity(0.3),
          ),
          AppDimensions.h16,
          BuildText(
            text: 'Search for users to add',
            fontSize: 16,
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
          AppDimensions.h8,
          BuildText(
            text: 'Type a name or email to get started',
            fontSize: 14,
            color: colorScheme.onSurface.withOpacity(0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.search_status_outline,
            size: 64,
            color: colorScheme.onSurface.withOpacity(0.3),
          ),
          AppDimensions.h16,
          BuildText(
            text: 'No users found',
            fontSize: 16,
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
          AppDimensions.h8,
          BuildText(
            text: 'Try searching with different keywords',
            fontSize: 14,
            color: colorScheme.onSurface.withOpacity(0.5),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserModel user;

  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<ManageTeamProvider>(
      builder: (context, provider, child) {
        final isSelected = provider.isUserSelected(user.uid);

        return Container(
          margin: const EdgeInsets.only(bottom: AppDimensions.space8),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primary.withOpacity(0.1)
                : colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(AppDimensions.radius8),
            border: isSelected
                ? Border.all(color: colorScheme.primary, width: 1)
                : null,
          ),
          child: ListTile(
            leading: CircleAvatar(
              radius: 20,
              backgroundColor: colorScheme.primary.withOpacity(0.1),
              child: BuildText(
                text: _getInitials(user.fullName),
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
            title: BuildText(
              text: user.fullName,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
            subtitle: BuildText(
              text: user.email,
              fontSize: 12,
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
            trailing: Checkbox(
              value: isSelected,
              onChanged: (value) => provider.toggleUserSelection(user),
              activeColor: colorScheme.primary,
            ),
            onTap: () => provider.toggleUserSelection(user),
          ),
        );
      },
    );
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
