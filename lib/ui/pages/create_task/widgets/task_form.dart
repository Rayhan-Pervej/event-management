// File: pages/create_task/widgets/task_form_fields_widget.dart
import 'package:event_management/ui/widgets/app_dimensions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:event_management/providers/create_task_provider.dart';
import 'package:event_management/ui/widgets/custom_input.dart';
import 'package:event_management/ui/widgets/custom_date_input.dart';
import 'package:event_management/ui/widgets/custom_time_input.dart';

class TaskFormFieldsWidget extends StatelessWidget {
  const TaskFormFieldsWidget({super.key});

  @override
  Widget build(BuildContext context) {
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
              textInputAction: TextInputAction.done, // Changed from newline
              inputType: TextInputType.multiline, // Added multiline type
              maxLines: 4,
              minLines: 3,
            ),
            AppDimensions.h16,
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
        );
      },
    );
  }
}