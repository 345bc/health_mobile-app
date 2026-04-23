import 'package:flutter/material.dart';
import 'package:frontend/screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/log_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/main_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'My App',

      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Inter'),

      home: const SplashScreen(),

      // 📍 Route (sau này dùng)
      // routes: {
      //   '/': (_) => HomePage(),
      // },
    );
  }
}
