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
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _rememberMe = false;
  String? _errorMessage; // Will hold errors from login attempts OR deep links
  bool _hasCheckedArgs = false; // Prevents re-checking arguments on every rebuild

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This runs when the screen is built and ensures we catch the incoming message
    if (!_hasCheckedArgs) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['message'] != null) {
        // Use postFrameCallback to avoid calling setState during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            _errorMessage = args['message'];
          });
        });
      }
      _hasCheckedArgs = true;
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
      final response = await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      if (response.user != null && mounted) {
        final role = response.user!.appMetadata?['role'];

        if (role == 'PATIENT') {
          Helpers.showSuccess(context, 'Welcome back!');
          AppRoutes.pushAndRemoveUntil(context, AppRoutes.dashboard);
        } else if (role == 'CLINICIAN') {
          Helpers.showSuccess(context, 'Welcome back, Clinician!');
          AppRoutes.pushAndRemoveUntil(context, AppRoutes.clinicianDashboard);
        } else {
          Helpers.showError(context, 'Your user role is not supported.');
          await supabase.auth.signOut();
        }
      }
    } on AuthException catch (error) {
      if (mounted) {
        setState(() => _errorMessage = error.message);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _errorMessage = 'An unexpected error occurred. Please try again.');
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
                    
                    // THIS IS THE NEW ERROR DISPLAY WIDGET
                    if (_errorMessage != null) ...[
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
                                _errorMessage!,
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
                      validator: (value) => Validators.required(
                        value,
                        fieldName: 'Password',
                      ),
                      textInputAction: TextInputAction.done,
                      validator: (value) => Validators.required(value, fieldName: 'Password'),
                      textInputAction: TextInputAction.done,
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
