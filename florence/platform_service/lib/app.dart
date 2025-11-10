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
  StreamSubscription<AuthState>? _authSubscription;

  // Navigator key to allow navigation from outside the build context
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  bool _hasHandledInitialAuth = false; // Prevents multiple initial navigations

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
      (data) async {
        final session = data.session;
        final event = data.event;

        // Handle initial session check only once on app start
        if (event == AuthChangeEvent.initialSession && !_hasHandledInitialAuth) {
          _hasHandledInitialAuth = true;
          // A small delay to allow the splash screen to render smoothly
          await Future.delayed(const Duration(milliseconds: 500));
          _handleNavigation(session);
        }
        // Handle sign-in events (e.g., from a deep link after the app is already running)
        else if (event == AuthChangeEvent.signedIn) {
          _handleNavigation(session);
        }
        // Handle sign-out events
        else if (event == AuthChangeEvent.signedOut) {
          _handleNavigation(null);
        }
      },
      onError: (error) {
        String message = 'An authentication error occurred. Please try again.';
        if (error is AuthException) {
          // Use the more specific message from Supabase if available and user-friendly
          if (error.message.contains('invalid or has expired')) {
            message = 'This confirmation link is invalid or has expired. Please try again.';
          } else {
            message = error.message; // Use the direct error message from Supabase
          }
        }
        // Ensure the navigator is ready before trying to push a new route.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          navigatorKey.currentState?.pushNamedAndRemoveUntil(
              AppRoutes.login, (route) => false,
              arguments: {'message': message});
        });
      },
    );
  }

  void _handleNavigation(Session? session) {
    if (session != null) {
      final user = session.user;
      final role = user.userMetadata?['role'];
      String message = 'Welcome! Your email has been successfully confirmed.';
      if (role == 'PATIENT') {
        navigatorKey.currentState?.pushNamedAndRemoveUntil(AppRoutes.dashboard, (route) => false, arguments: {'message': message});
      } else if (role == 'CLINICIAN' || role == 'ADMIN') {
        navigatorKey.currentState?.pushNamedAndRemoveUntil(AppRoutes.clinicianDashboard, (route) => false, arguments: {'message': message});
      } else {
        navigatorKey.currentState?.pushNamedAndRemoveUntil(AppRoutes.login, (route) => false, arguments: {'message': 'Login failed: Unsupported user role.'});
      }
    } else {
      navigatorKey.currentState?.pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
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
