// File: ui/widgets/manage_team/user_search_widget.dart
import 'package:event_management/ui/widgets/app_dimensions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:event_management/providers/manage_team_provider.dart';

import 'package:event_management/core/constants/build_text.dart';
import 'package:icons_plus/icons_plus.dart';

class UserSearchWidget extends StatelessWidget {
  const UserSearchWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<ManageTeamProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.all(AppDimensions.space16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radius12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Iconsax.search_normal_outline,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  AppDimensions.w8,
                  BuildText(
                    text: 'Search Users',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ],
              ),
              AppDimensions.h12,
              TextField(
                controller: provider.searchController,
                onChanged: (value) {
                  provider.searchUsers(value);
                },
                decoration: InputDecoration(
                  hintText: 'Search by name or email...',
                  hintStyle: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.5),
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: colorScheme.primaryContainer,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radius8),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: Icon(
                    Iconsax.search_normal_outline,
                    color: colorScheme.onSurface.withOpacity(0.5),
                    size: 20,
                  ),
                  suffixIcon: provider.searchController.text.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            provider.clearSearch();
                          },
                          icon: Icon(
                            Iconsax.close_circle_outline,
                            color: colorScheme.onSurface.withOpacity(0.5),
                            size: 20,
                          ),
                        )
                      : null,
                ),
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}