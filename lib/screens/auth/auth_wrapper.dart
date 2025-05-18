import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:resume_screening/screens/auth/login.dart';

import 'package:resume_screening/screens/uplaod_screen_new.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // If the user is logged in, navigate to the upload page
        if (snapshot.hasData) {
          return UploadPage();
        }
        // Otherwise, show the login screen
        return const LoginScreen();
      },
    );
  }
}
