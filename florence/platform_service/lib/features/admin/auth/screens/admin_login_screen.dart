import 'package:flutter/material.dart';
import 'package:florence/config/admin_theme.dart';
import 'package:florence/features/admin/core/services/admin_auth_service.dart';

/// Admin Login Screen
/// Separate login for admin/staff users
class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AdminAuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // Clear previous error
    setState(() {
      _errorMessage = null;
    });

    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Attempt login
      final user = await _authService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (user != null) {
        // Login successful - navigate to appropriate dashboard
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Welcome back, ${user.firstName}!'),
              backgroundColor: AdminTheme.primary, // Updated to new theme primary
            ),
          );

          // Navigate to dashboard
          Navigator.pushReplacementNamed(context, '/admin-dashboard');
        }
      } else {
        // Login failed
        setState(() {
          _errorMessage = 'Invalid email or password';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showDemoAccounts() {
    final demoCredentials = AdminAuthService.getDemoCredentials();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Demo Accounts'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: demoCredentials.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Replaced getRoleBadge with a new inline badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AdminTheme.primaryContainer.withAlpha(77), // 0.3 * 255 = 77
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            entry.key,
                            style: const TextStyle(
                              color: AdminTheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.value['email']!,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      entry.value['description']!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AdminTheme.onSurfaceVariant, // Updated
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Password: ${entry.value['password']}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AdminTheme.outline, // Updated
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _fillDemoCredentials(String email) {
    setState(() {
      _emailController.text = email;
      _passwordController.text = 'demo123';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AdminTheme.lightTheme,
      child: Scaffold(
        backgroundColor: AdminTheme.surface, // Updated
        body: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(
                      color: AdminTheme.outlineVariant, // Updated
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Logo and Title
                          Column(
                            children: [
                              // Logo (placeholder)
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: AdminTheme.primary.withValues(alpha: 0.1), // Updated
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.admin_panel_settings,
                                  size: 32,
                                  color: AdminTheme.primary, // Updated
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Florence Admin',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Healthcare Management Portal',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AdminTheme.onSurfaceVariant, // Updated
                                    ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 32),

                          // Error message
                          if (_errorMessage != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: AdminTheme.error.withValues(alpha: 0.1), // Updated
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AdminTheme.error.withValues(alpha: 0.3), // Updated
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: AdminTheme.error, // Updated
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(
                                        color: AdminTheme.error, // Updated
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Email field
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              hintText: 'Enter your email',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!value.contains('@')) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // Password field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              hintText: 'Enter your password',
                              prefixIcon: const Icon(Icons.lock_outlined),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 24),

                          // Login button
                          FilledButton( // Switched to FilledButton to match new theme
                            onPressed: _isLoading ? null : _handleLogin,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text('Sign In'),
                          ),

                          const SizedBox(height: 16),

                          // Divider
                          Row(
                            children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'Demo Mode',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AdminTheme.outline, // Updated
                                  ),
                                ),
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Quick login buttons
                          _QuickLoginButton(
                            label: 'Admin',
                            email: 'admin@biotective.com',
                            icon: Icons.shield,
                            color: AdminTheme.primary, // Updated
                            onTap: () => _fillDemoCredentials('admin@biotective.com'),
                          ),
                          const SizedBox(height: 8),
                          _QuickLoginButton(
                            label: 'Hospital Admin',
                            email: 'admin@citygeneral.com',
                            icon: Icons.business,
                            color: AdminTheme.secondary, // Updated
                            onTap: () => _fillDemoCredentials('admin@citygeneral.com'),
                          ),

                          const SizedBox(height: 16),

                          // View all demo accounts
                          TextButton(
                            onPressed: _showDemoAccounts,
                            child: const Text('View All Demo Accounts'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Quick login button widget
class _QuickLoginButton extends StatelessWidget {
  final String label;
  final String email;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickLoginButton({
    required this.label,
    required this.email,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.all(16),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                Text(
                  email,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AdminTheme.onSurfaceVariant, // Updated
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward,
            size: 18,
            color: color,
          ),
        ],
      ),
    );
  }
}