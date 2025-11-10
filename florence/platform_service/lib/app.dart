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
    // Handle the initial auth state right away
    _handleNavigation(supabase.auth.currentSession);

    // Then, listen for any future changes
    _authSubscription = supabase.auth.onAuthStateChange.listen(
      (data) {
        final event = data.event;
        // This listener handles auth changes that happen AFTER the app's initial load,
        // such as a user signing out or a sign-in from a deep link while the app is already open.
        if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.signedOut) {
          debugPrint('[Auth Listener] Auth state changed: $event. Handling navigation.');
          _handleNavigation(data.session);
        }
      },
      onError: (error) {
        // This handles deep link errors (e.g., expired token).
        if (error is AuthException) {
          String message = 'This confirmation link is invalid or has expired. Please try again.';
          WidgetsBinding.instance.addPostFrameCallback((_) {
            navigatorKey.currentState?.pushNamedAndRemoveUntil(
                AppRoutes.login, (route) => false, arguments: {'message': message});
          });
        }
      },
    );
  }

  void _handleNavigation(Session? session) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigator = navigatorKey.currentState;
      if (navigator == null) return;
      final context = navigator.context;
      final currentRouteName = ModalRoute.of(context)?.settings.name;

      if (session != null) {
        final user = session.user;
        final role = user.userMetadata?['role'];
        final isNewUser = user.createdAt != null &&
            DateTime.now().difference(DateTime.parse(user.createdAt!)).inMinutes < 2;
        String message = isNewUser
            ? 'Welcome! Your email has been successfully confirmed.'
            : 'Welcome back!';

        String destinationRoute;
        Object? routeArguments = {'message': message};

        if (role == 'PATIENT') {
          destinationRoute = AppRoutes.dashboard;
        } else if (role == 'CLINICIAN' || role == 'ADMIN') {
          destinationRoute = AppRoutes.clinicianDashboard;
        } else {
          destinationRoute = AppRoutes.login;
          routeArguments = {'message': 'Login failed: Unsupported user role.'};
        }

        if (currentRouteName != destinationRoute) {
          navigator.pushNamedAndRemoveUntil(destinationRoute, (route) => false,
              arguments: routeArguments);
        }
      } else {
        // If we are not already on the login screen, navigate there.
        if (currentRouteName != AppRoutes.login) {
          debugPrint('[Auth Listener] No session found. Navigating to login.');
          navigator.pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
        }
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
