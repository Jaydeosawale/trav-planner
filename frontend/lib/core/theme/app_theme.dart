import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_theme.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,

        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),

        scaffoldBackgroundColor: AppColors.background,

        canvasColor: AppColors.background,

        cardColor: AppColors.surface,

        dividerColor: Colors.transparent,

        splashFactory: InkRipple.splashFactory,

        textTheme: AppTextTheme.textTheme,

        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: false,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
        ),

        cardTheme: CardThemeData(
          elevation: 0,
          color: AppColors.surface,
          shadowColor: Colors.black12,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: false,

          isDense: true,

          contentPadding: const EdgeInsets.symmetric(
            horizontal: 22,
            vertical: 18,
          ),

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(32),
            borderSide: BorderSide.none,
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(32),
            borderSide: BorderSide.none,
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(32),
            borderSide: const BorderSide(
              color: AppColors.primary,
              width: 1.4,
            ),
          ),

          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(32),
            borderSide: BorderSide.none,
          ),

          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(32),
            borderSide: const BorderSide(
              color: Colors.red,
            ),
          ),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            side: BorderSide(
              color: Colors.grey.shade300,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            textStyle: const TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        chipTheme: ChipThemeData(
          backgroundColor: Colors.white,
          selectedColor: AppColors.primary,
          disabledColor: Colors.grey.shade200,
          secondarySelectedColor: AppColors.primary,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
          secondaryLabelStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),

        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),

        pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
         TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
         TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
         TargetPlatform.macOS: ZoomPageTransitionsBuilder(),
        },
      ),

      );
}