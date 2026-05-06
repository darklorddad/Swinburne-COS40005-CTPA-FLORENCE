import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:florence/core/services/api_service.dart';
import 'package:florence/core/utils/validators.dart';
import 'package:florence/core/utils/helpers.dart';
import 'package:florence/shared/widgets/button_widgets.dart';
import 'package:florence/shared/widgets/input_widgets.dart';
import 'package:florence/config/theme.dart';
import 'package:florence/config/routes.dart';

/// Registration Screen
/// Allows new users to create an account
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Form key for validation
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  // State
  bool _isLoading = false;
  bool _acceptTerms = false;
  
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
  
  /// Handle registration
  Future<void> _handleRegister() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check if terms are accepted
    if (!_acceptTerms) {
      Helpers.showWarning(
        context,
        'Please accept the terms and conditions to continue',
      );
      return;
    }

    // Hide keyboard
    Helpers.hideKeyboard(context);

    setState(() => _isLoading = true);

    try {
      // Call the backend API using ApiService
      await _apiService.post('/auth/register', {
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'role': 'PATIENT', // Hardcoded for patient registration
        'name': _nameController.text.trim(),
      });

      if (mounted) {
        Helpers.showSuccess(
          context,
          'Registered successfully! Please check your email for verification',
        );
        AppRoutes.pop(context); // Go back to login screen
      }
    } catch (error) {
      if (mounted) {
        Helpers.showError(context, error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  /// Navigate back to login
  void _goToLogin() {
    AppRoutes.pop(context);
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
      appBar: AppBar(
        title: const Text('Create Account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isLoading ? null : _goToLogin,
        ),
      ),
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    _buildHeader(),
                    const SizedBox(height: 32),
                    
                    // Name field
                    CustomTextField(
                      label: 'Name',
                      hint: 'Enter your name',
                      controller: _nameController,
                      validator: Validators.name,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      prefixIcon: const Icon(Icons.person_outlined),
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 16),
                    
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
                      hint: 'Create a strong password',
                      controller: _passwordController,
                      validator: Validators.password,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 8),
                    
                    // Password requirements
                    _buildPasswordRequirements(),
                    const SizedBox(height: 16),
                    
                    // Confirm password field
                    PasswordField(
                      label: 'Confirm Password',
                      hint: 'Re-enter your password',
                      controller: _confirmPasswordController,
                      validator: (value) => Validators.confirmPassword(
                        value,
                        _passwordController.text,
                      ),
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 24),
                    
                    // Terms and conditions checkbox
                    _buildTermsCheckbox(),
                    const SizedBox(height: 32),
                    
                    // Register button
                    PrimaryButton(
                      text: 'Create Account',
                      onPressed: _isLoading ? null : _handleRegister,
                      isLoading: _isLoading,
                      width: double.infinity,
                    ),
                    const SizedBox(height: 16),
                    
                    // Divider
                    _buildDivider(),
                    const SizedBox(height: 16),
                    
                    // Login link
                    _buildLoginLink(),
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
  
  /// Build header
  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          'Join Florence',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Start your journey to better health management',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  
  /// Build password requirements text
  Widget _buildPasswordRequirements() {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Password must contain:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
          ),
          const SizedBox(height: 4),
          _buildRequirementItem('At least 8 characters'),
          _buildRequirementItem('One uppercase letter'),
          _buildRequirementItem('One lowercase letter'),
          _buildRequirementItem('One number'),
        ],
      ),
    );
  }
  
  /// Build single requirement item
  Widget _buildRequirementItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 14,
            color: AppTheme.textSecondaryColor,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
          ),
        ],
      ),
    );
  }
  
  /// Build terms and conditions checkbox
  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: _acceptTerms,
            onChanged: _isLoading
                ? null
                : (value) {
                    setState(() => _acceptTerms = value ?? false);
                  },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: _isLoading
                ? null
                : () {
                    setState(() => _acceptTerms = !_acceptTerms);
                  },
            child: RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodySmall,
                children: [
                  const TextSpan(text: 'I agree to the '),
                  TextSpan(
                    text: 'Terms of Service',
                    style: TextStyle(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        Helpers.showInfo(
                            context, 'Terms of Service page coming soon');
                      },
                  ),
                  const TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: TextStyle(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        Helpers.showInfo(
                            context, 'Privacy Policy page coming soon');
                      },
                  ),
                ],
              ),
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

  /// Build login link
  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        TextButton(
          onPressed: _isLoading ? null : _goToLogin,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 0),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Sign In',
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
