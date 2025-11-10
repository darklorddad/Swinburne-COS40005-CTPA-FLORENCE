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
    // Give the app a moment to settle before navigating
    Future.delayed(const Duration(seconds: 1), _redirect);
  }

  Future<void> _redirect() async {
    if (!mounted) return;

    // Perform a one-time check for the current session on app start.
    // The persistent listener in app.dart will handle dynamic changes.
    final session = supabase.auth.currentSession;

    if (session != null) {
      final role = session.user.userMetadata?['role'];
      if (role == 'PATIENT') {
        AppRoutes.pushReplacement(context, AppRoutes.dashboard, arguments: {'message': 'Welcome back!'});
      } else if (role == 'CLINICIAN' || role == 'ADMIN') {
        AppRoutes.pushReplacement(context, AppRoutes.clinicianDashboard, arguments: {'message': 'Welcome back!'});
      } else {
        AppRoutes.pushReplacement(context, AppRoutes.login, arguments: {'message': 'Login failed: Unsupported user role.'});
      }
    } else {
      AppRoutes.pushReplacement(context, AppRoutes.login);
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
