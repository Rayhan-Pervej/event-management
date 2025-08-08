import 'package:event_management/models/user.dart';
import 'package:event_management/providers/create_event_proivder.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:event_management/ui/widgets/custom_input.dart';
import 'package:event_management/ui/widgets/custom_date_input.dart';
import 'package:event_management/ui/widgets/custom_time_input.dart';
import 'package:event_management/ui/widgets/default_button.dart';

class CreateEventPage extends StatefulWidget {
  const CreateEventPage({super.key});

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.primaryContainer,
      appBar: AppBar(
        backgroundColor: colorScheme.primaryContainer,
        elevation: 0,
        title: Text(
          'Create Event',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<CreateEventProvider>(
        builder: (context, provider, child) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Event Title
                      CustomInput(
                        controller: provider.titleController,
                        fieldLabel: 'Event Title',
                        hintText: 'Enter event title',
                        validation: true,
                        errorMessage: 'Please enter event title',
                        textInputAction: TextInputAction.next,
                        validatorClass: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Event title is required';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Event Description
                      CustomInput(
                        controller: provider.descriptionController,
                        fieldLabel: 'Description',
                        hintText: 'Enter event description',
                        validation: true,
                        errorMessage: 'Please enter event description',
                        textInputAction: TextInputAction.next,
                        maxLines: 3,
                        minLines: 3,
                        validatorClass: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Event description is required';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Event Location
                      CustomInput(
                        controller: provider.locationController,
                        fieldLabel: 'Location',
                        hintText: 'Enter event location',
                        validation: true,
                        errorMessage: 'Please enter event location',
                        textInputAction: TextInputAction.done,
                        prefixWidget: Icon(
                          Icons.location_on_outlined,
                          color: colorScheme.onSurface.withAlpha(153),
                        ),
                        validatorClass: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Event location is required';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 24),

                      // Date and Time Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.onSurface.withAlpha(60),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Event Schedule',
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Start Date and Time Row
                            Row(
                              children: [
                                Expanded(
                                  child: CustomDateInput(
                                    selectedDate: provider.startDate,
                                    fieldLabel: 'Start Date',
                                    hintText: 'Select date',
                                    validation: true,
                                    errorMessage: 'Please select start date',
                                    onChanged: (date) {
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                            provider.setStartDate(date!);
                                          });
                                    },
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(
                                      const Duration(days: 365),
                                    ),
                                    validatorClass: (date) {
                                      if (date == null) {
                                        return 'Start date is required';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: CustomTimeInput(
                                    selectedTime: provider.startTime,
                                    fieldLabel: 'Start Time',
                                    hintText: 'Select time',
                                    validation: true,
                                    errorMessage: 'Please select start time',
                                    onChanged: (time) {
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                            provider.setStartTime(time!);
                                          });
                                    },
                                    use24HourFormat: false,
                                    validatorClass: (time) {
                                      if (time == null) {
                                        return 'Start time is required';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // End Date and Time Row
                            Row(
                              children: [
                                Expanded(
                                  child: CustomDateInput(
                                    selectedDate: provider.endDate,
                                    fieldLabel: 'End Date',
                                    hintText: 'Select date',
                                    validation: true,
                                    errorMessage: 'Please select end date',
                                    onChanged: (date) {
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                            provider.setEndDate(date!);
                                          });
                                    },
                                    firstDate:
                                        provider.startDate ?? DateTime.now(),
                                    lastDate: DateTime.now().add(
                                      const Duration(days: 365),
                                    ),
                                    validatorClass: (date) {
                                      if (date == null) {
                                        return 'End date is required';
                                      }
                                      if (provider.startDate != null &&
                                          date.isBefore(provider.startDate!)) {
                                        return 'End date must be after start date';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: CustomTimeInput(
                                    selectedTime: provider.endTime,
                                    fieldLabel: 'End Time',
                                    hintText: 'Select time',
                                    validation: true,
                                    errorMessage: 'Please select end time',
                                    onChanged: (time) {
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                            provider.setEndTime(time!);
                                          });
                                    },
                                    use24HourFormat: false,
                                    validatorClass: (time) {
                                      if (time == null) {
                                        return 'End time is required';
                                      }

                                      // Check if same date and time validation
                                      if (provider.startDate != null &&
                                          provider.endDate != null &&
                                          provider.startTime != null) {
                                        final isSameDate =
                                            provider.startDate!.year ==
                                                provider.endDate!.year &&
                                            provider.startDate!.month ==
                                                provider.endDate!.month &&
                                            provider.startDate!.day ==
                                                provider.endDate!.day;

                                        if (isSameDate) {
                                          final startMinutes =
                                              provider.startTime!.hour * 60 +
                                              provider.startTime!.minute;
                                          final endMinutes =
                                              time.hour * 60 + time.minute;

                                          if (endMinutes <= startMinutes) {
                                            return 'End time must be after start time';
                                          }
                                        }
                                      }

                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Error Message
                      if (provider.errorMessage != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.error.withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: colorScheme.error.withAlpha(128),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: colorScheme.error,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  provider.errorMessage!,
                                  style: TextStyle(
                                    color: colorScheme.error,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Create Event Button
                      DefaultButton(
                        text: 'Create Event',
                        isLoading: provider.isLoading,
                        press: () => _createEvent(provider),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _createEvent(CreateEventProvider provider) async {
    if (_formKey.currentState?.validate() ?? false) {
      if (provider.isFormValid) {
        try {
          // Get current user from Firebase Auth
          final currentFirebaseUser = FirebaseAuth.instance.currentUser;

          if (currentFirebaseUser == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'User not authenticated. Please login again.',
                ),
                backgroundColor: Theme.of(context).colorScheme.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }

          // Fetch user details from Firestore using the Firebase user UID
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(currentFirebaseUser.uid)
              .get();

          if (!userDoc.exists) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('User data not found. Please try again.'),
                backgroundColor: Theme.of(context).colorScheme.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }

          // Create UserModel from document data
          final currentUser = UserModel.fromMap(
            userDoc.data() as Map<String, dynamic>,
          );

          final success = await provider.createEvent(
            currentUser.uid,
            creatorFirstName: currentUser.firstName,
            creatorLastName: currentUser.lastName,
          );

          if (success && mounted) {
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Event created successfully!'),
                backgroundColor: Theme.of(context).colorScheme.primary,
                behavior: SnackBarBehavior.floating,
              ),
            );

            // Navigate back or to event details
            Navigator.pop(context);
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error creating event: ${e.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }
}
