// File: ui/widgets/manage_team/role_selection_widget.dart
import 'package:event_management/ui/widgets/app_dimensions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:event_management/providers/manage_team_provider.dart';
import 'package:event_management/core/constants/build_text.dart';
import 'package:icons_plus/icons_plus.dart';

class RoleSelectionWidget extends StatelessWidget {
  const RoleSelectionWidget({super.key});

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
                    Iconsax.people_outline,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  AppDimensions.w8,
                  BuildText(
                    text: 'Select Role',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ],
              ),
              AppDimensions.h12,
              Row(
                children: [
                  Expanded(
                    child: _RoleOption(
                      title: 'Member',
                      description: 'Can view and complete tasks',
                      value: 'member',
                      icon: Iconsax.user_outline,
                      isSelected: provider.selectedRole == 'member',
                      onTap: () => provider.setSelectedRole('member'),
                    ),
                  ),
                  AppDimensions.w12,
                  Expanded(
                    child: _RoleOption(
                      title: 'Admin',
                      description: 'Can manage event and tasks',
                      value: 'admin',
                      icon: Iconsax.shield_tick_outline,
                      isSelected: provider.selectedRole == 'admin',
                      onTap: () => provider.setSelectedRole('admin'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RoleOption extends StatelessWidget {
  final String title;
  final String description;
  final String value;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleOption({
    required this.title,
    required this.description,
    required this.value,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.space12),
        decoration: BoxDecoration(
          color: isSelected 
              ? colorScheme.primary.withOpacity(0.1)
              : colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(AppDimensions.radius8),
          border: isSelected 
              ? Border.all(color: colorScheme.primary, width: 2)
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.6),
              size: 24,
            ),
            AppDimensions.h8,
            BuildText(
              text: title,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? colorScheme.primary : colorScheme.onSurface,
            ),
            AppDimensions.h4,
            BuildText(
              text: description,
              fontSize: 11,
              color: colorScheme.onSurface.withOpacity(0.6),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}