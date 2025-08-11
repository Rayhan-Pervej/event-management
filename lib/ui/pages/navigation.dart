import 'package:event_management/providers/home_provider.dart';
import 'package:event_management/providers/navigation_provider.dart';
import 'package:event_management/providers/profile_provider.dart';
import 'package:event_management/providers/user_tasks_provider.dart';
import 'package:event_management/ui/pages/events/events_page.dart';
import 'package:event_management/ui/pages/home/home_page.dart';
import 'package:event_management/ui/pages/profile/profile_page.dart';
import 'package:event_management/ui/pages/tasks/tasks_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:icons_plus/icons_plus.dart';

class NavigationPage extends StatelessWidget {
  const NavigationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Consumer<NavigationProvider>(
      builder: (context, navigationProvider, child) {
        return Scaffold(
          body: IndexedStack(
            index: navigationProvider.currentIndex,
            children: [
              ChangeNotifierProvider(
                create: (context) => HomeProvider(),
                child: const HomePage(),
              ),
              const EventsPage(),
              ChangeNotifierProvider(
                create: (context) => UserTasksProvider(),
                child: const UserTasksPage(),
              ),
              ChangeNotifierProvider(
                create: (context) => ProfileProvider(),
                child: const ProfilePage(),
              ),
            ],
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: navigationProvider.currentIndex,
              onTap: (index) => navigationProvider.updateIndex(index),
              backgroundColor: colorScheme.primaryContainer,
              selectedItemColor: colorScheme.primary,
              unselectedItemColor: colorScheme.onSurface.withOpacity(0.6),
              selectedFontSize: 12,
              unselectedFontSize: 12,
              elevation: 0,
              // Remove splash effect
              enableFeedback: false,

              items: [
                BottomNavigationBarItem(
                  icon: Icon(Iconsax.home_2_outline),
                  activeIcon: Icon(Iconsax.home_2_bold),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Iconsax.calendar_outline),
                  activeIcon: Icon(Iconsax.calendar_bold),
                  label: 'Events',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Iconsax.task_square_outline),
                  activeIcon: Icon(Iconsax.task_square_outline),
                  label: 'Tasks',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Iconsax.user_outline),
                  activeIcon: Icon(Iconsax.user_bold),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
