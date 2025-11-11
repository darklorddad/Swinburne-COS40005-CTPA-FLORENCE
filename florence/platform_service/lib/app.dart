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
        // Use a post-frame callback to ensure the widget tree is built and ready for navigation.
        // This prevents race conditions during app startup.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleNavigation(data.session, data.event);
        });
      },
      onError: (error) {
        // This handles deep link errors (e.g., an expired token).
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final navigator = navigatorKey.currentState;
          if (navigator == null || !navigator.mounted) return;
          
          // On any auth error from a deep link, the safest action is to go to the login screen
          // with a clear message, regardless of the current session state.
          navigator.pushNamedAndRemoveUntil(
            AppRoutes.login,
            (route) => false,
            arguments: {'message': 'This confirmation link is invalid or has expired. Please try again.'},
          );
        });
      },
    );
  }

  void _handleNavigation(Session? session, AuthChangeEvent event) {
    final navigator = navigatorKey.currentState;
    if (navigator == null || !navigator.mounted) return;
    final currentRouteName = ModalRoute.of(navigator.context)?.settings.name;

    if (session != null) {
      // User is logged in.
      final user = session.user;
      final role = user.userMetadata?['role'];
      
      // More reliable way to check for a new user confirming their email via deep link.
      final isSignUpConfirmation = event == AuthChangeEvent.signedIn && user.createdAt != null &&
            DateTime.now().difference(DateTime.parse(user.createdAt!)).inMinutes < 2;

      String destinationRoute;
      if (role == 'PATIENT') {
        destinationRoute = AppRoutes.dashboard;
      } else if (role == 'CLINICIAN' || role == 'ADMIN') {
        destinationRoute = AppRoutes.clinicianDashboard;
      } else {
        // Unsupported role, force back to login with an error message.
        if (currentRouteName != AppRoutes.login) {
          navigator.pushNamedAndRemoveUntil(AppRoutes.login, (route) => false, arguments: {'message': 'Login failed: Unsupported user role.'});
        }
        return;
      }

      // Only navigate if we are not already on the destination screen.
      // This prevents navigation loops if the auth state changes for other reasons (e.g., token refresh).
      if (currentRouteName != destinationRoute) {
          final message = isSignUpConfirmation
              ? 'Welcome! Your email has been successfully confirmed.'
              : 'Welcome back!';
          navigator.pushNamedAndRemoveUntil(destinationRoute, (route) => false, arguments: {'message': message});
      }
    } else {
      // User is not logged in.
      // If we are not already on the login screen, navigate there.
      if (currentRouteName != AppRoutes.login) {
        navigator.pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
      }
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
