import 'package:flutter/material.dart';
import 'package:health_tracker_app/notifications_service.dart';
import 'features/auth/presentation/login_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'goal/goal_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final notificationsService = NotificationsService();
  await notificationsService.initNotifications();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Thêm persistence với thời gian 4 ngày
  await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  FirebaseAuth.instance.authStateChanges().listen((User? user) {
    if (user != null) {
      // Kiểm tra thời gian đăng nhập cuối
      final metadata = user.metadata;
      final lastSignIn = metadata.lastSignInTime;
      if (lastSignIn != null) {
        final now = DateTime.now();
        final diff = now.difference(lastSignIn);
        if (diff.inDays >= 4) {
          FirebaseAuth.instance.signOut();
        }
      }
    }
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Health Tracker',
      theme: ThemeData(primarySwatch: Colors.green),
      debugShowCheckedModeBanner: false,
      home: const LoginPage(),
      routes: {
        '/goals': (context) => const GoalScreen(),
      },
    );
  }
}
