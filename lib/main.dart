import 'package:event_management/core/theme/app_theme.dart';
import 'package:event_management/core/theme/theme_provider.dart';
import 'package:event_management/providers/create_event_proivder.dart';
import 'package:event_management/providers/event_details_provider.dart';
import 'package:event_management/providers/events_provider.dart';
import 'package:event_management/providers/login_provider.dart';
import 'package:event_management/providers/navigation_provider.dart';
import 'package:event_management/providers/sign_up_provider.dart';
import 'package:event_management/providers/manage_team_provider.dart';
import 'package:event_management/ui/pages/auth/login_page.dart';
import 'package:event_management/ui/pages/navigation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
            //darkTheme: AppTheme.darkTheme,
            //themeMode: themeProvider.themeMode,
            home: StreamBuilder<User?>(
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
                  return Login(); // User is not logged in
                }
              },
            ),
          );
        },
      ),
    );
  }
}
