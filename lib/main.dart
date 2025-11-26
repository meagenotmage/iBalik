import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'firebase_options.dart';
import 'screens/auth/login_page.dart';
import 'screens/home/home_page.dart';
import 'services/storage_cleanup_service.dart';
import 'utils/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

// run supabase for images
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://erljzvaikyztphsamptd.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVybGp6dmFpa3l6dHBoc2FtcHRkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQxNzg1NDgsImV4cCI6MjA3OTc1NDU0OH0.jTZJt3yXcK1xnMyasBtL8r1iH5hK2B6_bhthK7IJ2wk',
  );
  runApp(MyApp());
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
      home: StreamBuilder<fb_auth.User?>(
        stream: fb_auth.FirebaseAuth.instance.authStateChanges(),
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