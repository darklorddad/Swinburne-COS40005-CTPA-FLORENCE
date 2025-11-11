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
    // This delay is important to allow the app to finish its initial render
    // and for the Supabase client to process any incoming deep links.
    await Future.delayed(Duration.zero);

    if (!mounted) return;

    bool hasNavigated = false;

    // Set up the listener for auth changes. This will fire for deep links or existing sessions.
    _authSubscription = supabase.auth.onAuthStateChange.listen(
      (data) {
        if (hasNavigated) return; // Prevent multiple navigations

        final session = data.session;
        if (session != null) {
          hasNavigated = true;
          _authSubscription?.cancel();
          _navigateFromSession(session);
        }
      },
      onError: (error) {
        if (hasNavigated) return;
        hasNavigated = true;
        _authSubscription?.cancel();
        final message = error is AuthException ? error.message : 'Authentication error.';
        Navigator.of(context).pushReplacementNamed(AppRoutes.login, arguments: {'message': message});
      },
    );

    // If after a short delay there's still no session, go to login.
    // This handles the case of a manual app launch with no user logged in.
    Future.delayed(const Duration(seconds: 1), () {
      if (!hasNavigated && mounted && supabase.auth.currentSession == null) {
        hasNavigated = true;
        _authSubscription?.cancel();
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
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
