import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'core/utils/helpers.dart';
import 'core/providers/theme_provider.dart';
// import 'config/admin_routes.dart';
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
  late final StreamSubscription<AuthState> _authSubscription;

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
        debugPrint('[Auth Listener] onAuthStateChange received event: ${data.event}');
        _handleNavigation(data.session);
      },
      onError: (error) {
        // This handles deep link errors (e.g., expired token).
        String message = 'An authentication error occurred. Please try again.';
        if (error is AuthException) {
          // Use the more specific message from Supabase if available and user-friendly
          if (error.message.contains('invalid or has expired')) {
            message = 'This confirmation link is invalid or has expired. Please try again.';
          } else {
            message = error.message; // Use the direct error message from Supabase
          }
        }
        debugPrint('[Auth Listener] onError: Navigating to login with message: "$message"');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          navigatorKey.currentState?.pushNamedAndRemoveUntil(
              AppRoutes.login, (route) => false,
              arguments: {'message': message});
        });
      },
    );
  }

  void _handleNavigation(Session? session) {
    // This function is now the single source of truth for navigation.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (session != null) {
        final user = session.user;
        final role = user.userMetadata?['role'];
        final isNewUser = user.createdAt != null &&
            DateTime.now().difference(DateTime.parse(user.createdAt!)).inMinutes < 2;
        String message = isNewUser ? 'Welcome! Your email has been successfully confirmed.' : 'Welcome back!';
        debugPrint('[Auth Listener] Session found. Role: $role. Navigating to dashboard.');
        if (role == 'PATIENT') {
          navigatorKey.currentState?.pushNamedAndRemoveUntil(AppRoutes.dashboard, (route) => false, arguments: {'message': message});
        } else if (role == 'CLINICIAN' || role == 'ADMIN') {
          navigatorKey.currentState?.pushNamedAndRemoveUntil(AppRoutes.clinicianDashboard, (route) => false, arguments: {'message': message});
        } else {
          navigatorKey.currentState?.pushNamedAndRemoveUntil(AppRoutes.login, (route) => false, arguments: {'message': 'Login failed: Unsupported user role.'});
        }
      } else {
        debugPrint('[Auth Listener] No session found. Navigating to login.');
        navigatorKey.currentState?.pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
      }
    });
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
