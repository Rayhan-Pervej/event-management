// File: ui/widgets/event_members_tab.dart
import 'package:event_management/providers/event_details_provider.dart';
import 'package:event_management/providers/events_provider.dart';
import 'package:event_management/ui/pages/manage_team/manage_team.dart';
import 'package:event_management/ui/widgets/app_dimensions.dart';
import 'package:flutter/material.dart';
import 'package:event_management/models/event_model.dart';

import 'package:event_management/core/constants/build_text.dart';
import 'package:event_management/ui/widgets/default_button.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:provider/provider.dart';

class EventMembersTab extends StatelessWidget {
  final EventModel event;
  final bool isAdmin;
  final String currentUserId;
  final VoidCallback? onRefresh;

  const EventMembersTab({
    super.key,
    required this.event,
    required this.isAdmin,
    required this.currentUserId,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<EventDetailsProvider>(
      builder: (context, provider, child) {
        // Use the provider's event if available, otherwise fall back to the passed event
        final currentEvent = provider.event ?? event;

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppDimensions.space16),
          child: Column(
            children: [
              // Manage Team Button (Admin only)
              if (isAdmin) ...[
                DefaultButton(
                  text: 'Manage Team',
                  press: () async {
                    final result = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ManageTeamPage(event: currentEvent),
                      ),
                    );

                    if (result == true) {
                      if (onRefresh != null) {
                        onRefresh!();
                      }
                    }
                  },
                  bgColor: colorScheme.primary,
                ),
                AppDimensions.h16,
              ],

              // Members List - Use currentEvent instead of event
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Admins Section
                  if (currentEvent.admins.isNotEmpty) ...[
                    _buildSectionHeader(
                      context,
                      title: 'Admins',
                      count: currentEvent.admins.length,
                      icon: Iconsax.shield_tick_outline,
                    ),
                    AppDimensions.h12,
                    ...currentEvent.admins.map(
                      (admin) => _buildMemberCard(
                        context,
                        participant: admin,
                        isAdminRole: true,
                        isCurrentUser: admin.id == currentUserId,
                        currentEvent: currentEvent,
                      ),
                    ),
                    AppDimensions.h24,
                  ],

                  // Members Section
                  if (currentEvent.members.isNotEmpty) ...[
                    _buildSectionHeader(
                      context,
                      title: 'Members',
                      count: currentEvent.members.length,
                      icon: Iconsax.people_outline,
                    ),
                    AppDimensions.h12,
                    ...currentEvent.members.map(
                      (member) => _buildMemberCard(
                        context,
                        participant: member,
                        isAdminRole: false,
                        isCurrentUser: member.id == currentUserId,
                        currentEvent: currentEvent,
                      ),
                    ),
                  ],

                  // Empty State
                  if (currentEvent.admins.isEmpty &&
                      currentEvent.members.isEmpty)
                    SizedBox(
                      height: 300,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Iconsax.people_outline,
                              size: 64,
                              color: colorScheme.onSurface.withOpacity(0.3),
                            ),
                            AppDimensions.h16,
                            BuildText(
                              text: 'No team members yet',
                              fontSize: 16,
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ],
                        ),
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

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required int count,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(icon, color: colorScheme.primary, size: 20),
        AppDimensions.w8,
        BuildText(
          text: title,
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
            borderRadius: BorderRadius.circular(AppDimensions.radius8),
          ),
          child: BuildText(
            text: count.toString(),
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildMemberCard(
    BuildContext context, {
    required EventParticipant participant,
    required bool isAdminRole,
    required bool isCurrentUser,
    required EventModel currentEvent, // ✅ Add this parameter
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.space8),
      padding: const EdgeInsets.all(AppDimensions.space12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radius8),
        border: isCurrentUser
            ? Border.all(color: colorScheme.primary, width: 1)
            : null,
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: isAdminRole
                ? colorScheme.primary.withOpacity(0.1)
                : colorScheme.secondary.withOpacity(0.1),
            child: BuildText(
              text: _getInitials(participant.fullName),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isAdminRole ? colorScheme.primary : colorScheme.secondary,
            ),
          ),

          AppDimensions.w12,

          // Name and Role
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: BuildText(
                        text: participant.fullName,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    if (isCurrentUser) ...[
                      AppDimensions.w8,
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.space8,
                          vertical: AppDimensions.space2,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radius4,
                          ),
                        ),
                        child: BuildText(
                          text: 'You',
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ],
                ),
                AppDimensions.h4,
                Row(
                  children: [
                    Icon(
                      isAdminRole
                          ? Iconsax.shield_tick_outline
                          : Iconsax.user_outline,
                      size: 12,
                      color: isAdminRole
                          ? colorScheme.primary
                          : colorScheme.secondary,
                    ),
                    AppDimensions.w4,
                    BuildText(
                      text: isAdminRole ? 'Admin' : 'Member',
                      fontSize: 12,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Actions (for admins only)
          if (isAdmin && !isCurrentUser) ...[
            IconButton(
              onPressed: () {
                _showMemberActions(
                  context,
                  participant,
                  isAdminRole,
                  currentEvent,
                ); // ✅ Pass currentEvent
              },
              icon: Icon(
                Iconsax.more_outline,
                color: colorScheme.onSurface.withOpacity(0.5),
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showMemberActions(
    BuildContext context,
    EventParticipant participant,
    bool isAdminRole,
    EventModel currentEvent, // ✅ Add this parameter
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppDimensions.space16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BuildText(
              text: participant.fullName,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
            AppDimensions.h16,
            if (!isAdminRole)
              ListTile(
                leading: Icon(
                  Iconsax.shield_tick_outline,
                  color: colorScheme.primary,
                ),
                title: const BuildText(text: 'Promote to Admin'),
                onTap: () async {
                  Navigator.pop(context);
                  await _promoteToAdmin(
                    context,
                    participant.id,
                  ); // Keep existing method
                },
              ),
            if (isAdminRole)
              ListTile(
                leading: Icon(
                  Iconsax.user_outline,
                  color: colorScheme.secondary,
                ),
                title: const BuildText(text: 'Demote to Member'),
                onTap: () async {
                  Navigator.pop(context);
                  await _demoteToMember(
                    context,
                    participant.id,
                  ); // Keep existing method signature
                },
              ),
            ListTile(
              leading: Icon(Iconsax.trash_outline, color: colorScheme.error),
              title: const BuildText(text: 'Remove from Event'),
              onTap: () async {
                final provider = Provider.of<EventsProvider>(
                  context,
                  listen: false,
                );
                Navigator.pop(context);

                bool confirm = await _showRemoveConfirmation(
                  context,
                  participant.fullName,
                );

                if (confirm) {
                  await provider.removeFromEvent(
                    currentEvent.id,
                    participant.id,
                  ); // ✅ Use currentEvent
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _promoteToAdmin(BuildContext context, String memberId) async {
    if (!context.mounted) return;

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final provider = Provider.of<EventDetailsProvider>(
        context,
        listen: false,
      );

      await provider.promoteToAdmin(event.id, memberId);

      if (context.mounted) {
        Navigator.of(context).pop(); // Dismiss loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Member promoted to admin successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Force refresh the data
        if (onRefresh != null) {
          onRefresh!();
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Dismiss loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to promote member: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // In EventMembersTab - _demoteToMember method
Future<void> _demoteToMember(BuildContext context, String adminId) async {
  if (!context.mounted) return;


  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(child: CircularProgressIndicator()),
  );

  try {
    final provider = Provider.of<EventDetailsProvider>(
      context,
      listen: false,
    );

    final currentEventId = provider.event?.id ?? event.id;
    
   

    await provider.demoteToMember(currentEventId, adminId);

  

    if (context.mounted) {
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Admin demoted to member successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Force refresh the parent widget
      if (onRefresh != null) {
      
        onRefresh!();
      }

     
    }
  } catch (e) {
   
    
    if (context.mounted) {
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to demote admin: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
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

  Future<bool> _showRemoveConfirmation(
    BuildContext context,
    String memberName,
  ) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: colorScheme.surface,
            title: BuildText(
              text: 'Remove Member',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
            content: BuildText(
              text:
                  'Are you sure you want to remove $memberName from this event?',
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
                  text: 'Remove',
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
