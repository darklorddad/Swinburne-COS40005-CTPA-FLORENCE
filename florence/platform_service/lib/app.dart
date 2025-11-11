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
  final Uri? initialUri;

  App({super.key, this.initialUri});

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

        // The SplashScreen is responsible for the initial navigation. This listener
        // handles all subsequent auth changes (logout, password recovery, etc.).
        // We MUST ignore the initialSession event to prevent a race condition.
        if (event == AuthChangeEvent.initialSession) {
          debugPrint('[App Listener] Ignoring initialSession event (handled by SplashScreen).');
          return;
        }

        // Use a post-frame callback to ensure the widget tree is built before navigating.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleNavigation(data);
        });
      },
      onError: (error) {
        debugPrint('[Auth Listener] Error: $error');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final nav = navigatorKey.currentState;
          if (nav?.mounted != true) return;

          // Clear stack and show login with error
          final message = 'Authentication failed. Please sign in again.';
          nav!.pushNamedAndRemoveUntil(
            AppRoutes.login,
            (route) => false,
            arguments: {'message': message},
          );
        });
      },
    );
  }

  void _handleNavigation(AuthState data) {
    debugPrint('[Auth Listener] Handling navigation for event: ${data.event}');
    final navigator = navigatorKey.currentState;
    if (navigator == null || !navigator.mounted) return;

    final session = data.session;
    debugPrint('[Auth Listener] Session is: ${session != null ? 'PRESENT' : 'NULL'}');

    // Only handle events AFTER initial session (SplashScreen handles initial session)
    if (data.event != AuthChangeEvent.initialSession) {
      if (session != null) {
        final user = session.user;
        final role = user.userMetadata?['role'];
        debugPrint('[App Listener] Post-initial session found. Role: $role. Navigating...');
        
        final isSignUpConfirmation = data.event == AuthChangeEvent.signedIn && 
            user.createdAt != null &&
            DateTime.now().difference(DateTime.parse(user.createdAt!)).inMinutes < 2;

        String destinationRoute;
        if (role == 'PATIENT') {
          destinationRoute = AppRoutes.dashboard;
        } else if (role == 'CLINICIAN' || role == 'ADMIN') {
          destinationRoute = AppRoutes.clinicianDashboard;
        } else {
          navigator.pushNamedAndRemoveUntil(AppRoutes.login, (route) => false, 
              arguments: {'message': 'Login failed: Unsupported user role.'});
          return;
        }

        final message = isSignUpConfirmation ? 
            'Welcome! Your email has been successfully confirmed.' : 
            'Welcome back!';
            
        navigator.pushNamedAndRemoveUntil(destinationRoute, (route) => false, 
            arguments: {'message': message});
      } else {
        // Handle sign out or session expiration
        debugPrint('[App Listener] No session found after initial. Navigating to login.');
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
              onGenerateRoute: (settings) {
                if (settings.name == AppRoutes.splash) {
                  // Pass the initialUri to the splash screen as an argument
                  return AppRoutes.generateRoute(
                    settings.copyWith(arguments: {'initialUri': widget.initialUri}),
                  );
                }
                return AppRoutes.generateRoute(settings);
              },

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
