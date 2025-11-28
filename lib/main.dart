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
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase first
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Supabase for image hosting
  await Supabase.initialize(
    url: 'https://erljzvaikyztphsamptd.supabase.co',
    anonKey: 'sb_publishable_Idv4z1wqyG6j5wIZasDoiA_34NHmCbY',
  );
  
  // Ensure storage bucket exists
  await _ensureStorageBucket();
  
  // Run storage cleanup in background
  _runStorageCleanup();
  
  runApp(const MyApp());
}

/// Ensure the storage bucket exists for image uploads
Future<void> _ensureStorageBucket() async {
  try {
    final storageService = SupabaseStorageService();
    await storageService.ensureBucketExists();
  } catch (e) {
    print('Storage bucket setup error: $e');
  }
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
            page = const WelcomePage();
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