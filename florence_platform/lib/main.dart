import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'config/env.dart';

/// Main entry point of the application
void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await _initializeSupabase();
  
  // Set preferred orientations (optional - comment out if you want landscape support)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  // Run the app
  runApp(const App());
}

/// Initialize Supabase
Future<void> _initializeSupabase() async {
  try {
    // Check if configuration is valid
    if (!Env.isConfigured) {
      debugPrint('⚠️  WARNING: Supabase is not configured!');
      debugPrint('⚠️  Please update your Supabase URL and Anon Key in lib/config/env.dart');
      debugPrint('⚠️  The app will run in offline/demo mode.');

      // Initialize with dummy values to prevent "not initialized" errors
      // This allows the app to run even without proper Supabase configuration
      await Supabase.initialize(
        url: 'https://placeholder.supabase.co',
        anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBsYWNlaG9sZGVyIiwicm9sZSI6ImFub24iLCJpYXQiOjE2NDUxOTIwMDAsImV4cCI6MTk2MDc2ODAwMH0.placeholder',
      );
      debugPrint('✅ Supabase initialized in demo mode');
      return;
    }

    // Initialize Supabase with real credentials
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
      debug: true, // Set to false in production
    );

    debugPrint('✅ Supabase initialized successfully');
  } catch (e) {
    debugPrint('❌ Error initializing Supabase: $e');
    debugPrint('⚠️  The app will run in offline/demo mode.');
    // Re-throw to prevent app from starting with broken Supabase instance
    rethrow;
  }
}

/// Global Supabase client accessor
/// Usage: supabase.auth.signIn(...)
final supabase = Supabase.instance.client;