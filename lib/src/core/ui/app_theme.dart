import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

ThemeData buildAppTheme() {
  final ColorScheme colorScheme = const ColorScheme.dark().copyWith(
    primary: AppColors.primaryAccent,
    onPrimary: AppColors.bgPrimary,
    secondary: AppColors.primaryAccentLight,
    onSecondary: AppColors.bgPrimary,
    error: AppColors.error,
    onError: AppColors.textPrimary,
    surface: AppColors.bgCard,
    onSurface: AppColors.textPrimary,
    outlineVariant: AppColors.borderSubtle,
  );

  final TextTheme textTheme = AppTextStyles.buildTextTheme().apply(
    bodyColor: AppColors.textPrimary,
    displayColor: AppColors.textPrimary,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'Cairo',
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.bgPrimary,
    canvasColor: AppColors.bgPrimary,
    dividerColor: AppColors.borderSubtle,
    textTheme: textTheme,
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.bgElevated,
      contentTextStyle: textTheme.bodyMedium,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        side: const BorderSide(color: AppColors.borderSubtle),
      ),
      behavior: SnackBarBehavior.floating,
    ),
    cardTheme: CardThemeData(
      color: AppColors.bgCard,
      elevation: 0,
      margin: EdgeInsets.zero,
      shadowColor: AppColors.shadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        side: const BorderSide(color: AppColors.borderSubtle),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: false,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.bgElevated,
      surfaceTintColor: Colors.transparent,
      showDragHandle: false,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(0, 54),
        backgroundColor: AppColors.primaryAccent,
        foregroundColor: AppColors.bgPrimary,
        disabledBackgroundColor: AppColors.textMuted.withValues(alpha: 0.18),
        disabledForegroundColor: AppColors.textMuted,
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        textStyle: textTheme.labelLarge,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.large),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style:
          OutlinedButton.styleFrom(
            minimumSize: const Size(0, 52),
            foregroundColor: AppColors.textPrimary,
            side: const BorderSide(color: AppColors.borderSubtle),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            textStyle: textTheme.labelLarge,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.large),
            ),
          ).copyWith(
            backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
              if (states.contains(WidgetState.disabled)) {
                return AppColors.bgInput.withValues(alpha: 0.5);
              }
              if (states.contains(WidgetState.pressed)) {
                return AppColors.bgInput;
              }
              return AppColors.bgElevated;
            }),
          ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryAccent,
        textStyle: textTheme.labelLarge,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.large),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.bgInput,
      hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
      labelStyle: textTheme.bodyMedium?.copyWith(
        color: AppColors.textSecondary,
      ),
      errorStyle: textTheme.bodySmall?.copyWith(color: AppColors.error),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.large),
        borderSide: const BorderSide(color: AppColors.borderSubtle),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.large),
        borderSide: const BorderSide(color: AppColors.borderSubtle),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.large),
        borderSide: const BorderSide(
          color: AppColors.primaryAccent,
          width: 1.4,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.large),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.large),
        borderSide: const BorderSide(color: AppColors.error, width: 1.4),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        side: const BorderSide(color: AppColors.borderSubtle),
      ),
      backgroundColor: AppColors.bgInput,
      selectedColor: AppColors.primaryAccent,
      secondarySelectedColor: AppColors.primaryAccent,
      labelStyle: textTheme.bodyMedium!,
      secondaryLabelStyle: textTheme.bodyMedium!.copyWith(
        color: AppColors.bgPrimary,
        fontWeight: FontWeight.w700,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primaryAccent,
      foregroundColor: AppColors.bgPrimary,
      elevation: 6,
      highlightElevation: 8,
      shape: CircleBorder(),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.bgElevated,
      indicatorColor: AppColors.primaryAccent.withValues(alpha: 0.18),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>((states) {
        final bool selected = states.contains(WidgetState.selected);
        return textTheme.bodySmall?.copyWith(
          color: selected ? AppColors.textPrimary : AppColors.textMuted,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith<IconThemeData?>((states) {
        final bool selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? AppColors.primaryAccent : AppColors.textMuted,
        );
      }),
    ),
    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primaryAccent.withValues(alpha: 0.35);
        }
        return AppColors.bgInput;
      }),
      thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primaryAccent;
        }
        return AppColors.textSecondary;
      }),
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      iconColor: AppColors.textSecondary,
      textColor: AppColors.textPrimary,
    ),
    extensions: const <ThemeExtension<dynamic>>[
      OgraUiTokens(
        textSecondaryLight: AppColors.textSecondaryLight,
        textSecondary: AppColors.textSecondary,
        textMuted: AppColors.textMuted,
        borderSubtle: AppColors.borderSubtle,
        borderAccent: AppColors.borderAccent,
        inputSurface: AppColors.bgInput,
        elevatedSurface: AppColors.bgElevated,
        warningSurface: AppColors.warningSurface,
        success: AppColors.success,
        info: AppColors.info,
        warning: AppColors.warning,
        error: AppColors.error,
      ),
    ],
  );
}

