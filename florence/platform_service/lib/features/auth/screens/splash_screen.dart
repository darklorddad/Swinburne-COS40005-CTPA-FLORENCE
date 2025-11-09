import 'dart:async'; // Add this import
import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../config/routes.dart';
import '../../../main.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Add this import

/// Splash Screen
/// Shows app logo and listens for authentication status changes
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _redirect();
  }

  @override
  void dispose() {
    // Be sure to cancel the subscription when the widget is disposed
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _redirect() async {
    // Wait for the widget to be fully built before navigating
    await Future.delayed(Duration.zero);
    if (!mounted) return;

    // Listen for authentication state changes
    _authSubscription = supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;
      
      if (event == AuthChangeEvent.signedIn && session != null) {
        // User is signed in, check role and navigate
        final user = session.user;
        final role = user.appMetadata?['role'];

        if (role == 'PATIENT') {
          AppRoutes.pushReplacement(context, AppRoutes.dashboard);
        } else if (role == 'CLINICIAN') {
          AppRoutes.pushReplacement(context, AppRoutes.clinicianDashboard);
        } else {
          // Role not supported or not found, go to login
          AppRoutes.pushReplacement(context, AppRoutes.login);
        }
      } else if (event == AuthChangeEvent.signedOut) {
        // User signed out, go to login
        AppRoutes.pushReplacement(context, AppRoutes.login);
      }
    });

    // Handle the initial state (if the app is opened normally, not from a link)
    final session = supabase.auth.currentSession;
    if (session == null) {
       // Give Supabase a moment to process a deep link if it exists
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      
      // If still no session after the delay, navigate to login
      if (supabase.auth.currentSession == null) {
        AppRoutes.pushReplacement(context, AppRoutes.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite_rounded,
                size: 60,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 32),
            
            // App name
            Text(
              'Florence',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            
            // Tagline
            Text(
              'Monitor your health, improve your life',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            
            // Loading indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
