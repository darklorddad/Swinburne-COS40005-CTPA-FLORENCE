import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'core/utils/helpers.dart';
import 'core/providers/theme_provider.dart';
import 'features/patient/core/providers/health_data_provider.dart';
import 'main.dart';

/// Main application widget
/// This sets up the MaterialApp with theme, routing, and providers

class App extends StatefulWidget {
  App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  StreamSubscription<AuthState>? _authSubscription;

  // Navigator key to allow navigation from outside the build context
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  void _setupAuthListener() {
    _authSubscription = supabase.auth.onAuthStateChange.listen(
      (data) {
        final event = data.event;
        debugPrint('[Auth Listener] Event received: $event');

        // Use a post-frame callback to ensure the widget tree is built before navigating.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleNavigation(data);
        });
      },
      onError: (error) {
        // This handles deep link errors (e.g., an expired token).
        debugPrint('[Auth Listener] Deep link error: $error');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final navigator = navigatorKey.currentState;
          if (navigator == null || !navigator.mounted) return;
          navigator.pushNamedAndRemoveUntil(
            AppRoutes.login,
            (route) => false,
            arguments: {'message': 'This confirmation link is invalid or has expired. Please try again.'},
          );
        });
      },
    );
  }

  void _handleNavigation(AuthState data) {
    debugPrint('[Auth Listener] Handling navigation for event: ${data.event}');
    final session = data.session;
    debugPrint('[Auth Listener] Session is: ${session != null ? 'PRESENT' : 'NULL'}');

    final navigator = navigatorKey.currentState;
    if (navigator == null || !navigator.mounted) return;

    final event = data.event;

    // A signedIn event means authentication was successful.
    // If a session object already exists (e.g., from a warm start), we also treat the user as logged in.
    if (event == AuthChangeEvent.signedIn || session != null) {
      debugPrint('[Auth Listener] Session found or signedIn event received. Navigating to authenticated route.');
      final user = session?.user ?? supabase.auth.currentUser; // Get user from session or client
      if (user == null) {
        debugPrint('[Auth Listener] ERROR: Signed in but user is null. Navigating to login.');
        navigator.pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
        return;
      }
      
      final role = user.userMetadata?['role'];
      debugPrint('[Auth Listener] User role: $role');

      final isSignUpConfirmation = data.event == AuthChangeEvent.signedIn && user.createdAt != null &&
            DateTime.now().difference(DateTime.parse(user.createdAt!)).inMinutes < 2;

      String destinationRoute;
      if (role == 'PATIENT' || role == 'CLINICIAN' || role == 'ADMIN') { // Added clinician and admin for robustness
        destinationRoute = AppRoutes.dashboard;
      } else {
        navigator.pushNamedAndRemoveUntil(AppRoutes.login, (route) => false, arguments: {'message': 'Login failed: Unsupported user role.'});
        return;
      }

      final message = isSignUpConfirmation ? 'Welcome! Your email has been successfully confirmed.' : 'Welcome back!';
      navigator.pushNamedAndRemoveUntil(destinationRoute, (route) => false, arguments: {'message': message});
    } else if (event == AuthChangeEvent.signedOut || (event == AuthChangeEvent.initialSession && session == null)) {
      // If the user signed out, or if this is the very first check and there's no session, go to login.
      debugPrint('[Auth Listener] No session found for initial check or sign out. Navigating to login.');
      navigator.pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
    } else {
      debugPrint('[Auth Listener] Unhandled navigation event: $event');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Theme provider for dark mode switching
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        // Health data provider for patient data management
        ChangeNotifierProvider(create: (_) => HealthDataProvider()),
        // Add more providers here as needed
        // ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          // Dynamic system UI overlay based on theme
          final isDark = themeProvider.isDarkMode;
          final systemUiOverlay = SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
            systemNavigationBarColor: isDark ? const Color(0xFF1F2937) : Colors.white,
            systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          );

          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: systemUiOverlay,
            child: MaterialApp(
              navigatorKey: navigatorKey, // Assign the key here
              title: 'Florence',
              debugShowCheckedModeBanner: false,

              // Theme with dynamic mode switching
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeProvider.themeMode,

              // Routing
              initialRoute: AppRoutes.splash,
              onGenerateRoute: AppRoutes.generateRoute,

              // Localization (for future use)
              // localizationsDelegates: const [
              //   GlobalMaterialLocalizations.delegate,
              //   GlobalWidgetsLocalizations.delegate,
              //   GlobalCupertinoLocalizations.delegate,
              // ],
              // supportedLocales: const [
              //   Locale('en', 'US'),
              //   Locale('ms', 'MY'),
              // ],
            ),
          );
        },
      ),
    );
  }
}
