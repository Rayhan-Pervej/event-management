// File: pages/create_task/widgets/task_form_fields_widget.dart
import 'package:event_management/core/constants/build_text.dart';
import 'package:event_management/ui/widgets/app_dimensions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:event_management/providers/create_task_provider.dart';
import 'package:event_management/ui/widgets/custom_input.dart';
import 'package:event_management/ui/widgets/custom_date_input.dart';
import 'package:event_management/ui/widgets/custom_time_input.dart';
import 'package:event_management/models/task_model.dart';

class TaskFormFieldsWidget extends StatelessWidget {
  const TaskFormFieldsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Consumer<CreateTaskProvider>(
      builder: (context, provider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomInput(
              controller: provider.taskNameController,
              fieldLabel: 'Task Name',
              hintText: 'Enter task name',
              validation: true,
              errorMessage: 'Please enter task name',
              validatorClass: provider.validateTaskName,
              textInputAction: TextInputAction.next,
            ),
            AppDimensions.h16,
            CustomInput(
              controller: provider.descriptionController,
              fieldLabel: 'Description',
              hintText: 'Enter task description',
              validation: true,
              errorMessage: 'Please enter description',
              validatorClass: provider.validateDescription,
              textInputAction: TextInputAction.done,
              inputType: TextInputType.multiline,
              maxLines: 4,
              minLines: 3,
            ),
            AppDimensions.h16,

            // Recurring Task Toggle
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    provider.isRecurring ? Icons.repeat : Icons.event,
                    color: provider.isRecurring ? Colors.purple : Colors.grey,
                  ),
                  AppDimensions.w12,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recurring Task',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          provider.isRecurring
                              ? 'This task repeats on schedule'
                              : 'This is a one-time task',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: provider.isRecurring,
                    onChanged: provider.setIsRecurring,
                    activeColor: colorScheme.secondary,
                  ),
                ],
              ),
            ),
            AppDimensions.h16,

            // Conditional: Deadline fields OR Recurrence type
            if (provider.isRecurring) ...[
              // Recurrence Type Selector
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.repeat, color: Colors.purple),
                        AppDimensions.w8,
                        BuildText(
                          text: 'Recurrence Type',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ],
                    ),
                    AppDimensions.h12,
                    Wrap(
                      spacing: 8,
                      children: RecurrenceType.values
                          .where((type) => type != RecurrenceType.none)
                          .map((type) {
                            final isSelected =
                                provider.selectedRecurrenceType == type;
                            return GestureDetector(
                              onTap: () =>
                                  provider.setSelectedRecurrenceType(type),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? colorScheme.secondary
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected
                                        ? colorScheme.secondary
                                        : colorScheme.onSurface,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: BuildText(
                                  fontSize: 14,
                                  text: provider.getRecurrenceDisplayName(type),
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            );
                          })
                          .toList(),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Deadline Date and Time (for single tasks)
              Row(
                children: [
                  Expanded(
                    child: CustomDateInput(
                      selectedDate: provider.selectedDate,
                      fieldLabel: 'Deadline Date',
                      hintText: 'Select date',
                      validation: false,
                      errorMessage: '',
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      onChanged: provider.setSelectedDate,
                    ),
                  ),
                  AppDimensions.w12,
                  Expanded(
                    child: CustomTimeInput(
                      selectedTime: provider.selectedTime,
                      fieldLabel: 'Deadline Time',
                      hintText: 'Select time',
                      validation: false,
                      errorMessage: '',
                      onChanged: provider.setSelectedTime,
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}
