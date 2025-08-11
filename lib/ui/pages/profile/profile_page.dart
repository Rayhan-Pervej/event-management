// File: ui/pages/profile_page.dart
import 'package:event_management/core/constants/build_text.dart';
import 'package:event_management/ui/widgets/default_appbar.dart';
import 'package:event_management/ui/widgets/show_circular.dart';
import 'package:event_management/ui/widgets/app_dimensions.dart';
import 'package:event_management/ui/widgets/custom_input.dart';
import 'package:event_management/ui/widgets/default_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:event_management/providers/profile_provider.dart';
import 'package:icons_plus/icons_plus.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  void _loadUserData() {
    context.read<ProfileProvider>().loadUserData();
  }

  void _populateFields() {
    final user = context.read<ProfileProvider>().currentUser;
    if (user != null) {
      _firstNameController.text = user.firstName;
      _lastNameController.text = user.lastName;
      _emailController.text = user.email;
      _phoneController.text = user.phone ?? '';
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState?.validate() ?? false) {
      final success = await context.read<ProfileProvider>().updateUserData(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _showLogoutDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const BuildText(
          text: 'Logout',
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        content: const BuildText(
          text: 'Are you sure you want to logout?',
          fontSize: 14,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const BuildText(text: 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const BuildText(
              text: 'Logout',
              color: Colors.red,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<ProfileProvider>().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: DefaultAppBar(
        title: "My Profile",
        isShowBackButton: false,
        actions: [
          Consumer<ProfileProvider>(
            builder: (context, provider, child) {
              if (provider.isEditing) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: provider.isSaving
                          ? null
                          : () {
                              provider.cancelEditing();
                              _populateFields(); // Reset fields
                            },
                      child: BuildText(
                        text: 'Cancel',
                        color: colorScheme.onBackground.withOpacity(0.7),
                      ),
                    ),
                    TextButton(
                      onPressed: provider.isSaving ? null : _saveProfile,
                      child: provider.isSaving
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.primary,
                              ),
                            )
                          : BuildText(
                              text: 'Save',
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                    ),
                  ],
                );
              } else {
                return IconButton(
                  onPressed: () {
                    provider.toggleEditMode();
                    _populateFields();
                  },
                  icon: Icon(
                    Iconsax.edit_outline,
                    color: colorScheme.onBackground,
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Consumer<ProfileProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: ShowCircular(visible: true));
          }

          if (provider.error != null) {
            return _buildErrorState(provider.error!);
          }

          if (provider.currentUser == null) {
            return _buildNoUserState();
          }

          // Populate fields when user data is loaded
          if (!provider.isEditing) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _populateFields();
            });
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.space16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Profile Avatar
                  _buildProfileAvatar(provider.currentUser!),

                  AppDimensions.h32,

                  // Profile Form
                  _buildProfileForm(provider),

                  AppDimensions.h32,

                  // Logout Button
                  _buildLogoutButton(),

                  AppDimensions.h24,
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileAvatar(dynamic user) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primary,
                colorScheme.primary.withOpacity(0.7),
              ],
            ),
          ),
          child: Center(
            child: BuildText(
              text: user.fullName.isNotEmpty
                  ? user.fullName
                        .split(' ')
                        .map((e) => e[0])
                        .take(2)
                        .join()
                        .toUpperCase()
                  : 'U',
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        AppDimensions.h16,
        BuildText(
          text: user.fullName,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onBackground,
        ),
        AppDimensions.h4,
        BuildText(
          text: user.email,
          fontSize: 14,
          color: theme.colorScheme.onBackground.withOpacity(0.7),
        ),
      ],
    );
  }

  Widget _buildProfileForm(ProfileProvider provider) {
    return Column(
      children: [
        // First Name
        CustomInput(
          controller: _firstNameController,
          fieldLabel: 'First Name',
          hintText: 'Enter your first name',
          validation: true,
          errorMessage: 'First name is required',
          viewOnly: !provider.isEditing,
          validatorClass: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'First name is required';
            }
            return null;
          },
          prefixWidget: Icon(
            Iconsax.user_outline,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),

        AppDimensions.h16,

        // Last Name
        CustomInput(
          controller: _lastNameController,
          fieldLabel: 'Last Name',
          hintText: 'Enter your last name',
          validation: true,
          errorMessage: 'Last name is required',
          viewOnly: !provider.isEditing,
          validatorClass: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Last name is required';
            }
            return null;
          },
          prefixWidget: Icon(
            Iconsax.user_outline,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),

        AppDimensions.h16,

        // Email
        CustomInput(
          controller: _emailController,
          fieldLabel: 'Email',
          hintText: 'Enter your email',
          validation: true,
          errorMessage: 'Valid email is required',
          viewOnly: !provider.isEditing,
          inputType: TextInputType.emailAddress,
          validatorClass: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Email is required';
            }
            if (!value.contains('@')) {
              return 'Enter a valid email';
            }
            return null;
          },
          prefixWidget: Icon(
            Iconsax.sms_outline,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),

        AppDimensions.h16,

        // Phone (Optional)
        CustomInput(
          controller: _phoneController,
          fieldLabel: 'Phone Number',
          hintText: 'Enter your phone number (optional)',
          validation: false,
          errorMessage: '',
          viewOnly: !provider.isEditing,
          inputType: TextInputType.phone,
          prefixWidget: Icon(
            Iconsax.call_outline,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space16),
      child: DefaultButton(
        text: 'Logout',
        press: _showLogoutDialog,
        bgColor: Colors.red,
        btnTextColor: Colors.white,
      ),
    );
  }

  Widget _buildErrorState(String error) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.space32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.info_circle_outline,
              size: 64,
              color: Colors.red.withOpacity(0.5),
            ),
            AppDimensions.h16,
            BuildText(
              text: 'Error loading profile',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colorScheme.onBackground,
            ),
            AppDimensions.h8,
            BuildText(
              text: error,
              fontSize: 14,
              color: colorScheme.onBackground.withOpacity(0.7),
              textAlign: TextAlign.center,
            ),
            AppDimensions.h16,
            DefaultButton(
              text: 'Retry',
              press: _loadUserData,
              isFullWidth: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoUserState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.space32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.user_outline,
              size: 64,
              color: colorScheme.onBackground.withOpacity(0.3),
            ),
            AppDimensions.h16,
            BuildText(
              text: 'No user data found',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colorScheme.onBackground,
            ),
            AppDimensions.h8,
            BuildText(
              text: 'Please try logging in again',
              fontSize: 14,
              color: colorScheme.onBackground.withOpacity(0.7),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