@immutable
class OgraUiTokens extends ThemeExtension<OgraUiTokens> {
  const OgraUiTokens({
    required this.textSecondary,
    required this.textSecondaryLight,
    required this.textMuted,
    required this.borderSubtle,
    required this.borderAccent,
    required this.inputSurface,
    required this.elevatedSurface,
    required this.warningSurface,
    required this.success,
    required this.info,
    required this.warning,
    required this.error,
  });

  final Color textSecondary;
  final Color textSecondaryLight;
  final Color textMuted;
  final Color borderSubtle;
  final Color borderAccent;
  final Color inputSurface;
  final Color elevatedSurface;
  final Color warningSurface;
  final Color success;
  final Color info;
  final Color warning;
  final Color error;

  @override
  OgraUiTokens copyWith({
    Color? textSecondary,
    Color? textSecondaryLight,
    Color? textMuted,
    Color? borderSubtle,
    Color? borderAccent,
    Color? inputSurface,
    Color? elevatedSurface,
    Color? warningSurface,
    Color? success,
    Color? info,
    Color? warning,
    Color? error,
  }) {
    return OgraUiTokens(
      textSecondary: textSecondary ?? this.textSecondary,
      textSecondaryLight: textSecondaryLight ?? this.textSecondaryLight,
      textMuted: textMuted ?? this.textMuted,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      borderAccent: borderAccent ?? this.borderAccent,
      inputSurface: inputSurface ?? this.inputSurface,
      elevatedSurface: elevatedSurface ?? this.elevatedSurface,
      warningSurface: warningSurface ?? this.warningSurface,
      success: success ?? this.success,
      info: info ?? this.info,
      warning: warning ?? this.warning,
      error: error ?? this.error,
    );
  }

  @override
  OgraUiTokens lerp(ThemeExtension<OgraUiTokens>? other, double t) {
    if (other is! OgraUiTokens) {
      return this;
    }

    return OgraUiTokens(
      textSecondary:
          Color.lerp(textSecondary, other.textSecondary, t) ?? textSecondary,
      textSecondaryLight:
          Color.lerp(textSecondaryLight, other.textSecondaryLight, t) ??
          textSecondaryLight,
      textMuted: Color.lerp(textMuted, other.textMuted, t) ?? textMuted,
      borderSubtle:
          Color.lerp(borderSubtle, other.borderSubtle, t) ?? borderSubtle,
      borderAccent:
          Color.lerp(borderAccent, other.borderAccent, t) ?? borderAccent,
      inputSurface:
          Color.lerp(inputSurface, other.inputSurface, t) ?? inputSurface,
      elevatedSurface:
          Color.lerp(elevatedSurface, other.elevatedSurface, t) ??
          elevatedSurface,
      warningSurface:
          Color.lerp(warningSurface, other.warningSurface, t) ?? warningSurface,
      success: Color.lerp(success, other.success, t) ?? success,
      info: Color.lerp(info, other.info, t) ?? info,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      error: Color.lerp(error, other.error, t) ?? error,
    );
  }
}
