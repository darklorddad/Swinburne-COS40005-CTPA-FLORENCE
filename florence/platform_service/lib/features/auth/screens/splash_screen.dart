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

  @override
  void initState() {
    super.initState();
    // Start listening for the auth state as soon as the widget is ready.
    WidgetsBinding.instance.addPostFrameCallback((_) => _redirect());
  }

  @override
  void dispose() {
    // Ensure we cancel the subscription to prevent memory leaks.
    _authSubscription?.cancel();
    super.dispose();
  }

  void _redirect() {
    // Listen for the FIRST auth state change. This is the definitive initial state.
    _authSubscription = supabase.auth.onAuthStateChange.listen((data) {
      // As soon as we get the first event, we can navigate and stop listening.
      _authSubscription?.cancel();
      final session = data.session;
      if (session != null) {
        final user = session.user;
        final role = user.userMetadata?['role'];
        final isNewUser = user.createdAt != null && DateTime.now().difference(DateTime.parse(user.createdAt!)).inMinutes < 2;
        String message = isNewUser ? 'Welcome! Your email has been successfully confirmed.' : 'Welcome back!';

        if (role == 'PATIENT') {
          AppRoutes.pushReplacement(context, AppRoutes.dashboard, arguments: {'message': message});
        } else if (role == 'CLINICIAN' || role == 'ADMIN') {
          AppRoutes.pushReplacement(context, AppRoutes.clinicianDashboard, arguments: {'message': message});
        } else {
          AppRoutes.pushReplacement(context, AppRoutes.login, arguments: {'message': 'Login failed: Unsupported user role.'});
        }
      } else {
        AppRoutes.pushReplacement(context, AppRoutes.login);
      }
    });
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
