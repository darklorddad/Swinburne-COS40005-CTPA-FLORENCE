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
    // This delay ensures the widget is mounted and ready, and gives a moment
    // for the Supabase client to process any incoming deep links from a cold start.
    await Future.delayed(Duration.zero);

    if (!mounted) return;

    // 1. Check for an immediate session. The deep link might have been processed
    //    by the Supabase plugin before this Dart code even runs.
    final currentSession = supabase.auth.currentSession;
    if (currentSession != null) {
      _navigateFromSession(currentSession);
      return; // Navigation handled, we are done.
    }

    // 2. If no immediate session, set up a listener for auth changes.
    //    This will catch the session if it's established while the splash screen is visible.
    _authSubscription = supabase.auth.onAuthStateChange.listen(
      (data) {
        _authSubscription?.cancel(); // We only need the first event.
        final session = data.session;

        if (session != null) {
          _navigateFromSession(session);
        } else {
          // No session found, navigate to login. This handles manual app starts with no user.
          Navigator.of(context).pushReplacementNamed(AppRoutes.login);
        }
      },
      onError: (error) {
        _authSubscription?.cancel();
        final message = error is AuthException ? error.message : 'Authentication error.';
        Navigator.of(context).pushReplacementNamed(AppRoutes.login, arguments: {'message': message});
      },
    );
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
