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
    // First, check if there's an existing session immediately
    final currentSession = supabase.auth.currentSession;
    if (currentSession != null) {
      debugPrint('[SplashScreen] Found existing session, navigating directly');
      _navigateFromSession(currentSession);
      return;
    }

    // Set a timeout for cases where no session exists
    final timer = Timer(const Duration(seconds: 3), () {
      debugPrint('[SplashScreen] Timeout reached. No session found. Navigating to login.');
      _authSubscription?.cancel();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      }
    });

    // Listen for auth changes (including deep links)
    _authSubscription = supabase.auth.onAuthStateChange.listen((data) {
      debugPrint('[SplashScreen] Auth event received: ${data.event}. Cancelling timeout.');
      timer.cancel();
      _authSubscription?.cancel();

      final session = data.session;
      if (session != null) {
        debugPrint('[SplashScreen] Session FOUND from event. Navigating to dashboard.');
        _navigateFromSession(session);
      } else {
        debugPrint('[SplashScreen] Event received but NO session. Navigating to login.');
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.login);
        }
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
