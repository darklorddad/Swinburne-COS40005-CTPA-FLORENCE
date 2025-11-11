import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/config/environment.dart';

/// Main entry point of the application
void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await _initializeSupabase();

  // Initialize app links handler
  final appLinks = AppLinks();

  // Handle initial deep link (e.g., from cold start)
  final initialUri = await appLinks.getInitialLink();
  if (initialUri != null) {
    debugPrint('[Main] Initial deep link: $initialUri');
  }

  // Listen for subsequent deep links
  appLinks.uriLinkStream.listen((uri) {
    debugPrint('[Main] Incoming deep link: $uri');
    // Supabase will automatically process this if MainActivity is configured
  });
  
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
  runApp(App());
}

/// Initialize Supabase
Future<void> _initializeSupabase() async {
  try {
    // Check if configuration is valid
    if (!Environment.isConfigured) {
      debugPrint('⚠️  WARNING: Supabase is not configured!');
      debugPrint('⚠️  Please update your Supabase URL and Anon Key in lib/core/config/environment.dart');
      debugPrint('⚠️  The app will run in offline/demo mode.');
      return;
    }
    
    // Initialize Supabase
    await Supabase.initialize(
      url: Environment.supabaseUrl,
      anonKey: Environment.supabaseAnonKey,
      debug: true, // Set to false in production
    );
    
    debugPrint('✅ Supabase initialized successfully');
  } catch (e) {
    debugPrint('❌ Error initializing Supabase: $e');
    debugPrint('⚠️  The app will run in offline/demo mode.');
  }
}

/// Global Supabase client accessor
/// Usage: supabase.auth.signIn(...)
final supabase = Supabase.instance.client;
