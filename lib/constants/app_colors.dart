import 'package:flutter/material.dart';

class AppColors {
  // Primary brand colors (teal-first) for the app chrome
  static const primary = Color(0xFF00897B); // teal 600
  static const primaryVariant = Color(0xFF00695C); // darker teal
  static const secondary = Color(0xFF26A69A); // lighter teal/green accent

  // Gradient used in some components (teal -> green)
  static const gradientStart = Color(0xFF00897B);
  static const gradientEnd = Color(0xFF26A69A);

  // Semantic colors for attendance states
  static const presentGreen = Color(0xFF2ECC71);
  static const absentRed = Color(0xFFE74C3C);
  static const lateAmber = Color(0xFFF1C40F);

  // Legacy aliases (kept for compatibility with existing widgets)
  static const safeGreen = presentGreen;
  static const warningYellow = lateAmber;
  static const dangerRed = absentRed;

  // Neutral palette for cards and backgrounds
  static const background = Color(0xFFF4F6FB);
  static const surface = Color(0xFFFFFFFF);

  // Subject palette (teal/green focused choices)
  static const List<Color> subjectPalette = [
    Color(0xFF00695C), // dark teal
    Color(0xFF00796B),
  Color(0xFF00897B),
  Color(0xFF009688),
  Color(0xFF26A69A),
    Color(0xFF4DB6AC),
    Color(0xFF80CBC4),
    Color(0xFFB2DFDB),
  ];
}
