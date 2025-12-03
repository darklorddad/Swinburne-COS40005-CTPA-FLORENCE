import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/config/environment.dart';

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

  // Set transparent status bar (system UI will be handled dynamically by theme)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ),
  );

  // Run the app
  runApp(const ProviderScope(child: App()));
}

/// Initialize Supabase
Future<void> _initializeSupabase() async {
  try {
    // Check if configuration is valid
    if (!Environment.isConfigured) {
      debugPrint('WARNING: Supabase is not configured!');
      debugPrint('Please update your Supabase URL and Anon Key in lib/core/config/environment.dart');
      return;
    }
    
    // Initialize Supabase
    await Supabase.initialize(
      url: Environment.supabaseUrl,
      anonKey: Environment.supabaseAnonKey,
      debug: true, // Set to false in production
    );
    
    debugPrint('Supabase initialized successfully');
  } catch (e) {
    debugPrint('Error initializing Supabase: $e');
  }
}

/// Global Supabase client accessor
/// Usage: supabase.auth.signIn(...)
final supabase = Supabase.instance.client;
