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
  Timer? _splashTimeoutTimer;

  // Navigator key to allow navigation from outside the build context
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    // The Supabase client automatically handles listening for deep links.
    // Our onAuthStateChange listener is all that's needed to react to them.
    _setupAuthListener();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _splashTimeoutTimer?.cancel();
    super.dispose();
  }

  void _setupAuthListener() {
    _authSubscription = supabase.auth.onAuthStateChange.listen(
      (data) {
        // Use a post-frame callback to ensure the widget tree is built before navigating.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleNavigation(data);
        });
      },
      onError: (error) {
        // This handles deep link errors (e.g., an expired token).
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
    final navigator = navigatorKey.currentState;
    if (navigator == null || !navigator.mounted) return;

    // Any auth event (signIn, signOut, etc.) means the initial state is resolved,
    // so we can cancel the splash screen timeout timer if it's running.
    _splashTimeoutTimer?.cancel();

    if (data.session != null) {
      // USER IS LOGGED IN
      final user = data.session!.user;
      final role = user.userMetadata?['role'];

      String destinationRoute;
      if (role == 'PATIENT') {
        destinationRoute = AppRoutes.dashboard;
      } else if (role == 'CLINICIAN' || role == 'ADMIN') {
        destinationRoute = AppRoutes.clinicianDashboard;
      } else {
        // Unsupported role, force back to login.
        navigator.pushNamedAndRemoveUntil(AppRoutes.login, (route) => false, arguments: {'message': 'Login failed: Unsupported user role.'});
        return;
      }
      
      // Check if this is a new user confirming their email via a deep link.
      final isSignUpConfirmation = data.event == AuthChangeEvent.signedIn && user.createdAt != null &&
            DateTime.now().difference(DateTime.parse(user.createdAt!)).inMinutes < 2;

      final message = isSignUpConfirmation
          ? 'Welcome! Your email has been successfully confirmed.'
          : 'Welcome back!';
      
      navigator.pushNamedAndRemoveUntil(destinationRoute, (route) => false, arguments: {'message': message});

    } else {
      // USER IS NOT LOGGED IN
      // On a cold start, the first event is 'initialSession'. If the session is null,
      // we start a timer. If no other auth event (like a `signedIn` from a deep link)
      // occurs before the timer finishes, we know the user is truly logged out.
      if (data.event == AuthChangeEvent.initialSession) {
        _splashTimeoutTimer = Timer(const Duration(seconds: 1), () {
          navigator.pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
        });
      } else {
        // For any other event where the session is null (like a `signedOut` event),
        // we can navigate to the login screen immediately.
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
