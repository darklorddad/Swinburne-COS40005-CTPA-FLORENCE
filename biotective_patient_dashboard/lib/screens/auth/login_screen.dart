import 'package:flutter/material.dart';
import 'registration_screen.dart';
import '../../widgets/loading_dialog.dart';
import '../../widgets/main_layout.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),
                  Text('Welcome\nBack', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 60),
                  const _LoginForm(),
                  const SizedBox(height: 60),
                  _buildRedirectToRegister(context),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRedirectToRegister(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const RegistrationScreen()),
          );
        },
        child: const Text.rich(
          TextSpan(
            text: "Don't have an account? ",
            children: [
              TextSpan(
                text: 'Sign up',
                style: TextStyle(fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const TextField(decoration: InputDecoration(labelText: 'Email')),
        const SizedBox(height: 24),
        const TextField(
          obscureText: true,
          decoration: InputDecoration(labelText: 'Password'),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            // Simulated simple dialog confirming the action was triggered
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Forgot Password'),
                content: const Text(
                    'A password reset link would be sent to your email address.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          },
          child: const Text('Forgot password?', style: TextStyle(color: Colors.black)),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              // After successful login, navigate to the main app layout
              // Navigator.of(context).pushAndRemoveUntil(
              //   MaterialPageRoute(builder: (context) => MainLayout()),
              //   (Route<dynamic> route) => false,
              // );

              // 1. Show the loading dialog
              showLoadingDialog(context);

              // 2. Simulate a network delay
              await Future.delayed(const Duration(seconds: 1));

              // 3. Hide the loading dialog
              if (!context.mounted) return;
              hideLoadingDialog(context);

              // 4. Navigate to the main app, removing all previous routes
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const MainLayout()),
                (Route<dynamic> route) => false,
              );
            },
            child: const Text('Login'),
          ),
        ),
      ],
    );
  }
}