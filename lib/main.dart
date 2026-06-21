import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const DriftApp());
}

class DriftApp extends StatelessWidget {
  const DriftApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DRIFT — Trip Planner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.interTextTheme(),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8F9FE),
      ),
      home: const HomeScreen(),
    );
  }
}
