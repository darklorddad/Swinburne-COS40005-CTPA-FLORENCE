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
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    // Check for existing session immediately
    final currentSession = supabase.auth.currentSession;
    if (currentSession != null) {
      debugPrint('[SplashScreen] Found existing session, navigating directly');
      _navigateFromSession(currentSession);
      return;
    }

    bool hasNavigated = false;

    // Timeout fallback if no auth event arrives
    final timer = Timer(const Duration(seconds: 3), () {
      if (!hasNavigated && mounted) {
        debugPrint('[SplashScreen] Timeout: No session established');
        _authSubscription?.cancel();
        hasNavigated = true;
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      }
    });

    // Listen for auth events (deep link callbacks trigger signedIn)
    _authSubscription = supabase.auth.onAuthStateChange.listen((data) {
      debugPrint('[SplashScreen] Auth event: ${data.event}');

      if (data.session != null) {
        timer.cancel(); // Cancel the timeout only when a session is found.
        debugPrint('[SplashScreen] Session acquired, navigating');
        _authSubscription?.cancel();
        if (!hasNavigated && mounted) {
          hasNavigated = true;
          _navigateFromSession(data.session!);
        }
      }
      // Ignore initialSession with null session - wait for signedIn event
      // If initialSession is null, the timer will eventually fire and navigate to login.
    }, onError: (error) {
      debugPrint('[SplashScreen] Auth stream error: $error');
      timer.cancel(); // Cancel timer because we are handling the error navigation now.
      if (!hasNavigated && mounted) {
        hasNavigated = true;
        // The error from an expired link is an AuthException.
        final message = (error is AuthException) ? error.message : 'An authentication error occurred.';
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.login,
          arguments: {'message': message},
        );
      }
    });
  }

  void _navigateFromSession(Session session) {
    final role = session.user.userMetadata?['role'];
    String destinationRoute = AppRoutes.dashboard;

    if (role == 'CLINICIAN' || role == 'ADMIN') {
      destinationRoute = AppRoutes.clinicianDashboard;
    }
    
    final isSignUpConfirmation = session.user.createdAt != null &&
        DateTime.now().difference(DateTime.parse(session.user.createdAt!)).inMinutes < 2;
    
    final message = isSignUpConfirmation ? 
        'Welcome! Your email has been successfully confirmed.' : 
        'Welcome back!';

    Navigator.of(context).pushReplacementNamed(destinationRoute, arguments: {'message': message});
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
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
