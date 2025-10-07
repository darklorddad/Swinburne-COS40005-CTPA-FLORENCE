import 'package:flutter/material.dart';
import 'login_screen.dart';
import '../../widgets/loading_dialog.dart';
import '../../widgets/main_layout.dart';

class RegistrationScreen extends StatelessWidget {
  const RegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The transparent app bar allows the body content to go behind it,
      // and automatically adds a back button.
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
                children: [
                  const SizedBox(height: 20),
                  Container(
                    width: 150,
                    height: 150,
                    color: Colors.grey[300],
                    child: Center(child: Image.asset('assets/images/FLORENCE-light-background.png')),
                  ),
                  const SizedBox(height: 40),
                  const _RegistrationForm(),
                  const SizedBox(height: 24),
                  _buildRedirectToLogin(context),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper widget for the "Already have an account?" text link
  Widget _buildRedirectToLogin(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Use pushReplacement so the user can't go back to the registration page
        // from the login page after tapping this.
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      },
      child: const Text.rich(
        TextSpan(
          text: 'Already have an account? ',
          children: [
            TextSpan(
              text: 'Login',
              style: TextStyle(fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
            ),
          ],
        ),
      ),
    );
  }
}

// A private widget for the form itself to keep the build method clean
class _RegistrationForm extends StatelessWidget {
  const _RegistrationForm();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TextField(decoration: InputDecoration(labelText: 'Full Name')),
        const SizedBox(height: 24),
        const TextField(decoration: InputDecoration(labelText: 'Phone number')),
        const SizedBox(height: 24),
        const TextField(decoration: InputDecoration(labelText: 'Email')),
        const SizedBox(height: 24),
        const TextField(
          obscureText: true,
          decoration: InputDecoration(labelText: 'Password'),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              // After successful registration, navigate to the main app
              // Navigator.of(context).pushAndRemoveUntil(
              //   MaterialPageRoute(builder: (context) => MainLayout()),
              //   (Route<dynamic> route) => false,
              // );
              // 1. Show the loading dialog
              showLoadingDialog(context);

              // 2. Simulate a network delay
              await Future.delayed(const Duration(seconds: 1));

              // 3. Hide the loading dialog
              // Use mounted check to ensure widget is still in the tree
              if (!context.mounted) return;
              hideLoadingDialog(context);

              // 4. Navigate to the main app, removing all previous routes
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const MainLayout()),
                (Route<dynamic> route) => false,
              );
            },
            child: const Text('Register'),
          ),
        ),
      ],
    );
  }
}