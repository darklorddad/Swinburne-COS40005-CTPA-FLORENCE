import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:florence/config/theme.dart';
import 'package:florence/config/routes.dart';
import 'package:florence/core/services/api_service.dart';
import 'package:florence/core/providers/theme_provider.dart';
import 'package:florence/features/admin/core/services/admin_auth_service.dart';
import 'package:florence/main.dart';
import 'package:florence/features/patient/core/providers/monitor_data_providers.dart';
import 'package:florence/features/patient/profile/providers/user_profile_provider.dart';
import 'package:florence/features/patient/chat/services/chatbot_service.dart';
import 'package:florence/features/patient/recommendations/services/recommendation_engine.dart';
import 'package:florence/core/services/notifications/notification_service.dart';

/// Main application widget
/// This sets up the MaterialApp with theme, routing, and providers

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  StreamSubscription<AuthState>? _authSubscription;
  StreamSubscription<Uri>? _linkSubscription;
  final ApiService _apiService = ApiService();
  bool _isAuthenticated = false;

  // Navigator key to allow navigation from outside the build context
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _isAuthenticated = supabase.auth.currentSession != null;
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
    _linkSubscription = appLinks.uriLinkStream.listen((uri) async {
      debugPrint('[App] Received deep link: $uri');
      // Manually handle the session recovery from the deep link fragment.
      if (uri.fragment.contains('refresh_token=')) {
        final params = Uri.splitQueryString(uri.fragment);
        final refreshToken = params['refresh_token'];
        if (refreshToken != null) {
          debugPrint('[App] Found refresh token in deep link. Manually setting session.');
          try {
            // This will trigger the onAuthStateChange listener to handle navigation.
            await supabase.auth.setSession(refreshToken);
          } on AuthException catch (error) {
            debugPrint('[Deep Link] Error setting session from deep link: $error');
            final nav = navigatorKey.currentState;
            if (nav?.mounted != true) return;

            const message = 'This confirmation link is invalid or has expired';

            nav!.pushNamedAndRemoveUntil(
              AppRoutes.login,
              (route) => false,
              arguments: {'message': message},
            );
          }
        }
      }
    });
  }

  void _setupAuthListener() {
    _authSubscription = supabase.auth.onAuthStateChange.listen(
      (data) {
        final event = data.event;
        final session = data.session;
        debugPrint('[Auth Listener] Event received: $event');

        // Ignore background token refreshes to prevent unwanted navigation/resets.
        // We only skip if we are already authenticated. If we are not (e.g. during login),
        // we must process the event to navigate to the dashboard.
        if (event == AuthChangeEvent.tokenRefreshed && _isAuthenticated) {
          debugPrint('[Auth Listener] Token refreshed in background. Skipping navigation.');
          return;
        }

        // Update local auth state
        _isAuthenticated = session != null;

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

          String message = 'Authentication failed. Please try again';
          if (error is AuthException) {
            final errorMessage = error.message.toLowerCase();
            // Check for token-related errors that occur with deep links
            if ((errorMessage.contains('invalid') && errorMessage.contains('token')) ||
                errorMessage.contains('expired')) {
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
      // Force invalidate providers on fresh login to prevent seeing previous user's data
      if (data.event == AuthChangeEvent.signedIn || data.event == AuthChangeEvent.passwordRecovery) {
        debugPrint('[App Listener] Sign-in detected. Invalidating providers to clear stale data.');
        ref.invalidate(monitorDataProvider);
        ref.invalidate(userProfileProvider);
        ref.invalidate(chatProvider);
        ref.invalidate(recommendationProvider);
        ref.invalidate(notificationProvider);
      }

      // The ApiService now gets the token directly from the Supabase client.
      // No need to manually manage the token in SessionManager.
      debugPrint('[App Listener] Session found. Token is available via supabase.auth.currentSession.');

      final user = session.user;

      // Detect if this is a brand new account (less than 5 mins old, handling clock skew)
      final createdAt = DateTime.parse(user.createdAt).toUtc();
      final diffMinutes = DateTime.now().toUtc().difference(createdAt).inMinutes.abs();
      final isNewUser = data.event == AuthChangeEvent.signedIn && diffMinutes < 5;

      dynamic backendUser;
      try {
        // Notify the backend of the new session by fetching user data.
        // This validates the token with the backend and allows it to create a server-side session.
        backendUser = await _apiService.get('/auth/me');
        debugPrint('[App Listener] Backend session validated successfully.');
      } catch (e) {
        // If the user is not found on the backend during the first login after email confirmation,
        // it means we need to create their profile on our backend.
        if (isNewUser && e.toString().contains('Not Found')) {
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
              arguments: {'message': 'Failed to create your profile. Please contact support'},
            );
            return; // Stop processing
          }
        } else {
          // Check if this is a network error vs an actual auth error
          final errorStr = e.toString().toLowerCase();
          final isNetworkError = errorStr.contains('socketexception') || 
                                 errorStr.contains('clientexception') || 
                                 errorStr.contains('connection') ||
                                 errorStr.contains('host lookup');

          if (isNetworkError) {
             debugPrint('[App Listener] Network error during validation. Proceeding with local session. Error: $e');
             // Proceed to navigation below. We trust the local Supabase token if the backend is just unreachable.
          } else {
            // Real auth error (401/403/404/500 from API)
            debugPrint('[App Listener] Backend session validation failed (Auth Error): $e');
            await supabase.auth.signOut();
            navigator.pushNamedAndRemoveUntil(
              AppRoutes.login,
              (route) => false,
              arguments: {'message': 'Session expired. Please log in again'},
            );
            return; // Stop processing
          }
        }
      }

      // Determine user role from Supabase auth metadata
      final userRole = session.user.appMetadata['role'] as String? ?? 'PATIENT';
      debugPrint('[App Listener] Session found. Role: $userRole. Navigating...');

      String destinationRoute;
      if (userRole.toUpperCase() == 'PATIENT') {
        AdminAuthService().logout(); // Ensure admin state is cleared
        destinationRoute = AppRoutes.dashboard;
      } else if (userRole.toUpperCase() == 'CLINICIAN') {
        AdminAuthService().logout(); // Ensure admin state is cleared
        destinationRoute = AppRoutes.clinicianDashboard;
      } else if (userRole.toUpperCase() == 'ADMIN') {
        destinationRoute = AppRoutes.adminDashboard;
      } else {
        navigator.pushNamedAndRemoveUntil(AppRoutes.login, (route) => false,
            arguments: {'message': 'Login failed: Unsupported user role'});
        return;
      }

      final message = isNewUser
          ? 'Welcome to Florence!'
          : 'Welcome back!';

      navigator.pushNamedAndRemoveUntil(destinationRoute, (route) => false,
          arguments: {'message': message});
    } else {
      // Handle sign out, session expiration, or no initial session
      debugPrint('[App Listener] No session found. Navigating to login.');

      // Invalidate Riverpod providers to clear user data
      ref.invalidate(monitorDataProvider);
      ref.invalidate(userProfileProvider);
      ref.invalidate(chatProvider);
      ref.invalidate(recommendationProvider);
      ref.invalidate(notificationProvider);

      // Clear admin session state as well
      AdminAuthService().logout();

      // Ensure we clear the stack and go to login
      navigator.pushNamedAndRemoveUntil(
        AppRoutes.login,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    // Dynamic system UI overlay based on theme
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
        themeMode: themeMode,

        // Routing
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRoutes.generateRoute,
      ),
    );
  }
}
