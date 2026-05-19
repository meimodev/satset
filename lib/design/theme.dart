import 'package:flutter/material.dart';
import 'colors.dart';
import 'typography.dart';

ThemeData heritageLightTheme() {
  final colorScheme = const ColorScheme.light(
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: AppColors.onPrimaryContainer,
    secondary: AppColors.secondary,
    onSecondary: AppColors.onSecondary,
    secondaryContainer: AppColors.secondaryContainer,
    onSecondaryContainer: AppColors.onSecondaryContainer,
    tertiary: AppColors.tertiary,
    onTertiary: AppColors.onTertiary,
    tertiaryContainer: AppColors.tertiaryContainer,
    onTertiaryContainer: AppColors.onTertiaryContainer,
    error: AppColors.error,
    onError: AppColors.onError,
    errorContainer: AppColors.errorContainer,
    onErrorContainer: AppColors.onErrorContainer,
    surface: AppColors.surface,
    onSurface: AppColors.onSurface,
    onSurfaceVariant: AppColors.onSurfaceVariant,
    outline: AppColors.outline,
    outlineVariant: AppColors.outlineVariant,
    surfaceTint: AppColors.surfaceTint,
    inverseSurface: AppColors.inverseSurface,
    inversePrimary: AppColors.inversePrimary,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.surface,
    textTheme: AppTypography.buildTextTheme(),
    dividerTheme: const DividerThemeData(
      color: AppColors.secondaryOverride,
      thickness: 0.5,
      space: 12,
    ),
    cardTheme: CardThemeData(
      color: AppColors.surfaceLowest,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.secondaryOverride, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      margin: EdgeInsets.zero,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primaryOverride,
        foregroundColor: AppColors.onPrimary,
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryOverride,
        side: const BorderSide(color: AppColors.secondaryOverride),
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: false,
      border: UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.secondaryOverride),
      ),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.secondaryOverride),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.primaryOverride, width: 2),
      ),
      labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.1),
      contentPadding: EdgeInsets.symmetric(vertical: 12),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.tertiaryContainer,
      labelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.onTertiaryContainer,
      ),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surfaceContainer,
      indicatorColor: AppColors.primaryContainer.withValues(alpha: 0.2),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
            letterSpacing: 0.1,
          );
        }
        return const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: AppColors.onSurfaceVariant,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: AppColors.primary, size: 24);
        }
        return const IconThemeData(color: AppColors.onSurfaceVariant, size: 24);
      }),
    ),
  );
}
