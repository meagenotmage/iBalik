import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'firebase_options.dart';
import 'screens/auth/welcome_page.dart';
import 'screens/home/home_page.dart';
import 'services/storage_cleanup_service.dart';
import 'services/supabase_storage_service.dart';
import 'utils/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  // Catch any uncaught errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    print('Flutter Error: ${details.exception}');
    print('Stack trace: ${details.stack}');
  };
  
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Firebase first
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('***** Firebase initialized successfully');
  } catch (e, stackTrace) {
    print('Firebase initialization error: $e');
    print('Stack trace: $stackTrace');
    // Continue anyway - some features may not work but app should still launch
  }
  
  try {
    // Initialize Supabase for image hosting
    await Supabase.initialize(
      url: 'https://erljzvaikyztphsamptd.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVybGp6dmFpa3l6dHBoc2FtcHRkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQxNzg1NDgsImV4cCI6MjA3OTc1NDU0OH0.jTZJt3yXcK1xnMyasBtL8r1iH5hK2B6_bhthK7IJ2wk',
    );
    print('***** Supabase initialized successfully');
  } catch (e, stackTrace) {
    print('Supabase initialization error: $e');
    print('Stack trace: $stackTrace');
    // Continue anyway - some features may not work but app should still launch
  }
  
  // Run app immediately without waiting for background services
  runApp(const MyApp());
  
  // Run background operations AFTER app starts - delay even longer
  Future.delayed(const Duration(seconds: 5), () {
    _ensureStorageBucket();
    _runStorageCleanup();
  });
}

/// Ensure the storage bucket exists for image uploads
void _ensureStorageBucket() async {
  try {
    final storageService = SupabaseStorageService();
    await storageService.ensureBucketExists();
    print('Storage bucket setup completed');
  } catch (e) {
    print('Storage bucket setup error (non-critical): $e');
    // Don't throw - this is a non-critical background operation
  }
}

/// Run storage cleanup in background
void _runStorageCleanup() async {
  try {
    final cleanupService = StorageCleanupService();
    await cleanupService.checkAndRunCleanup();
    print('Storage cleanup completed');
  } catch (e) {
    print('Storage cleanup error (non-critical): $e');
    // Don't throw - this is a non-critical background operation
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
      home: _buildHomePage(),
    );
  }
  
  Widget _buildHomePage() {
    // Wrap in error boundary
    return StreamBuilder<fb_auth.User?>(
      stream: fb_auth.FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Handle errors
        if (snapshot.hasError) {
          print('Auth stream error: ${snapshot.error}');
          return const Scaffold(
            body: Center(
              child: WelcomePage(),
            ),
          );
        }
        
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
          );
        }
        
        // Determine which page to show
        try {
          Widget page;
          if (snapshot.hasData && snapshot.data!.emailVerified) {
            page = const HomePage();
          } else {
            page = const WelcomePage();
          }
          
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            switchInCurve: Curves.easeInOut,
            switchOutCurve: Curves.easeInOut,
            child: page,
          );
        } catch (e) {
          print('Error building page: $e');
          return const Scaffold(
            body: Center(
              child: WelcomePage(),
            ),
          );
        }
      },
    );
  }
}