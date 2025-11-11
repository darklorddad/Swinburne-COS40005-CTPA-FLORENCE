import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/environment.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/helpers.dart';
import '../../../shared/widgets/button_widgets.dart';
import '../../../shared/widgets/input_widgets.dart';
import '../../../config/theme.dart';
import '../../../config/routes.dart';
import '../../../main.dart';

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
  
  bool _isLoading = false;
  bool _rememberMe = false;
  String? _errorMessage;
  bool _hasShownRouteError = false; // Add this flag to show the toast only once

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check for a message passed from navigation arguments (e.g., from an invalid deep link).
    // This is the ideal place to handle one-time actions when a screen is pushed with arguments.
    if (!_hasShownRouteError) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
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
      _isLoading = true;
      _errorMessage = null; // Clear previous errors on a new attempt
    });
    
    try {
      // Call the backend API instead of Supabase directly
      final response = await http.post(
        Uri.parse('${Environment.apiUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        // Backend returns the session object on success
        final session = jsonDecode(response.body);
        final accessToken = session['access_token'];
        final refreshToken = session['refresh_token'];

        if (accessToken != null && refreshToken != null) {
          // Manually set the session in the Supabase client.
          // This is crucial as it will trigger the onAuthStateChange listener in app.dart
          // which handles all the navigation logic.
          await supabase.auth.setSession(accessToken, refreshToken: refreshToken);
        } else {
          // If the server response is malformed
          throw Exception('Invalid session returned from the server.');
        }
      } else {
        // If the backend returns an error (e.g., 401 Unauthorized)
        final errorBody = jsonDecode(response.body);
        // The backend's error message is in the 'detail' field
        throw Exception(errorBody['detail'] ?? 'An unknown error occurred.');
      }
    } catch (error) {
      // Catch backend errors, network errors, etc.
      if (mounted) {
        final errorMessage = error.toString().replaceFirst('Exception: ', '');
        
        // The backend doesn't distinguish "Email not confirmed" from "Invalid credentials".
        // It returns the same "Login failed: Invalid login credentials" for both.
        // We can check for that specific message to provide a hint.
        if (errorMessage.contains('Invalid login credentials')) {
          setState(() => _errorMessage = 'Invalid email or password. Please also check if you have confirmed your email.');
        } else {
          setState(() => _errorMessage = errorMessage);
        }
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
    // TODO: Implement forgot password screen
    Helpers.showInfo(context, 'Forgot password feature coming soon');
  }
  
  @override
  Widget build(BuildContext context) {
    // We no longer need to read arguments here, as it's handled in didChangeDependencies.
    // The only message we need to display as part of the layout is for failed login attempts.
    final displayMessage = _errorMessage;
    
    debugPrint('[LoginScreen] build called. State message: "$_errorMessage", Displaying: "$displayMessage"');

    // Responsive sizing
    final isDesktop = Helpers.isDesktop(context);
    final maxWidth = isDesktop ? 400.0 : double.infinity;
    
    return Scaffold(
      body: SafeArea(
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
                    
                    // Display an in-screen error message ONLY for failed login attempts.
                    // Deep link errors are now handled by the toast in didChangeDependencies.
                    if (displayMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppTheme.errorColor, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                displayMessage,
                                style: const TextStyle(color: AppTheme.errorColor, fontSize: 13),
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
                      validator: (value) => Validators.required(value, fieldName: 'Password'),
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
    );
  }
  
  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withOpacity(0.1),
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
  
  /// Build remember me checkbox and forgot password link
  Widget _buildRememberMeRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Remember me checkbox
        Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: _rememberMe,
                onChanged: _isLoading
                    ? null
                    : (value) {
                        setState(() => _rememberMe = value ?? false);
                      },
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Remember me',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        
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
