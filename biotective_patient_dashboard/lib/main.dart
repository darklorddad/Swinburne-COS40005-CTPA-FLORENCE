import 'screens/auth/front_page.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const BioTectiveApp());
}

class BioTectiveApp extends StatelessWidget {
  const BioTectiveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BioTective Dashboard',
      theme: _buildThemeData(),
      home: const FrontPage(),
    );
  }

  ThemeData _buildThemeData() {
    return ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.blue,
      scaffoldBackgroundColor: const Color(0xFFF8F8F8,), // Off-white background color
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        // For "Welcome Back"
        headlineMedium: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black,
          fontSize: 36,
        ),
      ),

      // Define a style for primary buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(vertical: 20),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),

      // Define a style for appBar
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.black87),
        titleTextStyle: TextStyle(
          color: Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}