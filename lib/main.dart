import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:stay_safe_app/auth_service.dart';
import 'package:stay_safe_app/auth_wrapper.dart';
import 'package:stay_safe_app/screens/contacts_screen.dart';
import 'package:stay_safe_app/screens/emergency_screen.dart';
import 'package:stay_safe_app/screens/home_screen.dart';
import 'package:stay_safe_app/screens/profile_screen.dart';
import 'package:stay_safe_app/screens/map_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const StaySafeApp());
}

class StaySafeApp extends StatelessWidget {
  const StaySafeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamProvider<User?>.value(
      value: AuthService().user,
      initialData: null,
      child: MaterialApp(
        title: 'Stay Safe App',
        theme: ThemeData(
          primarySwatch: Colors.red,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const AuthWrapper(),
          '/home': (context) => const HomeScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/contacts': (context) => const EmergencyContactsScreen(),
          '/emergency': (context) => const EmergencyScreen(),
          '/map': (context) => const SafeHavensMapScreen(),
        },
      ),
    );
  }
}