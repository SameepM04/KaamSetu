import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.mist,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.blue,
          brightness: Brightness.light,
          primary: AppColors.blue,
          secondary: AppColors.orange,
          surface: Colors.white,
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            color: AppColors.navy,
            fontSize: 45,
            height: .99,
            letterSpacing: -1.8,
            fontWeight: FontWeight.w800,
          ),
          headlineMedium: TextStyle(
            color: AppColors.navy,
            fontSize: 35,
            height: 1.05,
            letterSpacing: -1.2,
            fontWeight: FontWeight.w800,
          ),
          bodyLarge: TextStyle(
            color: AppColors.inkMuted,
            fontSize: 18,
            height: 1.36,
            fontWeight: FontWeight.w400,
          ),
        ),
      );
}
