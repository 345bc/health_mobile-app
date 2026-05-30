import 'package:flutter/material.dart';
import 'package:frontend/screens/main_screen.dart';
import 'package:frontend/screens/profile_screen.dart';
// import 'package:frontend/screens/sign-in_screen.dart';
// import 'package:frontend/screens/sign-up_screen.dart';
import 'package:provider/provider.dart';
import 'package:frontend/provider/user_provider.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UserProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Health App',
        theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Inter'),
        home: const SplashScreen(),
      ),
    );
  }
}
