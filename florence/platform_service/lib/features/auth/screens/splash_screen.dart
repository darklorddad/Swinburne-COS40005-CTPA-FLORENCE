import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../config/theme.dart';
import '../../../config/routes.dart';
import '../../../main.dart';
import '../../../core/utils/helpers.dart'; // Make sure this import is present

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  StreamSubscription<AuthState>? _authSubscription;
  bool _hasNavigated = false;

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
    await Future.delayed(Duration.zero);
    if (!mounted) return;

    // Listen for both successful authentication and errors
    _authSubscription = supabase.auth.onAuthStateChange.listen(
      (data) {
        // This handles successful sign-ins (from deep link or existing session)
        final Session? session = data.session;
        if (session != null && !_hasNavigated) {
          _navigateToDashboard(session.user);
        }
      },
      onError: (error) {
        // This is the new, crucial part for handling errors like expired links
        if (error is AuthException && !_hasNavigated) {
          String message = 'An authentication error occurred. Please try again.';
          if (error.statusCode == '401' || error.message.contains('invalid or has expired')) {
            message = 'This confirmation link has expired or is invalid. Please log in or sign up again.';
          }
          _navigateToLogin(message: message);
        }
      },
    );

    // Handle the initial state for users who are already logged in
    final initialSession = supabase.auth.currentSession;
    if (initialSession != null) {
      _navigateToDashboard(initialSession.user);
    } else {
      // For new users or expired links, a short delay allows the onError to fire
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (!mounted || _hasNavigated) return;
        // If nothing has happened after 1 second, it's a normal startup for a logged-out user
        if (supabase.auth.currentSession == null) {
          _navigateToLogin();
        }
      });
    }
  }

  void _navigateToDashboard(User user) {
    if (!mounted || _hasNavigated) return;
    setState(() { _hasNavigated = true; });

    String message;
    final confirmedAt = user.emailConfirmedAt;
    // Check if the user was just confirmed in the last few minutes
    if (confirmedAt != null && DateTime.now().difference(DateTime.parse(confirmedAt)).inMinutes < 2) {
      message = 'Welcome! Your email has been successfully confirmed.';
    } else {
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
    setState(() { _hasNavigated = true; });
    AppRoutes.pushReplacement(context, AppRoutes.login, arguments: {'message': message});
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
