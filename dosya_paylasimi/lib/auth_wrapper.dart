import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'auth_page.dart';
import 'file_list_page.dart';
import 'verify_email_page.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(

      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;


        if (user == null) {
          return const AuthPage();
        }


        if (!user.emailVerified) {
          return const VerifyEmailPage();
        }


        return const FileListPage();
      },
    );
  }
}
