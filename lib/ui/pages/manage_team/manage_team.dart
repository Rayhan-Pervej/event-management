// File: ui/pages/manage_team_page.dart
import 'package:event_management/ui/pages/manage_team/widgets/role_selection.dart';
import 'package:event_management/ui/pages/manage_team/widgets/search_result.dart';
import 'package:event_management/ui/pages/manage_team/widgets/search_user.dart';
import 'package:event_management/ui/pages/manage_team/widgets/selected_user.dart';
import 'package:event_management/ui/widgets/app_dimensions.dart';
import 'package:event_management/ui/widgets/default_appbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:event_management/providers/manage_team_provider.dart';
import 'package:event_management/models/event_model.dart';

class ManageTeamPage extends StatefulWidget {
  final EventModel event;

  const ManageTeamPage({super.key, required this.event});

  @override
  State<ManageTeamPage> createState() => _ManageTeamPageState();
}

class _ManageTeamPageState extends State<ManageTeamPage> {
  late ManageTeamProvider _provider;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _provider = Provider.of<ManageTeamProvider>(context, listen: false);
    _provider.initialize(widget.event);

    // Listen for changes in the provider
    _provider.addListener(_onProviderChange);
  }

  @override
  void dispose() {
    _provider.removeListener(_onProviderChange);
    super.dispose();
  }

  void _onProviderChange() {
    // Check if members were successfully added
    if (_provider.membersWereAdded && !_hasChanges) {
      _markAsChanged();
    }
  }

  void _markAsChanged() {
    setState(() {
      _hasChanges = true;
    });
  }

  Future<bool> _onWillPop() async {
    // Return the result indicating whether changes were made
    Navigator.of(context).pop(_hasChanges);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: colorScheme.primaryContainer,
        appBar: DefaultAppBar(
          title: 'Manage Team',
          backgroundColor: colorScheme.surface,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop(_hasChanges);
            },
          ),
        ),
        body: Consumer<ManageTeamProvider>(
          builder: (context, provider, child) {
            return Padding(
              padding: const EdgeInsets.all(AppDimensions.space16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Section
                    const UserSearchWidget(),
                    AppDimensions.h16,
                    // Search Results
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.4,
                      child: SearchResultsWidget(),
                    ),
                    AppDimensions.h16,

                    // Role Selection
                    if (provider.hasSelectedUsers) ...[
                      const RoleSelectionWidget(),
                      AppDimensions.h16,
                    ],

                    // Selected Users & Submit Section
                    if (provider.hasSelectedUsers) ...[
                      SelectedUsersWidget(
                        onMembersAdded: () {
                          _markAsChanged();
                        },
                      ),
                      AppDimensions.h16,
                    ],
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
