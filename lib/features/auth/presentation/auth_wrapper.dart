import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';
import 'setup_profile_page.dart';
import '../../home/screens/home_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

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

        // Chưa đăng nhập -> Login
        if (snapshot.data == null) {
          return const LoginPage();
        }

        // Đã đăng nhập -> kiểm tra setup
        final uid = snapshot.data!.uid;
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .snapshots(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // Kiểm tra data và điều hướng
            final data = userSnapshot.data?.data() as Map<String, dynamic>?;
            final setupCompleted = data?['setupCompleted'] ?? false;

            // Debug
            print('User data: $data');
            print('Setup completed: $setupCompleted');

            // Nếu chưa setup -> SetupProfilePage
            if (!setupCompleted) {
              return const SetupProfilePage();
            }

            // Đã setup xong -> HomeScreen
            return const HomeScreen();
          },
        );
      },
    );
  }
}
