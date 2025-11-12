import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'core/utils/helpers.dart';
import 'core/providers/theme_provider.dart';
import 'features/auth/services/auth_service.dart';
import 'features/patient/core/providers/health_data_provider.dart';
import 'main.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/patient/dashboard/screens/dashboard_screen.dart';

/// Main application widget
/// This sets up the MaterialApp with theme, routing, and providers

class App extends StatefulWidget {
  App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  StreamSubscription<Uri>? _linkSubscription;

  // Navigator key to allow navigation from outside the build context
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _setupDeepLinkListener();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  void _setupDeepLinkListener() {
    final appLinks = AppLinks();
    _linkSubscription = appLinks.uriLinkStream.listen((uri) {
      debugPrint('[App] Received deep link: $uri');
      // Manually handle the session recovery from the deep link fragment.
      if (uri.fragment.contains('refresh_token=')) {
        try {
          final params = Uri.splitQueryString(uri.fragment);
          final refreshToken = params['refresh_token'];
          if (refreshToken != null) {
            debugPrint('[App] Found refresh token in deep link. Exchanging for backend token.');
            // Use the AuthService to exchange the token. This will trigger the auth state change.
            Provider.of<AuthService>(context, listen: false).exchangeToken(refreshToken);
          }
        } catch (e) {
          debugPrint("[App] Error exchanging token from deep link: $e");
          Helpers.showError(navigatorKey.currentContext!, "Failed to verify email link.");
        }
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Our new AuthService provider
        ChangeNotifierProvider(create: (_) => AuthService()),
        // Theme provider for dark mode switching
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        // Health data provider for patient data management
        ChangeNotifierProvider(create: (_) => HealthDataProvider()),
        // Add more providers here as needed
        // ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: Consumer2<ThemeProvider, AuthService>(
        builder: (context, themeProvider, authService, _) {
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

              // Routing - now driven by our AuthService
              home: authService.isAuthenticated
                  ? const DashboardScreen() // Or a screen that decides based on role
                  : const LoginScreen(),

              // We still need the route generator for other navigation
              // But the initial route is now controlled by the home property
              onGenerateRoute: (settings) {
                if (settings.name == AppRoutes.login) {
                  return MaterialPageRoute(builder: (_) => const LoginScreen());
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
