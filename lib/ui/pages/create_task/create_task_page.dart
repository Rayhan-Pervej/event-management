// File: pages/create_task/create_task_page.dart
import 'package:event_management/ui/pages/create_task/widgets/member_selector.dart';
import 'package:event_management/ui/pages/create_task/widgets/priority_selector.dart';
import 'package:event_management/ui/pages/create_task/widgets/task_form.dart';
import 'package:event_management/ui/widgets/app_dimensions.dart';
import 'package:event_management/ui/widgets/default_appbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:event_management/providers/create_task_provider.dart';
import 'package:event_management/ui/widgets/default_button.dart';
import 'package:event_management/ui/widgets/default_horizontal_divider.dart';

class CreateTaskPage extends StatefulWidget {
  final String eventId;
  final String currentUserId;

  const CreateTaskPage({
    super.key,
    required this.eventId,
    required this.currentUserId,
  });

  @override
  State<CreateTaskPage> createState() => _CreateTaskPageState();
}

class _CreateTaskPageState extends State<CreateTaskPage> {
  late CreateTaskProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = CreateTaskProvider();
    _loadEventData();
  }

  Future<void> _loadEventData() async {
    try {
      _provider.reset();
      await _provider.loadEventDetails(widget.eventId);
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to load event details: $e');
      }
    }
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  Future<void> _createTask() async {
    // Validation checks with specific error messages
    if (!_provider.formKey.currentState!.validate()) {
      return;
    }

    // FIXED: Only validate deadline for single tasks
    if (!_provider.isRecurring &&
        (_provider.selectedDate == null || _provider.selectedTime == null)) {
      _showSnackBar('Please select deadline date and time');
      return;
    }

    if (_provider.selectedMembers.isEmpty) {
      _showSnackBar('Please assign at least one member');
      return;
    }

    try {
      final success = await _provider.createTask(
        widget.eventId,
        widget.currentUserId,
      );

      if (success && mounted) {
        _showSnackBar(
          _provider.isRecurring
              ? 'Recurring task created successfully!'
              : 'Task created successfully!',
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to create task: $e');
      }
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        appBar: const DefaultAppBar(title: 'Create Task', centerTitle: true),
        body: Consumer<CreateTaskProvider>(
          builder: (context, provider, child) {
            return Form(
              key: provider.formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimensions.horizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const TaskFormFieldsWidget(),
                    AppDimensions.h16,
                    const DefaultHorizontalDivider(),
                    AppDimensions.h16,
                    const PrioritySelectorWidget(),
                    AppDimensions.h16,
                    const DefaultHorizontalDivider(),
                    AppDimensions.h16,
                    const MemberSelectorWidget(),
                    AppDimensions.h32,
                    DefaultButton(
                      text: 'Create Task',
                      press: _createTask,
                      isLoading: provider.isLoading,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
