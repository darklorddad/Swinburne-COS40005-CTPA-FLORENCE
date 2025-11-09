import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../config/theme.dart';
import '../../../config/routes.dart';
import '../../../main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  StreamSubscription<AuthState>? _authSubscription;
  bool _hasNavigated = false; // Add a flag to prevent multiple navigations

  @override
  void initState() {
    super.initState();
    _redirect();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _redirect() async {
    // Wait for the widget to be fully built before any logic
    await Future.delayed(Duration.zero);
    if (!mounted) return;

    // Listen for authentication state changes from Supabase
    _authSubscription = supabase.auth.onAuthStateChange.listen((data) {
      final Session? session = data.session;
      if (session != null && !_hasNavigated) {
        _navigateToDashboard(session.user);
      }
    });

    // Handle the initial state right away
    final initialSession = supabase.auth.currentSession;
    if (initialSession != null) {
      // If a session already exists (user was already logged in), go to dashboard
      _navigateToDashboard(initialSession.user);
    } else {
      // If no session, wait a brief moment to see if a deep link session is established.
      // This is the key part for handling both normal startup and deep link startup.
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted || _hasNavigated) return;

        final sessionAfterDelay = supabase.auth.currentSession;
        if (sessionAfterDelay == null) {
          // If after the delay there is still no session, it means either:
          // 1. It was a normal app start for a logged-out user.
          // 2. It was an invalid/expired deep link.
          // In both cases, we navigate to the login screen.
          _navigateToLogin();
        }
      });
    }
  }

  void _navigateToDashboard(User user) {
    if (!mounted || _hasNavigated) return;
    setState(() {
      _hasNavigated = true;
    });

    // Determine the correct welcome message
    String message;
    final confirmedAt = user.emailConfirmedAt;
    if (confirmedAt != null && DateTime.now().difference(DateTime.parse(confirmedAt)).inMinutes < 2) {
      // If confirmed within the last 2 minutes, it's a new confirmation
      message = 'Welcome! Your email has been confirmed.';
    } else {
      // Otherwise, they were already confirmed and are just logging in
      message = 'Welcome back!';
    }

    final role = user.appMetadata?['role'];
    if (role == 'PATIENT') {
      AppRoutes.pushReplacement(context, AppRoutes.dashboard, arguments: {'message': message});
    } else if (role == 'CLINICIAN') {
      AppRoutes.pushReplacement(context, AppRoutes.clinicianDashboard, arguments: {'message': message});
    } else {
      _navigateToLogin(message: 'Login failed: Unsupported user role.');
    }
  }

  void _navigateToLogin({String? message}) {
    if (!mounted || _hasNavigated) return;
    setState(() {
      _hasNavigated = true;
    });
    AppRoutes.pushReplacement(context, AppRoutes.login, arguments: {'message': message});
  }

  @override
  Widget build(BuildContext context) {
    // The UI remains the same, showing the loading screen
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
