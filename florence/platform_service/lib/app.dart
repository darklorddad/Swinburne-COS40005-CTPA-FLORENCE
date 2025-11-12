import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'core/services/api_service.dart';
import 'core/utils/helpers.dart';
import 'core/providers/settings_provider.dart';
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
  StreamSubscription<Uri>? _linkSubscription;
  final ApiService _apiService = ApiService();

  // Navigator key to allow navigation from outside the build context
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
    _setupDeepLinkListener();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _linkSubscription?.cancel();
    super.dispose();
  }

  void _setupDeepLinkListener() {
    final appLinks = AppLinks();
    _linkSubscription = appLinks.uriLinkStream.listen((uri) {
      debugPrint('[App] Received deep link: $uri');
      // Manually handle the session recovery from the deep link fragment.
      if (uri.fragment.contains('refresh_token=')) {
        final params = Uri.splitQueryString(uri.fragment);
        final refreshToken = params['refresh_token'];
        if (refreshToken != null) {
          debugPrint('[App] Found refresh token in deep link. Manually setting session.');
          // This will trigger the onAuthStateChange listener to handle navigation.
          supabase.auth.setSession(refreshToken);
        }
      }
    });
  }

  void _setupAuthListener() {
    _authSubscription = supabase.auth.onAuthStateChange.listen(
      (data) {
        final event = data.event;
        debugPrint('[Auth Listener] Event received: $event');

        // This listener is the single source of truth for auth-based navigation.
        // It handles all auth events: initial session, sign in, sign out, password recovery, etc.
        // We use a post-frame callback to ensure the widget tree is built before navigating.
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await _handleNavigation(data);
        });
      },
      onError: (error) {
        debugPrint('[Auth Listener] Error: $error');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final nav = navigatorKey.currentState;
          if (nav?.mounted != true) return;

          String message = 'Authentication failed, please try again';
          if (error is AuthException) {
            final errorMessage = error.message.toLowerCase();
            if (errorMessage.contains('invalid refresh token') ||
                errorMessage.contains('token has expired')) {
              message = 'This confirmation link is invalid or has expired';
            }
          }

          // Clear stack and show login with error
          nav!.pushNamedAndRemoveUntil(
            AppRoutes.login,
            (route) => false,
            arguments: {'message': message},
          );
        });
      },
    );
  }

  Future<void> _handleNavigation(AuthState data) async {
    debugPrint('[Auth Listener] Handling navigation for event: ${data.event}');
    final navigator = navigatorKey.currentState;
    if (navigator == null || !navigator.mounted) return;

    final session = data.session;
    debugPrint('[Auth Listener] Session is: ${session != null ? 'PRESENT' : 'NULL'}');

    if (session != null) {
      // Store the token for ApiService to use
      SessionManager.currentToken = session.accessToken;
      debugPrint('[App Listener] Session token stored in SessionManager.');

      final user = session.user;

      // This logic handles deep link sign-ins (email confirmation)
      final isSignUpConfirmation = data.event == AuthChangeEvent.signedIn &&
          user.createdAt != null &&
          DateTime.now().difference(DateTime.parse(user.createdAt!)).inMinutes <
              2;

      dynamic backendUser;
      try {
        // Notify the backend of the new session by fetching user data.
        // This validates the token with the backend and allows it to create a server-side session.
        backendUser = await _apiService.get('/auth/me');
        debugPrint('[App Listener] Backend session validated successfully.');
      } catch (e) {
        // If the user is not found on the backend during the first login after email confirmation,
        // it means we need to create their profile on our backend.
        if (isSignUpConfirmation && e.toString().contains('Not Found')) {
          debugPrint('[App Listener] User not found on backend. Attempting to sync profile.');
          try {
            // This endpoint should trigger the backend to create a user record
            // using the data from the JWT.
            await _apiService.post('/users/sync', {});
            debugPrint('[App Listener] User profile synced successfully.');
            // After syncing, we need to fetch the user data again.
            backendUser = await _apiService.get('/auth/me');
          } catch (syncError) {
            debugPrint('[App Listener] Failed to sync user profile: $syncError');
            await supabase.auth.signOut();
            navigator.pushNamedAndRemoveUntil(
              AppRoutes.login,
              (route) => false,
              arguments: {'message': 'Failed to create your profile, please contact support'},
            );
            return; // Stop processing
          }
        } else {
          // For any other error, or if the user is not found on a subsequent login,
          // treat it as a validation failure.
          debugPrint('[App Listener] Backend session validation failed: $e');
          await supabase.auth.signOut();
          navigator.pushNamedAndRemoveUntil(
            AppRoutes.login,
            (route) => false,
            arguments: {'message': 'Session validation failed, please log in again'},
          );
          return; // Stop processing
        }
      }

      // The user object from the backend is now the source of truth for the role.
      final role = backendUser?['user_metadata']?['role'];
      debugPrint('[App Listener] Session found. Role: $role. Navigating...');

      String destinationRoute;
      if (role == 'PATIENT') {
        destinationRoute = AppRoutes.dashboard;
      } else if (role == 'CLINICIAN' || role == 'ADMIN') {
        destinationRoute = AppRoutes.clinicianDashboard;
      } else {
        navigator.pushNamedAndRemoveUntil(AppRoutes.login, (route) => false,
            arguments: {'message': 'Login failed: Unsupported user role'});
        return;
      }

      final message = isSignUpConfirmation
          ? 'Welcome! Your email has been successfully confirmed.'
          : 'Welcome back!';

      navigator.pushNamedAndRemoveUntil(destinationRoute, (route) => false,
          arguments: {'message': message});
    } else {
      // Handle sign out, session expiration, or no initial session
      debugPrint('[App Listener] No session found. Navigating to login.');
      SessionManager.currentToken = null; // Clear the token on sign out
      navigator.pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),

        // Health data provider, dependent on SettingsProvider
        ChangeNotifierProxyProvider<SettingsProvider, HealthDataProvider>(
          create: (context) => HealthDataProvider(),
          update: (context, settings, healthData) {
            if (healthData == null) return HealthDataProvider();
            healthData.update(settings);
            return healthData;
          },
        ),
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
