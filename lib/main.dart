import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:health_tracker_app/measure/weight_history_screen.dart';
import 'package:health_tracker_app/notifications_service.dart';
import 'features/auth/presentation/login_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'goal/goal_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'features/home/screens/home_screen.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Khởi tạo dữ liệu định dạng cho tiếng Việt
  Intl.defaultLocale = 'vi';
  await initializeDateFormatting('vi');

  // Khởi tạo notifications
  final notificationsService = NotificationsService();
  await notificationsService.initNotifications();
  
  // Khởi tạo Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Auto logout after 4 days
  FirebaseAuth.instance.authStateChanges().listen((User? user) {
    if (user != null) {
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
      
      // Replace home with StreamBuilder
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          } else if (snapshot.hasData) {
            return const HomeScreen(); // Đã đăng nhập
          } else {
            return const LoginPage(); // Chưa đăng nhập
          }
        },
      ),
      
      // Thêm cấu hình localization
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('vi'),
        Locale('en'),
      ],
      locale: const Locale('vi'),
      
      // Routes hiện tại
      routes: {
        '/goals': (context) => const GoalScreen(),
        '/history': (_) => const WeightHistoryScreen(),
      },
    );
  }
}
