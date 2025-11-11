import 'dart:async';
import 'package:app_links/app_links.dart';
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
    // 1. Proactively check for an initial deep link.
    final appLinks = AppLinks();
    final initialUri = await appLinks.getInitialAppLink();

    if (initialUri != null && initialUri.fragment.contains('error')) {
      final fragmentParams = Uri.splitQueryString(initialUri.fragment);
      final errorDescription = fragmentParams['error_description']?.replaceAll('+', ' ') ?? 'The link is invalid or has expired.';
      debugPrint('[SplashScreen] Initial deep link has an error: $errorDescription');
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.login, arguments: {'message': errorDescription});
      }
      return; // Stop further execution.
    }

    // If there's an existing session, navigate immediately.
    if (supabase.auth.currentSession != null) {
      debugPrint('[SplashScreen] Found existing session, navigating directly');
      _navigateFromSession(supabase.auth.currentSession!);
      return;
    }

    // 2. Set up listener with a timeout as a fallback.
    bool hasNavigated = false;
    final timer = Timer(const Duration(seconds: 2), () {
      if (!hasNavigated && mounted) {
        debugPrint('[SplashScreen] TIMEOUT. No auth event. Navigating to login.');
        _authSubscription?.cancel();
        if (supabase.auth.currentSession == null) {
          hasNavigated = true;
          Navigator.of(context).pushReplacementNamed(AppRoutes.login);
        }
      }
    });

    _authSubscription = supabase.auth.onAuthStateChange.listen((data) {
      debugPrint('[SplashScreen] Auth event received: ${data.event}.');

      if (hasNavigated || !mounted) return;

      timer.cancel();
      _authSubscription?.cancel();
      hasNavigated = true;

      final session = data.session;
      if (session != null) {
        debugPrint('[SplashScreen] Session FOUND from event. Navigating...');
        _navigateFromSession(session);
      } else {
        debugPrint('[SplashScreen] Event received but NO session. Navigating to login.');
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
