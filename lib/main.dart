import 'package:flutter/material.dart';
import 'package:resume_screening/screens/auth/login.dart';
import 'package:resume_screening/screens/details_screen.dart';
import 'package:resume_screening/screens/results_screen.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:resume_screening/firebase_options.dart';
import 'package:resume_screening/screens/uplaod_screen_new.dart';
import 'package:resume_screening/screens/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      primarySwatch: Colors.indigo,
      scaffoldBackgroundColor: Colors.grey[100],
      appBarTheme: const AppBarTheme(
        color: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 10,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.indigoAccent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          padding: EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          textStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          shadowColor: Colors.indigo.withOpacity(0.5),
          elevation: 5,
        ),
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(fontSize: 18, color: Colors.grey[800]),
        bodyMedium: TextStyle(fontSize: 16, color: Colors.grey[700]),
        headlineLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.indigoAccent),
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 5,
        margin: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        shadowColor: Colors.grey.withOpacity(0.3),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        labelStyle: TextStyle(color: Colors.indigoAccent),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.indigoAccent, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.indigo, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.indigoAccent, width: 2),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 8,
      ),
    ),
    home: LoginScreen(),
    routes: {
      '/results': (context) => ResultsPage(),
      // '/details': (context) => DetailsPage(),
      '/profile': (context) => ProfilePage(),
    },
  ));
}
