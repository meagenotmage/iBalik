import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/auth/login_page.dart';
import 'screens/home/home_page.dart';
import 'services/storage_cleanup_service.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Run storage cleanup in background to stay within free tier
  _runStorageCleanup();
  
  runApp(const MyApp());
}

/// Run storage cleanup in background
void _runStorageCleanup() async {
  try {
    final cleanupService = StorageCleanupService();
    await cleanupService.checkAndRunCleanup();
  } catch (e) {
    print('Storage cleanup error: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'iBalik',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Show loading while checking auth state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          // Smooth fade transition when showing pages
          Widget page;
          if (snapshot.hasData && snapshot.data!.emailVerified) {
            page = const HomePage();
          } else {
            page = const LoginPage();
          }
          
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            switchInCurve: Curves.easeInOut,
            switchOutCurve: Curves.easeInOut,
            child: page,
          );
        },
      ),
    );
  }
}