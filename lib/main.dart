import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'providers/auth_provider.dart'; // Fixed path


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Request notification permissions and subscribe to announcements topic
  try {
    await FirebaseMessaging.instance.requestPermission();
    await FirebaseMessaging.instance.subscribeToTopic('announcements');
  } catch (e) {
    // ignore: avoid_print
    print('FCM init error: $e');
  }
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const HimsakApp(),
    ),
  );
}

class HimsakApp extends StatelessWidget {
  const HimsakApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF8B2247);
    const bgColor = Color(0xFFFAF8F5);

    return MaterialApp(
      title: 'HIMSAK',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          primary: primaryColor,
          background: bgColor,
        ),
        scaffoldBackgroundColor: bgColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        useMaterial3: true,
      ),
      routes: {
        '/admin': (context) => const AdminDashboardScreen(),
      },
      home: const LoginScreen(),
    );
  }
}
