import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/login.dart';
import 'screens/signup.dart';
import 'screens/dashboard.dart';
import 'screens/profile.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Referral App',
      initialRoute: '/login',
      routes: {
        '/login': (_) => LoginScreen(),
        '/signup': (_) => SignupScreen(),
        '/dashboard': (_) => DashboardScreen(),
        '/profile': (_) => ProfileScreen(),
      },
    );
  }
}
