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

  // Subject palette — balanced, muted, medium-saturation colors for color-coding subjects.
  // These are intentionally not too bright or too light and include some non-teal options
  // to help visually differentiate subjects while staying pleasant and accessible.
  // 8 colors: one shade each of green, blue, brown, chrome-yellow, light brown,
  // lightish pink, teal and grey (muted / medium saturation, no reds)
  static const List<Color> subjectPalette = [
    Color(0xFF2E7D32), // green (muted)
    Color(0xFF1976D2), // blue (muted)
    Color(0xFF6D4C41), // brown (warm muted)
    Color(0xFFF1C40F), // chrome yellow (medium)
    Color(0xFFBCAAA4), // light brown (muted)
    Color(0xFFF48FB1), // lightish pink (muted)
    Color(0xFF00897B), // teal (brand)
    Color(0xFF90A4AE), // grey (muted)
  ];
}
