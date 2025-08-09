// File: pages/create_task/widgets/member_selector_widget.dart

import 'package:event_management/core/constants/build_text.dart';
import 'package:event_management/ui/widgets/app_dimensions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:event_management/providers/create_task_provider.dart';

class MemberSelectorWidget extends StatelessWidget {
  const MemberSelectorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<CreateTaskProvider>(
      builder: (context, provider, child) {
        if (provider.isLoadingEvent) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BuildText(
                text: 'Assign Members',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
              AppDimensions.h8,
              const Center(child: CircularProgressIndicator()),
            ],
          );
        }

        if (provider.currentEvent == null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BuildText(
                text: 'Assign Members',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
              AppDimensions.h8,
              BuildText(
                text: 'Failed to load event details',
                color: colorScheme.error,
              ),
            ],
          );
        }

        final allParticipants = provider.getAllEventParticipants();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BuildText(
              text: 'Assign Members',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
            AppDimensions.h8,
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 200),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: colorScheme.onSurface.withAlpha(60),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(12),
                color: colorScheme.surface,
              ),
              child: allParticipants.isEmpty
                  ? BuildText(
                      text:
                          'No members available in event: ${provider.currentEvent!.title}',
                      color: colorScheme.onSurface.withAlpha(153),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: allParticipants.length,
                      itemBuilder: (context, index) {
                        final participant = allParticipants[index];
                        final isSelected = provider.isMemberSelected(
                          participant.id,
                        );
                        final isAdmin = provider.isParticipantAdmin(
                          participant.id,
                        );
                        final isMember = provider.isParticipantMember(
                          participant.id,
                        );

                        return CheckboxListTile(
                          title: Row(
                            children: [
                              Expanded(
                                child: BuildText(
                                  text: participant.fullName.toUpperCase(),
                                  fontSize: 16,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              AppDimensions.w8,
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isAdmin
                                      ? colorScheme.primary.withAlpha(20)
                                      : colorScheme.secondary.withAlpha(20),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isAdmin
                                        ? colorScheme.primary.withAlpha(60)
                                        : colorScheme.secondary.withAlpha(60),
                                    width: 1,
                                  ),
                                ),
                                child: BuildText(
                                  text: isAdmin ? 'A' : 'M',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isAdmin
                                      ? colorScheme.primary
                                      : colorScheme.secondary,
                                ),
                              ),
                            ],
                          ),

                          value: isSelected,
                          onChanged: (bool? value) {
                            provider.toggleMemberSelection(participant.id);
                          },
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          activeColor: colorScheme.primary,
                        );
                      },
                    ),
            ),
            if (provider.selectedMembers.isNotEmpty) ...[
              AppDimensions.h8,
              BuildText(
                text: '${provider.selectedMembers.length} member(s) selected',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface.withAlpha(153),
              ),
            ],
          ],
        );
      },
    );
  }
}
