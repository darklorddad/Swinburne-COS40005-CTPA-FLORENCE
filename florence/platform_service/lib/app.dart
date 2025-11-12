import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'core/utils/helpers.dart';
import 'core/providers/theme_provider.dart';
import 'features/auth/services/auth_service.dart';
import 'features/patient/core/providers/health_data_provider.dart';
import 'features/patient/dashboard/screens/dashboard_screen.dart';
import 'features/auth/screens/login_screen.dart';

/// Main application widget
/// This sets up the MaterialApp with theme, routing, and providers

class App extends StatelessWidget {
  const App({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Our new AuthService provider
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => HealthDataProvider()),
      ],
      child: const AppRoot(),
    );
  }
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<Uri>? _linkSubscription;
  late Future<void> _authInitialization;

  @override
  void initState() {
    super.initState();
    // We create a future from the AuthService initialization
    _authInitialization = Provider.of<AuthService>(context, listen: false).tryAutoLogin();
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
      if (uri.fragment.contains('refresh_token=')) {
        final params = Uri.splitQueryString(uri.fragment);
        final refreshToken = params['refresh_token'];
        if (refreshToken != null) {
          debugPrint('[App] Found refresh token in deep link. Exchanging for backend token.');
          // Now we can safely call the provider because this widget is below MultiProvider.
          // We use .catchError to handle any exceptions during the async operation.
          Provider.of<AuthService>(context, listen: false)
              .exchangeToken(refreshToken)
              .catchError((e) {
            debugPrint("[App] Error during token exchange: $e");
            if (navigatorKey.currentContext != null) {
              Helpers.showError(navigatorKey.currentContext!, "Failed to verify email link. Please try again.");
            }
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Florence',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: Provider.of<ThemeProvider>(context).themeMode,
      home: FutureBuilder(
        // Use the FutureBuilder to show a splash screen during initialization
        future: _authInitialization,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen(); // Show splash while checking auth
          }
          
          // Once checked, use the Consumer to decide the screen
          return Consumer<AuthService>(
            builder: (context, authService, child) {
              return authService.isAuthenticated
                  ? const DashboardScreen()
                  : const LoginScreen();
            },
          );
        },
      ),
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
