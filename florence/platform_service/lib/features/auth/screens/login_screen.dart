import 'package:flutter/material.dart';
import 'package:florence/core/services/api_service.dart';
import 'package:florence/core/utils/validators.dart';
import 'package:florence/core/utils/helpers.dart';
import 'package:florence/shared/widgets/button_widgets.dart';
import 'package:florence/shared/widgets/input_widgets.dart';
import 'package:florence/config/theme.dart';
import 'package:florence/config/routes.dart';
import 'package:florence/main.dart';

/// Login Screen
/// Allows users to sign in with email and password
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  String? _errorMessage;
  bool _hasShownRouteError = false; // Add this flag to show the toast only once

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check for a message passed from navigation arguments (e.g., from an invalid deep link).
    // This is the ideal place to handle one-time actions when a screen is pushed with arguments.
    if (!_hasShownRouteError) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final routeMessage = args?['message'] as String?;
      if (routeMessage != null) {
        // Schedule the snackbar to show after the build is complete to avoid build-time errors.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Helpers.showError(context, routeMessage);
        });
        // Set the flag to true so this message is only shown once per navigation event.
        _hasShownRouteError = true;
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Helpers.hideKeyboard(context);
    setState(() {
      _errorMessage = null; // Clear previous errors
      _isLoading = true;
    });

    try {
      debugPrint(
          '[Login Screen] Attempting login for user: ${_emailController.text.trim()}');

      // Call the backend API using ApiService
      final session = await _apiService.post('/auth/login', {
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
      });

      final refreshToken = session['refresh_token'];

      if (refreshToken != null) {
        // Manually set the session using the refresh token. The Supabase client
        // will use this to fetch a valid access token and establish the session.
        debugPrint(
            '[Login Screen] Login API call successful. Setting session with refresh token.');
        // This will trigger the onAuthStateChange listener in app.dart.
        await supabase.auth.setSession(refreshToken);
      } else {
        // If the server response is malformed
        throw Exception('Invalid session returned from the server.');
      }
    } catch (error) {
      // Catch backend errors, network errors, etc.
      if (mounted) {
        var errorMessage = error.toString().replaceFirst('Exception: ', '');
        // The backend returns a generic message for both invalid credentials and unconfirmed email.
        if (errorMessage.contains('Invalid login credentials')) {
          errorMessage =
              'Invalid email or password. Please also check if you have confirmed your email';
        }
        setState(() => _errorMessage = errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Navigate to registration
  void _goToRegister() {
    AppRoutes.push(context, AppRoutes.register);
  }

  /// Navigate to forgot password
  void _goToForgotPassword() {
    Helpers.showInfo(context, 'Forgot password feature coming soon');
  }

  @override
  Widget build(BuildContext context) {
    // Responsive sizing
    final isDesktop = Helpers.isDesktop(context);
    final maxWidth = isDesktop ? 400.0 : double.infinity;

    // Manual handling of bottom insets to fix mobile web keyboard glitch
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo and Title
                      _buildHeader(),
                      const SizedBox(height: 48),

                      // Display an in-screen error message for failed login attempts.
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: AppTheme.errorColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: AppTheme.errorColor, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                      color: AppTheme.errorColor, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      CustomTextField(
                        label: 'Email',
                        hint: 'Enter your email',
                        controller: _emailController,
                        validator: Validators.email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        prefixIcon: const Icon(Icons.email_outlined),
                        enabled: !_isLoading,
                      ),
                      const SizedBox(height: 16),

                      // Password field
                      PasswordField(
                        label: 'Password',
                        hint: 'Enter your password',
                        controller: _passwordController,
                        validator: (value) => Validators.minLength(value, 1,
                            fieldName: 'Password'),
                        textInputAction: TextInputAction.done,
                        onChanged: (value) {
                          // When user starts typing a new password, clear the error message
                          if (_errorMessage != null) {
                            setState(() {
                              _errorMessage = null;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Remember me and forgot password row
                      _buildRememberMeRow(),
                      const SizedBox(height: 32),

                      // Login button
                      PrimaryButton(
                        text: 'Sign In',
                        onPressed: _isLoading ? null : _handleLogin,
                        isLoading: _isLoading,
                        width: double.infinity,
                      ),
                      const SizedBox(height: 16),

                      // Divider
                      _buildDivider(),
                      const SizedBox(height: 16),

                      // Register link
                      _buildRegisterLink(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.favorite_rounded,
            size: 40,
            color: AppTheme.primaryBlue,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Florence',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Monitor your health, improve your life',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Build forgot password link
  Widget _buildRememberMeRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Forgot password link
        TextButton(
          onPressed: _isLoading ? null : _goToForgotPassword,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 0),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Forgot password?',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }

  /// Build divider with "or" text
  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: AppTheme.borderColor,
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
          ),
        ),
        Expanded(
          child: Divider(
            color: AppTheme.borderColor,
            thickness: 1,
          ),
        ),
      ],
    );
  }

  /// Build register link
  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        TextButton(
          onPressed: _isLoading ? null : _goToRegister,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 0),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Sign Up',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      ],
    );
  }
}
