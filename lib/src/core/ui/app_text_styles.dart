import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTextStyles {
  const AppTextStyles._();

  static const TextStyle screenTitle = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w800,
    height: 1.1,
    color: AppColors.textPrimary,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AppColors.textPrimary,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AppColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySecondary = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: AppColors.textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.3,
    color: AppColors.textMuted,
  );

  static const TextStyle numericDisplay = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w800,
    height: 1.0,
    color: AppColors.primaryAccent,
  );

  static const TextStyle buttonLabel = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.1,
  );

  static TextTheme buildTextTheme() {
    return const TextTheme(
      headlineLarge: screenTitle,
      headlineMedium: sectionTitle,
      headlineSmall: cardTitle,
      titleLarge: sectionTitle,
      titleMedium: cardTitle,
      bodyLarge: body,
      bodyMedium: bodySecondary,
      bodySmall: caption,
      labelLarge: buttonLabel,
      displaySmall: numericDisplay,
    );
  }
}
