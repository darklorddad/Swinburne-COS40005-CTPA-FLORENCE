import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../config/routes.dart';
import '../../../main.dart';

/// Splash Screen
/// Shows app logo and checks authentication status
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }
  
  /// Check authentication status and navigate accordingly
  Future<void> _checkAuthAndNavigate() async {
    // Wait a bit to show splash screen
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    try {
      // Check if user is logged in
      final session = supabase.auth.currentSession;
      final user = supabase.auth.currentUser;
      
      if (session != null && user != null) {
        // User is logged in, go to dashboard
        AppRoutes.pushReplacement(context, AppRoutes.dashboard);
      } else {
        // User is not logged in, go to login
        AppRoutes.pushReplacement(context, AppRoutes.login);
      }
    } catch (e) {
      // Error checking auth (e.g., Supabase not configured)
      // In demo mode, just go to login
      debugPrint('Auth check error (Demo Mode): $e');
      if (mounted) {
        AppRoutes.pushReplacement(context, AppRoutes.login);
      }
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
            // Logo
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
            
            // App name
            Text(
              'BioTective Health',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            
            // Tagline
            Text(
              'Monitor your health, improve your life',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            
            // Loading indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}