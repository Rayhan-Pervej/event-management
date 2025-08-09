// File: pages/create_task/widgets/priority_selector_widget.dart
import 'package:event_management/ui/widgets/app_dimensions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:event_management/providers/create_task_provider.dart';

class PrioritySelectorWidget extends StatelessWidget {
  const PrioritySelectorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<CreateTaskProvider>(
      builder: (context, provider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Priority',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            AppDimensions.h8,
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(
                  color: colorScheme.onSurface.withAlpha(60),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(12),
                color: colorScheme.surface,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: provider.selectedPriority,
                  isExpanded: true,
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      provider.setSelectedPriority(newValue);
                    }
                  },
                  items: provider.priorities.map<DropdownMenuItem<String>>(
                    (String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: provider.getPriorityColor(value),
                                shape: BoxShape.circle,
                              ),
                            ),
                            AppDimensions.w8,
                            Text(provider.getPriorityDisplayName(value)),
                          ],
                        ),
                      );
                    },
                  ).toList(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}