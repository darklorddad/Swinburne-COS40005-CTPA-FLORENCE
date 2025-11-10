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
    // Wait for the widget to be fully built and for Supabase to potentially handle a deep link.
    // This is crucial for both cold and warm starts.
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    // The session may have been restored by the Supabase client from a deep link by now.
    final session = supabase.auth.currentSession;

    if (session != null) {
      debugPrint('[SplashScreen] Session found on initial check. Navigating to dashboard.');
      final user = session.user;
      final role = user.userMetadata?['role'];
      
      // Check if this was a very recent confirmation to show the welcome message
      final confirmedAt = user.emailConfirmedAt;
      bool isRecentConfirmation = confirmedAt != null && DateTime.now().difference(DateTime.parse(confirmedAt)).inMinutes < 2;
      String message = isRecentConfirmation ? 'Welcome! Your email has been successfully confirmed.' : 'Welcome back!';

      if (role == 'PATIENT') {
        AppRoutes.pushReplacement(context, AppRoutes.dashboard, arguments: {'message': message});
      } else if (role == 'CLINICIAN' || role == 'ADMIN') {
        AppRoutes.pushReplacement(context, AppRoutes.clinicianDashboard, arguments: {'message': message});
      } else {
        AppRoutes.pushReplacement(context, AppRoutes.login, arguments: {'message': 'Login failed: Unsupported user role.'});
      }
    } else {
      // If there's no session after the delay, it's safe to assume we should go to login.
      // The onError listener in app.dart will still handle invalid deep link cases that navigate here.
      debugPrint('[SplashScreen] No session found on initial check. Navigating to login.');
      AppRoutes.pushReplacement(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    // The UI remains the same, just a loading/branding screen.
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
