import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'signin_page.dart'; // Import your sign-in page file
import 'signup_page.dart'; // Import your sign-up page file
import 'homepage.dart'; // Import your homepage file

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Check login state
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  MyApp({required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Firebase Auth Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: isLoggedIn ? '/home' : '/signin',
      routes: {
        '/signin': (context) => SignInPage(),
        '/signup': (context) => SignUpPage(),
        '/home': (context) => HomePage(),
      },
    );
  }
}
