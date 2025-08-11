import 'package:event_management/providers/home_provider.dart';
import 'package:event_management/providers/navigation_provider.dart';
import 'package:event_management/providers/user_tasks_provider.dart';
import 'package:event_management/ui/pages/events/events_page.dart';
import 'package:event_management/ui/pages/home/home_page.dart';
import 'package:event_management/ui/pages/more/more_page.dart';
import 'package:event_management/ui/pages/tasks/tasks_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NavigationPage extends StatelessWidget {
  const NavigationPage({super.key});

  @override
  Widget build(BuildContext context) {
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
              const MorePage(),
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
              backgroundColor: const Color(
                0xFFF3F4F6,
              ), // primaryContainer from theme
              selectedItemColor: const Color(0xFF3F51B5), // primary color
              unselectedItemColor: const Color(
                0xFF2C2C2C,
              ).withOpacity(0.6), // onSurface with opacity
              selectedFontSize: 12,
              unselectedFontSize: 12,
              elevation: 0,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.event_outlined),
                  activeIcon: Icon(Icons.event),
                  label: 'Events',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.task_outlined),
                  activeIcon: Icon(Icons.task),
                  label: 'Tasks',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
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
