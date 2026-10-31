import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextTheme {
  static TextTheme get textTheme =>
      const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Inter',
          fontSize: 48,
          height: 1.12,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.8,
        ),
        displayMedium: TextStyle(
          fontFamily: 'Inter',
          fontSize: 40,
          height: 1.12,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.5,
        ),
        displaySmall: TextStyle(
          fontFamily: 'Inter',
          fontSize: 34,
          height: 1.18,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.2,
        ),
        headlineLarge: TextStyle(
          fontFamily: 'Inter',
          fontSize: 32,
          height: 1.2,
          fontWeight: FontWeight.w800,
          letterSpacing: -1,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Inter',
          fontSize: 28,
          height: 1.25,
          fontWeight: FontWeight.w700,
          letterSpacing: -.8,
        ),
        headlineSmall: TextStyle(
          fontFamily: 'Inter',
          fontSize: 24,
          height: 1.3,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Inter',
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontSize: 16, height: 1.5),
        bodyMedium: TextStyle(fontSize: 14, height: 1.5),
        bodySmall: TextStyle(fontSize: 12, height: 1.5),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ).apply(
        fontFamily: 'Inter',
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      );
}
