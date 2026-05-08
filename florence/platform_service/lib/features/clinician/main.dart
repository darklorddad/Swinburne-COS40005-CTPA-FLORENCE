import 'package:flutter/material.dart';
import 'package:florence/features/clinician/screens/clinician_home_screen.dart';
import 'package:florence/features/clinician/theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BioTective Clinician Dashboard',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const ClinicianHomeScreen(),
    );
  }
}
