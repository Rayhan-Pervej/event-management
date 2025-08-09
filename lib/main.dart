import 'package:event_management/core/theme/app_theme.dart';
import 'package:event_management/core/theme/theme_provider.dart';
import 'package:event_management/providers/create_event_proivder.dart';
import 'package:event_management/providers/create_task_provider.dart';
import 'package:event_management/providers/event_details_provider.dart';
import 'package:event_management/providers/events_provider.dart';
import 'package:event_management/providers/login_provider.dart';
import 'package:event_management/providers/navigation_provider.dart';
import 'package:event_management/providers/sign_up_provider.dart';
import 'package:event_management/providers/manage_team_provider.dart';
import 'package:event_management/service/notification_manager.dart';
import 'package:event_management/service/notification_service.dart';
import 'package:event_management/service/background_service.dart';
import 'package:event_management/ui/pages/auth/login_page.dart';
import 'package:event_management/ui/pages/navigation.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize background service
  await BackgroundNotificationService.initialize();

  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SignUpProvider()),
        ChangeNotifierProvider(create: (_) => LoginProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => EventsProvider()),
        ChangeNotifierProvider(create: (_) => CreateEventProvider()),
        ChangeNotifierProvider(create: (_) => ManageTeamProvider()),
        ChangeNotifierProvider(create: (_) => EventDetailsProvider()),
        ChangeNotifierProvider(create: (_) => CreateTaskProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Event Management',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            home: AuthWrapper(),
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> with WidgetsBindingObserver {
  Timer? _reminderTimer;
  bool _notificationsInitialized = false;

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeNotificationService();
    });
    
    FirebaseAuth.instance.authStateChanges().listen(_handleAuthStateChange);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _reminderTimer?.cancel();
    if (_notificationsInitialized) {
      NotificationManager().dispose();
    }
    super.dispose();
  }

@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  super.didChangeAppLifecycleState(state);

  switch (state) {
    case AppLifecycleState.resumed:
      NotificationManager().setBackgroundState(false);
      // Remove the aggressive restart - let the health check handle it
      break;
    case AppLifecycleState.paused:
      NotificationManager().setBackgroundState(true);
      break;
    default:
      break;
  }
}

  Future<void> _initializeNotificationService() async {
    try {
      await NotificationService().initialize();
      _notificationsInitialized = true;
    } catch (e) {
      _notificationsInitialized = false;
    }
  }

  void _handleAuthStateChange(User? user) async {
    if (user != null) {
      if (_notificationsInitialized) {
        await _initializeNotifications(user.uid);
      } else {
        // Wait for notifications to be ready
        int attempts = 0;
        while (!_notificationsInitialized && attempts < 10) {
          await Future.delayed(Duration(milliseconds: 500));
          attempts++;
        }
        if (_notificationsInitialized) {
          await _initializeNotifications(user.uid);
        }
      }
    } else {
      await _disposeNotifications();
    }
  }

  Future<void> _initializeNotifications(String userId) async {
    if (!_notificationsInitialized) return;

    try {
      await NotificationManager().initialize(userId);
      await BackgroundNotificationService.startBackgroundTask(userId);
      _scheduleDailyReminders();
    } catch (e) {
      // Handle error silently in production
    }
  }

  void _scheduleDailyReminders() {
    _reminderTimer?.cancel();
    _reminderTimer = Timer.periodic(const Duration(hours: 6), (timer) {
      if (_notificationsInitialized) {
        NotificationManager().scheduleTaskReminders();
      }
    });
    
    if (_notificationsInitialized) {
      NotificationManager().scheduleTaskReminders();
    }
  }

  Future<void> _disposeNotifications() async {
    try {
      _reminderTimer?.cancel();
      _reminderTimer = null;
      await BackgroundNotificationService.stopBackgroundTask();
      await NotificationManager().dispose();
    } catch (e) {
      // Handle error silently in production
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return NavigationPage();
        } else {
          return Login();
        }
      },
    );
  }
}