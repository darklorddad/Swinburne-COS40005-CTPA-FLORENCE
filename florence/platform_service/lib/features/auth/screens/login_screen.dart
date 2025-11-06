import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  // Form key for validation
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // State
  bool _isLoading = false;
  bool _rememberMe = false;
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  /// Handle login
  Future<void> _handleLogin() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    // Hide keyboard
    Helpers.hideKeyboard(context);
    
    setState(() => _isLoading = true);
    
    try {
      final response = await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      if (response.user != null && mounted) {
        // Check user role and navigate accordingly
        final role = response.user!.appMetadata?['role'];

        if (role == 'PATIENT') {
          Helpers.showSuccess(context, 'Welcome back!');
          AppRoutes.pushAndRemoveUntil(context, AppRoutes.dashboard);
        } else if (role == 'CLINICIAN') {
          Helpers.showSuccess(context, 'Welcome back, Clinician!');
          AppRoutes.pushAndRemoveUntil(context, AppRoutes.clinicianDashboard);
        } else {
          // Role not supported or not found
          Helpers.showError(context, 'Your user role is not supported in this application.');
          await supabase.auth.signOut();
        }
      }
    } on AuthException catch (error) {
      if (mounted) {
        Helpers.showError(context, error.message);
      }
    } catch (error) {
      if (mounted) {
        Helpers.showError(context, 'An unexpected error occurred. Please try again.');
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
                    
                    // Email field
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
                      validator: (value) => Validators.required(
                        value,
                        fieldName: 'Password',
                      ),
                      textInputAction: TextInputAction.done,
                      onChanged: (_) {
                        // Clear error when user types
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
  
  /// Build header with logo and title
  Widget _buildHeader() {
    return Column(
      children: [
        // Logo (you can replace with actual logo)
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
        
        // App name
        Text(
          'Florence',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        
        // Subtitle
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
