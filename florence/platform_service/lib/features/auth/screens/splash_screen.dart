import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../config/routes.dart';
import '../../../main.dart';
import '../../../config/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    debugPrint('[SplashScreen] _redirect: Initializing startup check.');
    // Wait for a short duration to allow the Supabase client to initialize
    // and process any deep links that may have launched the app on a cold start.
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    debugPrint('[SplashScreen] _redirect: Delay complete. Checking for current session...');
    final session = supabase.auth.currentSession;
    if (session != null) {
      debugPrint('[SplashScreen] _redirect: Session FOUND. Navigating to dashboard.');
      // A session was found, meaning the user is logged in.
      final user = session.user;
      final role = user.userMetadata?['role'];
      String destinationRoute = AppRoutes.dashboard; // Default route

      if (role == 'CLINICIAN' || role == 'ADMIN') {
        destinationRoute = AppRoutes.clinicianDashboard;
      }

      // The auth listener in app.dart is responsible for subsequent changes.
      // This initial navigation gets the user to the right place.
      Navigator.of(context).pushReplacementNamed(destinationRoute);
    } else {
      debugPrint('[SplashScreen] _redirect: Session NOT FOUND. Navigating to login.');
      // No session found, user is not logged in.
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
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
            Text(
              'Florence',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Monitor your health, improve your life',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
